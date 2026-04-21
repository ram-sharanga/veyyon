import 'package:dartz/dartz.dart';
import 'package:veyyon/features/auth/domain/entities/auth_failure.dart';
import 'package:veyyon/features/auth/domain/repositories/auth_repository.dart';

/// Checks whether an email address has an existing account.
///
/// This is the gateway decision point in the email auth flow.
/// The result determines which email gets sent:
///   Right(true)  → account exists → sendMagicLink()
///   Right(false) → no account    → sendNewUserLink()
///
/// SECURITY NOTE:
/// If you use this use case directly from the client (Option 1),
/// you are exposing email enumeration — anyone can discover which
/// emails are registered by calling this repeatedly.
/// Prefer the backend-driven SendEmailFlowUseCase (Option 2)
/// which makes this decision server-side and never tells the
/// client which case applied.
///
/// This use case is kept here for:
/// 1. Internal use by SendEmailFlowUseCase
/// 2. Cases where email enumeration risk is acceptable for your app
class CheckEmailExistsUseCase {
  final AuthRepository _repository;

  const CheckEmailExistsUseCase(this._repository);

  /// [email] must be pre-validated for format before calling this.
  /// This use case does NOT validate format — that is
  /// ValidateEmailUseCase's job. Never skip format validation
  /// before calling this — an invalid email hitting the database
  /// is wasted round trip and noise in your logs.
  Future<Either<AuthFailure, bool>> call(String email) {
    // Normalize: always lowercase, always trimmed.
    // Do this here as a safety net even if the caller already did it.
    // Defense in depth — two normalizations cost nothing.
    final normalizedEmail = email.trim().toLowerCase();
    return _repository.checkEmailExists(normalizedEmail);
  }
}
