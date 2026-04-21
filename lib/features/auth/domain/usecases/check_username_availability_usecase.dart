import 'package:dartz/dartz.dart';
import '../entities/auth_failure.dart';
import '../repositories/auth_repository.dart';

class CheckUsernameAvailabilityUseCase {
  final AuthRepository _repository;

  const CheckUsernameAvailabilityUseCase(this._repository);

  /// [username] is the raw string from the text field.
  /// Format validation happens in the Bloc before this is called.
  /// This use case only checks database availability.
  Future<Either<AuthFailure, bool>> call(String username) {
    return _repository.checkUsernameAvailability(username);
  }
}
