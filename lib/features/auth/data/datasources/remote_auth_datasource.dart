import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:veyyon/features/auth/domain/usecases/verify_otp_usecase.dart';

/// Exceptions thrown by this data source.
/// These are caught by the repository and converted to AuthFailure objects.
/// They never escape past the repository layer.
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
}

class EmailNotRegisteredException implements Exception {
  const EmailNotRegisteredException();
}

class MagicLinkExpiredException implements Exception {
  const MagicLinkExpiredException();
}

class MagicLinkAlreadyUsedException implements Exception {
  const MagicLinkAlreadyUsedException();
}

class RateLimitExceededException implements Exception {
  final int retryAfterSeconds;
  const RateLimitExceededException({required this.retryAfterSeconds});
}

class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
}

/// The remote data source for authentication.
///
/// Directly calls Supabase auth client only.
/// Throws typed exceptions — never returns nulls or raw errors.
/// The repository catches these and converts to AuthFailure objects.
///
/// This class is the boundary between your clean architecture
/// and the external world (Supabase).
class RemoteAuthDataSource {
  final SupabaseClient _supabaseClient;

  const RemoteAuthDataSource({required this._supabaseClient});

  /// Returns the current Supabase user, or null if not signed in.
  User? getCurrentUser() {
    return _supabaseClient.auth.currentUser;
  }

  /// Returns the current session's access token (JWT).
  /// Returns null if no active session.
  String? getCurrentAccessToken() {
    return _supabaseClient.auth.currentSession?.accessToken;
  }

  /// Stream of auth state changes from Supabase.
  Stream<AuthState> watchAuthState() {
    return _supabaseClient.auth.onAuthStateChange;
  }

  /// Fetches the user's profile row from public.profiles.
  ///
  /// Called after every sign-in to get app-specific data
  /// (isOnboarded, username) that Supabase auth doesn't store.
  ///
  /// Retries once after 500ms if profile row not found yet.
  /// This handles the rare race condition where the trigger
  /// hasn't fired by the time we query.
  Future<Map<String, dynamic>> fetchProfile(String userId) async {
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return response;
    } on PostgrestException catch (e) {
      // PGRST116 = "The result contains 0 rows"
      // Trigger may not have fired yet — wait and retry once.
      if (e.code == 'PGRST116') {
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          final retryResponse = await _supabaseClient
              .from('profiles')
              .select()
              .eq('id', userId)
              .single();
          return retryResponse;
        } catch (retryError) {
          throw ServerException('Profile not found after retry: $retryError');
        }
      }
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Updates the username and marks onboarding as complete.
  Future<void> setUsername(String userId, String username) async {
    try {
      await _supabaseClient
          .from('profiles')
          .update({
            'username': username,
            'is_onboarded': true,
            // updated_at is handled by the database trigger.
            // We never set it from the client.
          })
          .eq('id', userId);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const ServerException('Username is already taken.');
      }
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Checks if a username already exists in profiles.
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      // maybeSingle() returns null if no row found (username available)
      // and returns the row if found (username taken).
      return response == null;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Checks if a user account exists for this email.
  ///
  /// Queries profiles, not auth.users — auth.users is RLS-blocked
  /// from the client. A profiles row existing = a fully created account.
  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      return response != null;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// Sends a magic link to a returning user.
  ///
  /// shouldCreateUser: false — Supabase rejects if email not found.
  /// The rejection is caught and thrown as EmailNotRegisteredException.
  Future<void> sendMagicLink(String email) async {
    try {
      await _supabaseClient.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
        emailRedirectTo: 'com.veyyon.veyyon://auth/callback',
      );
    } on AuthException catch (e) {
      if (e.message.contains('Signups not allowed') || e.statusCode == '422') {
        throw const EmailNotRegisteredException();
      }
      if (e.statusCode == '429') {
        throw const RateLimitExceededException(retryAfterSeconds: 60);
      }
      throw ServerException(e.message);
    } catch (e) {
      if (e.toString().contains('network') || e.toString().contains('socket')) {
        throw NetworkException(e.toString());
      }
      throw ServerException(e.toString());
    }
  }

  /// Sends a signup link to a new user pointing to the website.
  ///
  /// shouldCreateUser: true — Supabase creates auth.users row on click.
  /// Website handles onboarding then sends user back into the app.
  Future<void> sendNewUserLink(String email) async {
    try {
      await _supabaseClient.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
        emailRedirectTo: 'https://veyyon.com/signup?source=app',
      );
    } on AuthException catch (e) {
      if (e.statusCode == '429') {
        throw const RateLimitExceededException(retryAfterSeconds: 60);
      }
      throw ServerException(e.message);
    } catch (e) {
      if (e.toString().contains('network') || e.toString().contains('socket')) {
        throw NetworkException(e.toString());
      }
      throw ServerException(e.toString());
    }
  }

  /// Verifies a Supabase OTP token.
  ///
  /// Used for:
  /// 1. 6-digit code flow (user types code from email)
  /// 2. Manual deep link processing (if SDK doesn't auto-handle)
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    required OtpVerificationType type,
  }) async {
    try {
      final supabaseOtpType = switch (type) {
        OtpVerificationType.magicLink => OtpType.magiclink,
        OtpVerificationType.signup => OtpType.signup,
      };

      final response = await _supabaseClient.auth.verifyOTP(
        email: email,
        token: token,
        type: supabaseOtpType,
      );

      if (response.user == null) {
        throw const ServerException(
          'Supabase did not return a user after OTP verification.',
        );
      }

      return response;
    } on AuthException catch (e) {
      if (e.message.contains('expired') || e.statusCode == '401') {
        throw const MagicLinkExpiredException();
      }
      if (e.message.contains('already used') || e.statusCode == '422') {
        throw const MagicLinkAlreadyUsedException();
      }
      throw ServerException(e.message);
    } catch (e) {
      if (e is MagicLinkExpiredException ||
          e is MagicLinkAlreadyUsedException) {
        rethrow;
      }
      throw ServerException(e.toString());
    }
  }
}
