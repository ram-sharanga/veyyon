import 'package:dartz/dartz.dart';
import '../entities/auth_failure.dart';
import '../repositories/auth_repository.dart';

/// The preferred, secure email flow use case.
///
/// This is Option 2 from the architecture discussion:
/// the decision of "new user or returning user" is made
/// SERVER-SIDE, not client-side.
///
/// How it works:
/// 1. Client sends email to your Go backend
/// 2. Go backend checks internally: does this email have a profiles row?
/// 3. YES → Go calls Supabase Admin API to send magic link email
/// 4. NO  → Go calls Supabase Admin API to send new user email
/// 5. Go returns which type of link was sent (so client can show the right message)
/// 6. Client shows "check your email" with appropriate message
///
/// Why this is better than CheckEmailExistsUseCase + branch:
/// - No email enumeration attack surface (client never knows if email exists)
/// - Server has the service_role key to call Admin API directly
/// - More reliable: no race condition between check and send
/// - One round trip instead of two (check + send vs just send)
///
/// The repository.sendEmailFlow() calls your Go backend endpoint:
///   POST /api/v1/auth/send-link
///   Body: { "email": "user@example.com" }
///   Response: { "link_type": "magic_link" | "new_user" }
///
/// When Go backend is not yet available:
/// Falls back to client-side check (Option 1) automatically.
/// See AuthRepositoryImpl.sendEmailFlow() for the fallback logic.
class SendEmailFlowUseCase {
  final AuthRepository _repository;

  const SendEmailFlowUseCase(this._repository);

  /// Returns Right(EmailLinkType) indicating which email was sent.
  /// The Bloc uses this to show the correct "check your email" message.
  ///
  /// Returns Left(AuthFailure) on any error:
  ///   NetworkFailure → no internet
  ///   RateLimitExceeded → too many attempts
  ///   ServerFailure → something went wrong
  Future<Either<AuthFailure, EmailLinkType>> call(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    return _repository.sendEmailFlow(normalizedEmail);
  }
}

/// Which type of email link was sent.
///
/// The use case returns this so the Bloc can emit the correct state:
///   magicLink → AuthMagicLinkSent (returning user)
///   newUser   → AuthNewUserLinkSent (new user)
///
/// This enum lives in the domain layer because it's a business concept,
/// not a UI concept. The Bloc maps it to UI states.
/// The repository maps it from the backend response.
enum EmailLinkType {
  /// A magic link to sign in directly was sent.
  /// Used for returning users who have an existing account.
  magicLink,

  /// A "create your account" link was sent.
  /// Used for new users who don't have an account yet.
  newUser,
}
