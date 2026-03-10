import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/auth/domain/repositories/auth_repository.dart';
import 'package:bariskode_cf_email/features/domains/data/domain_repository.dart';
import 'package:bariskode_cf_email/features/domains/data/selected_domain_store.dart';
import 'package:bariskode_cf_email/features/domains/domain/entities/domain_summary.dart';
import 'package:bariskode_cf_email/features/domains/presentation/domain_context.dart';
import 'package:bariskode_cf_email/shared/utils/session_resolution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveSession', () {
    test(
      'returns no-session without invalidation when no token is stored',
      () async {
        final authRepository = FakeAuthRepository(hasValidSessionResult: false);
        final domainContext = DomainContext(repository: FakeDomainRepository());

        final resolution = await resolveSession(
          authRepository: authRepository,
          domainContext: domainContext,
        );

        expect(resolution.hasValidSession, isFalse);
        expect(resolution.hadStoredToken, isFalse);
        expect(resolution.shouldInvalidateSession, isFalse);
      },
    );

    test('tracks stored token when saved session is no longer valid', () async {
      final authRepository = FakeAuthRepository(
        initialToken: 'saved-token',
        hasValidSessionResult: false,
      );
      final domainContext = DomainContext(repository: FakeDomainRepository());

      final resolution = await resolveSession(
        authRepository: authRepository,
        domainContext: domainContext,
      );

      expect(resolution.hasValidSession, isFalse);
      expect(resolution.hadStoredToken, isTrue);
      expect(resolution.shouldInvalidateSession, isFalse);
    });

    test('returns valid session after successful domain load', () async {
      final authRepository = FakeAuthRepository(initialToken: 'saved-token');
      final domainRepository = FakeDomainRepository(
        domains: const [DomainSummary(id: 'zone-1', name: 'example.com')],
      );
      final domainContext = DomainContext(
        repository: domainRepository,
        selectedDomainStore: FakeSelectedDomainStore(),
      );

      final resolution = await resolveSession(
        authRepository: authRepository,
        domainContext: domainContext,
      );

      expect(resolution.hasValidSession, isTrue);
      expect(resolution.hadStoredToken, isTrue);
      expect(resolution.shouldInvalidateSession, isFalse);
      expect(domainRepository.listCalls, 1);
      expect(domainContext.selectedDomain?.id, 'zone-1');
    });

    test(
      'requests invalidation when domain load reports invalid token',
      () async {
        final authRepository = FakeAuthRepository(initialToken: 'saved-token');
        final domainContext = DomainContext(
          repository: FakeDomainRepository(
            authFailure: const AuthFailure.invalidToken(),
          ),
        );

        final resolution = await resolveSession(
          authRepository: authRepository,
          domainContext: domainContext,
        );

        expect(resolution.hasValidSession, isFalse);
        expect(resolution.hadStoredToken, isTrue);
        expect(resolution.shouldInvalidateSession, isTrue);
      },
    );

    test(
      'requests invalidation when domain load reports insufficient permissions',
      () async {
        final authRepository = FakeAuthRepository(initialToken: 'saved-token');
        final domainContext = DomainContext(
          repository: FakeDomainRepository(
            authFailure: const AuthFailure.insufficientPermissions(),
          ),
        );

        final resolution = await resolveSession(
          authRepository: authRepository,
          domainContext: domainContext,
        );

        expect(resolution.hasValidSession, isFalse);
        expect(resolution.hadStoredToken, isTrue);
        expect(resolution.shouldInvalidateSession, isTrue);
      },
    );

    test(
      'skips domain reload when domain context is already populated',
      () async {
        final authRepository = FakeAuthRepository(initialToken: 'saved-token');
        final domainRepository = FakeDomainRepository(
          domains: const [DomainSummary(id: 'zone-1', name: 'example.com')],
        );
        final domainContext = DomainContext(
          repository: domainRepository,
          selectedDomainStore: FakeSelectedDomainStore(),
        )..selectDomain(const DomainSummary(id: 'zone-1', name: 'example.com'));

        final resolution = await resolveSession(
          authRepository: authRepository,
          domainContext: domainContext,
        );

        expect(resolution.hasValidSession, isTrue);
        expect(resolution.shouldInvalidateSession, isFalse);
        expect(domainRepository.listCalls, 0);
      },
    );
  });
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.initialToken, this.hasValidSessionResult});

  final String? initialToken;
  final bool? hasValidSessionResult;

  @override
  Future<bool> hasValidSession() async {
    if (hasValidSessionResult != null) {
      return hasValidSessionResult!;
    }

    return initialToken != null && initialToken!.isNotEmpty;
  }

  @override
  Future<void> loginWithToken(String token) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<String?> readToken() async => initialToken;
}

class FakeDomainRepository implements DomainRepositoryContract {
  FakeDomainRepository({this.domains = const [], this.authFailure});

  final List<DomainSummary> domains;
  final AuthFailure? authFailure;
  int listCalls = 0;

  @override
  Future<List<DomainSummary>> listDomains() async {
    listCalls += 1;

    if (authFailure != null) {
      throw authFailure!;
    }

    return domains;
  }
}

class FakeSelectedDomainStore implements SelectedDomainStoreContract {
  @override
  Future<void> clearSelectedDomainId() async {}

  @override
  Future<String?> readSelectedDomainId() async => null;

  @override
  Future<void> saveSelectedDomainId(String domainId) async {}
}
