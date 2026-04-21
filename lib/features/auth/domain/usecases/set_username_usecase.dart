import 'package:dartz/dartz.dart';
import '../entities/auth_failure.dart';
import '../repositories/auth_repository.dart';

class SetUsernameUseCase {
  final AuthRepository _repository;

  const SetUsernameUseCase(this._repository);

  Future<Either<AuthFailure, void>> call(String username) {
    return _repository.setUsername(username);
  }
}
