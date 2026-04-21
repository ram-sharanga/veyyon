import 'package:dartz/dartz.dart';
import '../entities/auth_failure.dart';
import '../repositories/auth_repository.dart';

/// Sends a magic link to a RETURNING user's email address.
///
/// "Returning user" means: a profiles row exists for this email
/// AND is_onboarded is true.
///
/// The link opens your app via deep link:
///   com.veyyon.veyyon://auth/callback
///
/// Supabase sends the email. The user clicks the link.
/// The app intercepts the deep link. Supabase SDK exchanges
/// the OTP token for a session. Auth state stream emits signedIn.
/// Router navigates to home screen.
///
/// This use case calls the repository with shouldCreateUser: false.
/// Supabase will REJECT the OTP send if the email doesn't exist.
/// That rejection is mapped to EmailNotRegistered failure.
/// If you receive EmailNotRegistered from this use case,
/// you called it incorrectly — you should have called
/// SendNewUserLinkUseCase instead.
class SendMagicLinkUseCase {
  final AuthRepository _repository;

  const SendMagicLinkUseCase(this._repository);

  /// [email] must be pre-validated and pre-normalized (lowercase, trimmed).
  /// This use case does not validate or normalize.
  /// Caller is responsible for validation.
  Future<Either<AuthFailure, void>> call(String email) {
    return _repository.sendMagicLink(email);
  }
}
