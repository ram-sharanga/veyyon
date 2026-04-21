import 'package:dartz/dartz.dart';
import '../entities/auth_failure.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository _repository;

  const GetCurrentUserUseCase(this._repository);

  Future<Either<AuthFailure, AuthUser?>> call() {
    return _repository.getCurrentUser();
  }
}
