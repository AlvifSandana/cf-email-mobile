import 'package:bariskode_cf_email/features/auth/domain/repositories/auth_repository.dart';
import 'package:bariskode_cf_email/features/domains/data/domain_repository.dart';
import 'package:bariskode_cf_email/features/domains/domain/entities/domain_summary.dart';
import 'package:bariskode_cf_email/features/domains/presentation/domain_context.dart';
import 'package:bariskode_cf_email/shared/utils/session_invalidator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'invalidateSession reports cleared session when logout succeeds',
    () async {
      final authRepository = TrackingAuthRepository();
      final domainContext = TrackingDomainContext()
        ..selectDomain(const DomainSummary(id: 'zone-1', name: 'example.com'));

      final result = await invalidateSession(
        authRepository: authRepository,
        domainContext: domainContext,
      );

      expect(result.didClearStoredSession, isTrue);
      expect(authRepository.logoutAttempts, 1);
      expect(domainContext.clearSelectionCalls, 1);
      expect(domainContext.selectedDomain, isNull);
    },
  );

  test(
    'invalidateSession reports incomplete cleanup when logout fails',
    () async {
      final authRepository = TrackingAuthRepository(
        logoutFailure: Exception('secure storage failed'),
      );
      final domainContext = TrackingDomainContext()
        ..selectDomain(const DomainSummary(id: 'zone-1', name: 'example.com'));

      final result = await invalidateSession(
        authRepository: authRepository,
        domainContext: domainContext,
      );

      expect(result.didClearStoredSession, isFalse);
      expect(authRepository.logoutAttempts, 1);
      expect(domainContext.clearSelectionCalls, 1);
      expect(domainContext.selectedDomain, isNull);
    },
  );

  test(
    'invalidateSession reports incomplete cleanup when persisted domain clear fails',
    () async {
      final authRepository = TrackingAuthRepository();
      final domainContext = TrackingDomainContext(
        clearPersistedSelectionSucceeds: false,
      )..selectDomain(const DomainSummary(id: 'zone-1', name: 'example.com'));

      final result = await invalidateSession(
        authRepository: authRepository,
        domainContext: domainContext,
      );

      expect(result.didClearStoredSession, isFalse);
      expect(authRepository.logoutAttempts, 1);
      expect(domainContext.clearSelectionCalls, 1);
      expect(domainContext.selectedDomain, isNull);
    },
  );

  test(
    'invalidateSession clears domain selection even without active domain',
    () async {
      final authRepository = TrackingAuthRepository();
      final domainContext = TrackingDomainContext();

      await invalidateSession(
        authRepository: authRepository,
        domainContext: domainContext,
      );

      expect(domainContext.clearSelectionCalls, 1);
      expect(domainContext.selectedDomain, isNull);
    },
  );
}

class TrackingAuthRepository implements AuthRepository {
  TrackingAuthRepository({this.logoutFailure});

  final Exception? logoutFailure;
  int logoutAttempts = 0;

  @override
  Future<bool> hasValidSession() async => false;

  @override
  Future<void> loginWithToken(String token) async {}

  @override
  Future<void> logout() async {
    logoutAttempts += 1;
    if (logoutFailure != null) {
      throw logoutFailure!;
    }
  }

  @override
  Future<String?> readToken() async => null;
}

class TrackingDomainContext extends DomainContext {
  TrackingDomainContext({this.clearPersistedSelectionSucceeds = true})
    : super(repository: _NoopDomainRepository());

  final bool clearPersistedSelectionSucceeds;
  int clearSelectionCalls = 0;

  @override
  Future<bool> clearSelectionAndWait() async {
    clearSelectionCalls += 1;
    super.clearSelection();
    return clearPersistedSelectionSucceeds;
  }
}

class _NoopDomainRepository implements DomainRepositoryContract {
  @override
  Future<List<DomainSummary>> listDomains() async => const [];
}
