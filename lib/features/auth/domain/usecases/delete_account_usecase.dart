import 'package:dartz/dartz.dart';
import '../entities/auth_failure.dart';
import '../repositories/auth_repository.dart';

class DeleteAccountUseCase {
  final AuthRepository _repository;

  const DeleteAccountUseCase(this._repository);

  Future<Either<AuthFailure, void>> call() {
    return _repository.deleteAccount();
  }
}
