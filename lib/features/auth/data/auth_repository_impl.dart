import 'package:bariskode_cf_email/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/auth/domain/repositories/auth_repository.dart';
import 'package:bariskode_cf_email/features/auth/domain/services/session_store.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  final SessionStore localDataSource;
  final AuthRemoteDataSource remoteDataSource;

  @override
  Future<bool> hasValidSession() async {
    final token = await localDataSource.readToken();

    if (token == null || token.trim().isEmpty) {
      return false;
    }

    try {
      await remoteDataSource.validateStoredSession();
      return true;
    } on AuthFailure catch (failure) {
      if (failure.type == AuthFailureType.invalidToken ||
          failure.type == AuthFailureType.insufficientPermissions) {
        try {
          await localDataSource.clearToken();
        } catch (_) {}

        return false;
      }

      rethrow;
    }
  }

  @override
  Future<void> loginWithToken(String token) async {
    await remoteDataSource.validateToken(token);
    await localDataSource.saveToken(token);
  }

  @override
  Future<void> logout() {
    return localDataSource.clearToken();
  }

  @override
  Future<String?> readToken() {
    return localDataSource.readToken();
  }
}
