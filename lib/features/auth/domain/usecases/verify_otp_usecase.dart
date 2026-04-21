import 'package:dartz/dartz.dart';
import '../entities/auth_failure.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Verifies an OTP token received via deep link.
///
/// When is this needed?
/// Supabase Flutter SDK v2 automatically handles OTP verification
/// for magic links if the deep link is intercepted by the SDK.
/// You typically do NOT need to call this manually.
///
/// When you DO need this use case:
/// 1. You are building a 6-digit OTP input screen
///    (where user types the code instead of clicking a link)
/// 2. The SDK fails to auto-process the deep link for some reason
/// 3. You are processing the token from a web redirect manually
///
/// OTP input screen flow (alternative to magic link):
/// 1. User enters email → you call sendMagicLink or sendEmailFlow
/// 2. User receives email with 6-digit code (not a clickable link)
///    (Configure this in Supabase: Email OTP instead of Magic Link)
/// 3. User types the 6-digit code into your app
/// 4. App calls this use case with the code
/// 5. Supabase verifies → session created → auth stream emits signedIn
///
/// The 6-digit OTP approach is better UX on mobile because:
/// - No app switching (email app → your app)
/// - Works even if deep links are misconfigured
/// - Faster for the user
/// - More reliable across all email clients
///
/// Whether to use magic link (click) or OTP (type code) is a
/// product decision. Both are supported by Supabase. This use case
/// supports the OTP code approach.
class VerifyOtpUseCase {
  final AuthRepository _repository;

  const VerifyOtpUseCase(this._repository);

  /// [email] the email address the OTP was sent to.
  /// [token] the 6-digit code the user typed, OR the full token
  ///         extracted from the magic link deep link URL.
  /// [type] which OTP type: 'magiclink', 'signup', 'recovery', etc.
  ///        For your flow: always 'magiclink' or 'signup' (new user).
  Future<Either<AuthFailure, AuthUser>> call({
    required String email,
    required String token,
    required OtpVerificationType type,
  }) {
    return _repository.verifyOtp(email: email, token: token, type: type);
  }
}

/// The type of OTP being verified.
/// Maps directly to Supabase's OtpType enum in the data layer.
/// Defined here in domain so the Bloc doesn't import Supabase.
enum OtpVerificationType {
  /// Standard magic link / sign-in OTP.
  /// Use for returning users signing in.
  magicLink,

  /// New user signup OTP.
  /// Use when the user is completing email verification
  /// as part of account creation.
  signup,
}
