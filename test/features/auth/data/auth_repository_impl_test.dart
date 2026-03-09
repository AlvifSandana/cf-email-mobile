import 'package:bariskode_cf_email/features/auth/data/auth_repository_impl.dart';
import 'package:bariskode_cf_email/core/network/api_client.dart';
import 'package:bariskode_cf_email/core/network/auth_header_provider.dart';
import 'package:bariskode_cf_email/core/network/cloudflare_auth_api.dart';
import 'package:bariskode_cf_email/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/auth/domain/services/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('hasValidSession returns false when stored token is empty', () async {
    final repository = AuthRepositoryImpl(
      localDataSource: FakeAuthLocalDataSource('   '),
      remoteDataSource: FakeAuthRemoteDataSource(),
    );

    final result = await repository.hasValidSession();

    expect(result, isFalse);
  });

  test('hasValidSession validates remote session when token exists', () async {
    final remoteDataSource = FakeAuthRemoteDataSource();
    final repository = AuthRepositoryImpl(
      localDataSource: FakeAuthLocalDataSource('token-123'),
      remoteDataSource: remoteDataSource,
    );

    final result = await repository.hasValidSession();

    expect(result, isTrue);
    expect(remoteDataSource.validateStoredSessionCalls, 1);
  });

  test(
    'hasValidSession clears stored token on invalid token failure',
    () async {
      final localDataSource = FakeAuthLocalDataSource('token-123');
      final repository = AuthRepositoryImpl(
        localDataSource: localDataSource,
        remoteDataSource: FakeAuthRemoteDataSource(
          sessionFailure: const AuthFailure.invalidToken(),
        ),
      );

      final result = await repository.hasValidSession();

      expect(result, isFalse);
      expect(localDataSource.clearCalls, 1);
    },
  );

  test(
    'hasValidSession clears stored token on insufficient permissions failure',
    () async {
      final localDataSource = FakeAuthLocalDataSource('token-123');
      final repository = AuthRepositoryImpl(
        localDataSource: localDataSource,
        remoteDataSource: FakeAuthRemoteDataSource(
          sessionFailure: const AuthFailure.insufficientPermissions(),
        ),
      );

      final result = await repository.hasValidSession();

      expect(result, isFalse);
      expect(localDataSource.clearCalls, 1);
    },
  );

  test('hasValidSession rethrows network failure', () async {
    final repository = AuthRepositoryImpl(
      localDataSource: FakeAuthLocalDataSource('token-123'),
      remoteDataSource: FakeAuthRemoteDataSource(
        sessionFailure: const AuthFailure.network(),
      ),
    );

    expect(
      repository.hasValidSession(),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.type,
          'type',
          AuthFailureType.network,
        ),
      ),
    );
  });

  test('hasValidSession still returns false when token clear fails', () async {
    final localDataSource = FakeAuthLocalDataSource(
      'token-123',
      clearFailure: Exception('secure storage error'),
    );
    final repository = AuthRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: FakeAuthRemoteDataSource(
        sessionFailure: const AuthFailure.invalidToken(),
      ),
    );

    final result = await repository.hasValidSession();

    expect(result, isFalse);
    expect(localDataSource.clearCalls, 1);
  });

  test('loginWithToken validates then saves token', () async {
    final localDataSource = FakeAuthLocalDataSource(null);
    final remoteDataSource = FakeAuthRemoteDataSource();
    final repository = AuthRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
    );

    await repository.loginWithToken('token-abc');

    expect(remoteDataSource.validatedTokens, ['token-abc']);
    expect(localDataSource.savedToken, 'token-abc');
  });

  test('logout clears token', () async {
    final localDataSource = FakeAuthLocalDataSource('token-abc');
    final repository = AuthRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: FakeAuthRemoteDataSource(),
    );

    await repository.logout();

    expect(localDataSource.clearCalls, 1);
  });
}

class FakeAuthLocalDataSource implements SessionStore {
  FakeAuthLocalDataSource(this.initialToken, {this.clearFailure});

  final String? initialToken;
  final Exception? clearFailure;
  String? savedToken;
  int clearCalls = 0;

  @override
  Future<void> clearToken() async {
    clearCalls += 1;

    if (clearFailure != null) {
      throw clearFailure!;
    }

    savedToken = null;
  }

  @override
  Future<String?> readToken() async => savedToken ?? initialToken;

  @override
  Future<void> saveToken(String token) async {
    savedToken = token;
  }
}

class FakeAuthRemoteDataSource extends AuthRemoteDataSource {
  FakeAuthRemoteDataSource({this.sessionFailure})
    : super(
        authApi: CloudflareAuthApi(client: http.Client()),
        apiClient: ApiClient(
          client: http.Client(),
          headers: AuthHeaderProvider(FakeAuthLocalDataSource(null)),
        ),
      );

  final AuthFailure? sessionFailure;
  final List<String> validatedTokens = <String>[];
  int validateStoredSessionCalls = 0;

  @override
  Future<void> validateStoredSession() async {
    validateStoredSessionCalls += 1;

    if (sessionFailure != null) {
      throw sessionFailure!;
    }
  }

  @override
  Future<void> validateToken(String token) async {
    validatedTokens.add(token);
  }
}
