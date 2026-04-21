import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

// Note: this use case returns a Stream, not Either.
// Streams don't fail in the same way — individual events can carry
// null (signed out) or AuthUser (signed in).
// Stream-level errors are handled in the Bloc's stream subscription.
class WatchAuthStateUseCase {
  final AuthRepository _repository;

  const WatchAuthStateUseCase(this._repository);

  Stream<AuthUser?> call() {
    return _repository.watchAuthState();
  }
}
