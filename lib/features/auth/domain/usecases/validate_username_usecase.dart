/// Validates username format on the client side.
///
/// This runs BEFORE the network call to check availability.
/// If the format is invalid, we show an error immediately
/// without making a network request — better UX and fewer DB queries.
///
/// The same rules are enforced in the database CHECK constraint.
/// Two layers of validation: client (UX) and database (security).
/// Never trust client-only validation.
class ValidateUsernameUseCase {
  const ValidateUsernameUseCase();

  UsernameValidationResult call(String username) {
    if (username.isEmpty) {
      return const UsernameValidationResult.invalid(
        'Username cannot be empty.',
      );
    }

    if (username.length < 3) {
      return const UsernameValidationResult.invalid(
        'Username must be at least 3 characters.',
      );
    }

    if (username.length > 20) {
      return const UsernameValidationResult.invalid(
        'Username cannot exceed 20 characters.',
      );
    }

    // Only alphanumeric and underscores
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return const UsernameValidationResult.invalid(
        'Username can only contain letters, numbers, and underscores.',
      );
    }

    // Cannot start with underscore
    if (username.startsWith('_')) {
      return const UsernameValidationResult.invalid(
        'Username cannot start with an underscore.',
      );
    }

    // Cannot end with underscore
    if (username.endsWith('_')) {
      return const UsernameValidationResult.invalid(
        'Username cannot end with an underscore.',
      );
    }

    // Cannot have consecutive underscores
    if (username.contains('__')) {
      return const UsernameValidationResult.invalid(
        'Username cannot contain consecutive underscores.',
      );
    }

    return const UsernameValidationResult.valid();
  }
}

/// The result of username format validation.
/// Sealed so the caller must handle both cases.
sealed class UsernameValidationResult {
  const UsernameValidationResult();
  const factory UsernameValidationResult.valid() = UsernameValid;
  const factory UsernameValidationResult.invalid(String reason) =
      UsernameInvalid;
}

final class UsernameValid extends UsernameValidationResult {
  const UsernameValid();
}

final class UsernameInvalid extends UsernameValidationResult {
  final String reason;
  const UsernameInvalid(this.reason);
}
