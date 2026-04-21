/// lib\features\auth\domain\repositories\auth_repository.dart
///
/// Represents the contract for all authentication operations.
/// The domain layer depends on this abstraction.
/// The data layer provides the implementation.
/// The presentation layer (Bloc) calls these methods.
import 'package:dartz/dartz.dart';
import 'package:veyyon/features/auth/domain/entities/auth_failure.dart';
import 'package:veyyon/features/auth/domain/entities/auth_user.dart';

// What is Either<L, R>?
// It's a type from the dartz package that represents one of two values.
// Either<AuthFailure, AuthUser> means:
//   - Left(AuthFailure) → something went wrong, here's the failure
//   - Right(AuthUser)   → success, here's the user
//
// This is called Railway Oriented Programming.
// Your function can't crash - it always returns one of two tracks.
// The caller pattern matches on Left/Right and handles both cases.
// No try/catch. No null checks. The type itself tells you what happened.

abstract class AuthRepository {
  /// Checks whether an email address has an existing account.
  ///
  /// This is how we distinguish new users from returning users.
  /// Queries public.profiles for a row with this email.
  ///
  /// Returns Right(true) = account exists (returning user → send magic link)
  /// Returns Right(false) = no account (new user → send website link)
  /// Returns Left(failure) on error
  Future<Either<AuthFailure, bool>> checkEmailExists(String email);

  /// Sends a magic link to a returning user's email.
  ///
  /// The link opens your app via deep link and signs them in.
  /// Link format: com.veyyon.veyyon://auth/callback?token=...
  ///
  /// Returns Right(null) on success (email sent)
  /// Returns Left(RateLimitExceeded) if too many requests
  /// Returns Left(NetworkFailure) on connectivity issues
  Future<Either<AuthFailure, void>> sendMagicLink(String email);

  /// Sends a "create your account" link to a new user's email.
  ///
  /// The link points to your WEBSITE (not the app).
  /// Website URL: https://veyyon.com/signup?email=...&token=...
  ///
  /// The website handles onboarding (username setup etc),
  /// creates the profiles row, then sends a magic link to open the app.
  ///
  /// Returns Right(null) on success
  Future<Either<AuthFailure, void>> sendNewUserLink(String email);

  /// Signs the user out of both Supabase and the native provider SDK.
  ///
  /// For Google: also calls googleSignIn.signOut() so the account picker
  /// shows on next sign-in (not silent sign-in with previous account).
  /// For Apple: no native sign-out needed - OS handles it.
  Future<Either<AuthFailure, void>> signOut();

  /// Returns the currently authenticated user, or null if not signed in.
  ///
  /// This reads from the local session cache - no network call.
  /// Used to check auth state synchronously when needed.
  Future<Either<AuthFailure, AuthUser?>> getCurrentUser();

  /// A stream that emits the current user whenever auth state changes.
  ///
  /// Emits AuthUser when signed in (including session restoration on launch).
  /// Emits null when signed out (including token expiry and revocation).
  /// This stream never completes - it runs for the app's entire lifetime.
  /// The AuthBloc subscribes to this stream and drives all auth-based routing.
  Stream<AuthUser?> watchAuthState();

  /// Checks if a username is available and valid.
  ///
  /// Queries the profiles table for existence of this username.
  /// Called during onboarding as the user types (debounced in the Bloc).
  /// Returns true if available, false if taken.
  /// Returns [ServerFailure] if the query fails.
  Future<Either<AuthFailure, bool>> checkUsernameAvailability(String username);

  /// Sets the username for a user completing onboarding.
  ///
  /// Updates the profiles row: sets username and is_onboarded = true.
  /// After this succeeds, the user is fully onboarded and routes to home.
  /// Returns [ServerFailure] if the username was taken between
  /// availability check and submission (race condition).
  Future<Either<AuthFailure, void>> setUsername(String username);

  /// Deletes the user's account permanently.
  ///
  /// This does NOT call Supabase directly - it calls your Go backend,
  /// which uses the service role key to delete the auth.users row.
  /// The cascade delete removes the profiles row automatically.
  /// After success, signs out locally and clears all cached data.
  Future<Either<AuthFailure, void>> deleteAccount();
}
