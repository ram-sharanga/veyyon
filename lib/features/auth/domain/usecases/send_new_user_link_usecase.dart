import 'package:dartz/dartz.dart';
import '../entities/auth_failure.dart';
import '../repositories/auth_repository.dart';

/// Sends a "create your account" link to a NEW user's email.
///
/// "New user" means: no profiles row exists for this email.
///
/// The link points to your WEBSITE (not the app):
///   https://veyyon.com/signup?source=app
///
/// What happens after the user clicks:
/// 1. User lands on your website
/// 2. Supabase validates the OTP and creates an auth.users row
///    (because shouldCreateUser: true)
/// 3. Your trigger fires and creates the profiles row
/// 4. Website shows onboarding form (username etc)
/// 5. User completes onboarding
/// 6. Website sends a magic link to open the app
/// 7. User clicks → deep link → app → signed in + onboarded
///
/// Why does the website need to create the account and not the app?
/// The app cannot create auth.users rows directly without an OTP flow.
/// The OTP flow requires an email round-trip.
/// For new users, that email round-trip happens to the WEBSITE.
/// The website is the OAuth callback receiver for new users.
///
/// If you are using Option B (in-app onboarding instead of website):
/// This use case still sends the email, but emailRedirectTo points
/// to the app's deep link instead of the website. The user then
/// completes onboarding in-app using the existing OnboardingPage.
class SendNewUserLinkUseCase {
  final AuthRepository _repository;

  const SendNewUserLinkUseCase(this._repository);

  /// [email] must be pre-validated and pre-normalized.
  Future<Either<AuthFailure, void>> call(String email) {
    return _repository.sendNewUserLink(email);
  }
}
