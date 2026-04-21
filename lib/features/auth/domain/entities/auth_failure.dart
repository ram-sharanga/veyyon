/// lib\features\auth\domain\entities\auth_failure.dart
///
/// Represents all the ways authentication can fail.
/// Sealed classes allow exhaustive pattern matching at compile time.
sealed class AuthFailure {
  final String message;
  const AuthFailure(this.message);
}

/// No internet connection or timeout.
final class NetworkFailure extends AuthFailure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

/// User cancelled sign-in intentionally (NOT an error).
final class CancelledByUser extends AuthFailure {
  const CancelledByUser() : super('Sign in cancelled by user.');
}

/// Server-side or OAuth unexpected failure.
final class ServerFailure extends AuthFailure {
  const ServerFailure([super.message = 'An unexpected server error occurred.']);
}

/// Account exists with another provider (e.g. Google vs Apple).
final class AccountExistsWithDifferentProvider extends AuthFailure {
  final String existingProvider;

  const AccountExistsWithDifferentProvider({required this.existingProvider})
    : super('An account already exists with a different sign-in provider.');
}

/// Apple credential revoked by user in iOS settings.
final class CredentialRevoked extends AuthFailure {
  const CredentialRevoked()
    : super('Apple credential has been revoked by the user.');
}

/// Fallback for unknown/unexpected errors.
final class UnknownFailure extends AuthFailure {
  const UnknownFailure([super.message = 'An unknown error occurred.']);
}

/// User entered email that has no account.
/// Shown when they try to get a magic link but aren't registered.
/// This triggers the "new user" flow — send them the website link instead.
final class EmailNotRegistered extends AuthFailure {
  const EmailNotRegistered()
    : super('No account found with this email address.');
}

/// The magic link the user clicked has expired.
/// Supabase OTP links expire after a configurable period (default 1 hour).
final class MagicLinkExpired extends AuthFailure {
  const MagicLinkExpired()
    : super('This sign-in link has expired. Please request a new one.');
}

/// The magic link was already used.
/// Supabase OTP links are one-time use.
final class MagicLinkAlreadyUsed extends AuthFailure {
  const MagicLinkAlreadyUsed()
    : super(
        'This sign-in link has already been used. Please request a new one.',
      );
}

/// Email format is invalid (client-side check before any network call).
final class InvalidEmailFormat extends AuthFailure {
  const InvalidEmailFormat() : super('Please enter a valid email address.');
}
