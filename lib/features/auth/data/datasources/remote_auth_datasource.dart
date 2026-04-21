import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:veyyon/features/auth/domain/usecases/verify_otp_usecase.dart';

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

class RemoteAuthDataSource {
  final SupabaseClient _supabaseClient;

  const RemoteAuthDataSource({required this._supabaseClient});

  User? getCurrentUser() {
    return _supabaseClient.auth.currentUser;
  }

  String? getCurrentAccessToken() {
    return _supabaseClient.auth.currentSession?.accessToken;
  }

  Stream<AuthState> watchAuthState() {
    return _supabaseClient.auth.onAuthStateChange;
  }

  Future<Map<String, dynamic>> fetchProfile(String userId) async {
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } on PostgrestException catch (e) {
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

  Future<void> setUsername(String userId, String username) async {
    try {
      await _supabaseClient
          .from('profiles')
          .update({'username': username, 'is_onboarded': true})
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

  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();
      return response == null;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

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

  // Email auth has no native SDK to sign out from.
  // Only Supabase session needs clearing.
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
