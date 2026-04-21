import '../entities/auth_failure.dart';

/// Validates email format on the client side.
///
/// This runs BEFORE any network call.
/// No repository dependency — pure domain logic.
/// Identical pattern to ValidateUsernameUseCase.
///
/// Two layers of validation:
/// 1. This use case → instant client feedback, no network
/// 2. Server/Supabase → rejects malformed emails on submission
///
/// Never trust client-only validation for security decisions.
/// Always validate server-side too.
class ValidateEmailUseCase {
  const ValidateEmailUseCase();

  /// Returns null if the email format is valid.
  /// Returns [InvalidEmailFormat] if the format is wrong.
  ///
  /// Why return nullable AuthFailure instead of Either?
  /// Validation-only use cases that have no async work and no
  /// success value are cleaner with nullable return.
  /// Either<AuthFailure, void> is more ceremonial than useful here.
  /// The Bloc checks: if result != null => emit AuthEmailInvalid.
  AuthFailure? call(String email) {
    final trimmed = email.trim();

    if (trimmed.isEmpty) {
      return const InvalidEmailFormat();
    }

    // RFC 5322 simplified regex.
    // Catches obvious errors: missing @, missing domain, missing TLD.
    // Does NOT attempt to catch every edge case —
    // overly strict email regex rejects valid emails.
    // The server validates definitively.
    // This is just UX — "hey, you forgot the @".
    final isValidFormat = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(trimmed);

    if (!isValidFormat) {
      return const InvalidEmailFormat();
    }

    // Additional sanity checks that regex doesn't catch well:

    // Consecutive dots in local part (john..doe@gmail.com is invalid)
    final localPart = trimmed.split('@').first;
    if (localPart.contains('..')) {
      return const InvalidEmailFormat();
    }

    // Domain part must have at least one dot
    final domainPart = trimmed.split('@').last;
    if (!domainPart.contains('.')) {
      return const InvalidEmailFormat();
    }

    // TLD must be at least 2 characters
    final tld = domainPart.split('.').last;
    if (tld.length < 2) {
      return const InvalidEmailFormat();
    }

    return null; // null = valid
  }
}
