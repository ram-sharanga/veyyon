import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:veyyon/features/auth/data/datasources/local_auth_datasource.dart';
import 'package:veyyon/features/auth/data/datasources/remote_auth_datasource.dart';
import 'package:veyyon/features/auth/data/models/auth_user_model.dart';
import 'package:veyyon/features/auth/domain/entities/auth_failure.dart';
import 'package:veyyon/features/auth/domain/entities/auth_user.dart';
import 'package:veyyon/features/auth/domain/repositories/auth_repository.dart';
import 'package:veyyon/features/auth/domain/usecases/send_email_flow_usecase.dart';
import 'package:veyyon/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:veyyon/core/security/secure_storage_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final RemoteAuthDataSource _remoteDataSource;
  final LocalAuthDataSource _localDataSource;
  final SecureStorageService _secureStorage;

  const AuthRepositoryImpl({
    required this._remoteDataSource,
    required this._localDataSource,
    required this._secureStorage,
  });

  AuthFailure _mapExceptionToFailure(Object exception) {
    if (exception is NetworkException) {
      return NetworkFailure(exception.message);
    }
    if (exception is RateLimitExceededException) {
      return RateLimitExceeded(retryAfterSeconds: exception.retryAfterSeconds);
    }
    if (exception is EmailNotRegisteredException) {
      return const EmailNotRegistered();
    }
    if (exception is MagicLinkExpiredException) {
      return const MagicLinkExpired();
    }
    if (exception is MagicLinkAlreadyUsedException) {
      return const MagicLinkAlreadyUsed();
    }
    if (exception is ServerException) {
      return ServerFailure(exception.message);
    }
    return UnknownFailure(exception.toString());
  }

  @override
  Future<Either<AuthFailure, void>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      await _localDataSource.clearCache();
      await _secureStorage.deleteAll();
      return const Right(null);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<AuthFailure, AuthUser?>> getCurrentUser() async {
    try {
      final supabaseUser = _remoteDataSource.getCurrentUser();

      if (supabaseUser == null) return const Right(null);

      final cachedUser = _localDataSource.getCachedUser();
      if (cachedUser != null && cachedUser.id == supabaseUser.id) {
        return Right(cachedUser.toEntity());
      }

      final profileData = await _remoteDataSource.fetchProfile(supabaseUser.id);
      final userModel = AuthUserModel.fromSupabase(
        user: supabaseUser,
        profileData: profileData,
      );
      await _localDataSource.cacheUser(userModel);
      return Right(userModel.toEntity());
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Stream<AuthUser?> watchAuthState() {
    return _remoteDataSource.watchAuthState().asyncMap((authState) async {
      final event = authState.event;
      final session = authState.session;

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.userUpdated) {
        if (session?.user == null) return null;

        try {
          final cached = _localDataSource.getCachedUser();
          if (cached != null && cached.id == session!.user.id) {
            return cached.toEntity();
          }

          final profileData = await _remoteDataSource.fetchProfile(
            session!.user.id,
          );
          final userModel = AuthUserModel.fromSupabase(
            user: session.user,
            profileData: profileData,
          );
          await _localDataSource.cacheUser(userModel);
          return userModel.toEntity();
        } catch (_) {
          return null;
        }
      }

      await _localDataSource.clearCache();
      return null;
    });
  }

  @override
  Future<Either<AuthFailure, bool>> checkUsernameAvailability(
    String username,
  ) async {
    try {
      final isAvailable = await _remoteDataSource.isUsernameAvailable(username);
      return Right(isAvailable);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> setUsername(String username) async {
    try {
      final currentUser = _remoteDataSource.getCurrentUser();
      if (currentUser == null) {
        return const Left(ServerFailure('No authenticated user found.'));
      }

      await _remoteDataSource.setUsername(currentUser.id, username);

      final cached = _localDataSource.getCachedUser();
      if (cached != null) {
        final updated = AuthUserModel(
          id: cached.id,
          email: cached.email,
          name: cached.name,
          isOnboarded: true,
        );
        await _localDataSource.cacheUser(updated);
      }

      return const Right(null);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> deleteAccount() async {
    try {
      final accessToken = _remoteDataSource.getCurrentAccessToken();
      if (accessToken == null) {
        return const Left(ServerFailure('No active session.'));
      }

      // TODO: Call Go backend when it is set up.
      await _remoteDataSource.signOut();
      await _localDataSource.clearCache();
      await _secureStorage.deleteAll();
      return const Right(null);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<AuthFailure, bool>> checkEmailExists(String email) async {
    try {
      final exists = await _remoteDataSource.checkEmailExists(email);
      return Right(exists);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> sendMagicLink(String email) async {
    try {
      await _remoteDataSource.sendMagicLink(email);
      return const Right(null);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<AuthFailure, void>> sendNewUserLink(String email) async {
    try {
      await _remoteDataSource.sendNewUserLink(email);
      return const Right(null);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<AuthFailure, EmailLinkType>> sendEmailFlow(String email) async {
    try {
      final exists = await _remoteDataSource.checkEmailExists(email);
      if (exists) {
        await _remoteDataSource.sendMagicLink(email);
        return const Right(EmailLinkType.magicLink);
      } else {
        await _remoteDataSource.sendNewUserLink(email);
        return const Right(EmailLinkType.newUser);
      }
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<AuthFailure, AuthUser>> verifyOtp({
    required String email,
    required String token,
    required OtpVerificationType type,
  }) async {
    try {
      final authResponse = await _remoteDataSource.verifyOtp(
        email: email,
        token: token,
        type: type,
      );

      final profileData = await _remoteDataSource.fetchProfile(
        authResponse.user!.id,
      );

      final userModel = AuthUserModel.fromSupabase(
        user: authResponse.user!,
        profileData: profileData,
      );

      await _localDataSource.cacheUser(userModel);
      return Right(userModel.toEntity());
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }
}
