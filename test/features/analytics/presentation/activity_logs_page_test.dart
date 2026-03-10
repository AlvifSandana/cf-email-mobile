import 'package:bariskode_cf_email/core/constants/app_routes.dart';
import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/features/analytics/data/analytics_repository.dart';
import 'package:bariskode_cf_email/features/analytics/domain/entities/activity_log_entry.dart';
import 'package:bariskode_cf_email/features/analytics/presentation/pages/activity_logs_page.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/auth/domain/repositories/auth_repository.dart';
import 'package:bariskode_cf_email/features/domains/data/domain_repository.dart';
import 'package:bariskode_cf_email/features/domains/domain/entities/domain_summary.dart';
import 'package:bariskode_cf_email/features/domains/presentation/domain_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows empty state when no domain is selected', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityLogsPage(
            analyticsRepository: FakeAnalyticsRepository(),
            authRepository: FakeAuthRepository(),
            domainContext: DomainContext(repository: FakeDomainRepository()),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(AppStrings.activityNoDomainSelected), findsOneWidget);
  });

  testWidgets('renders activity log rows for selected domain', (
    WidgetTester tester,
  ) async {
    final domainContext = DomainContext(
      repository: FakeDomainRepository(
        domains: const [DomainSummary(id: 'zone-1', name: 'example.com')],
      ),
    )..selectDomain(const DomainSummary(id: 'zone-1', name: 'example.com'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityLogsPage(
            analyticsRepository: FakeAnalyticsRepository(
              logs: [
                ActivityLogEntry(
                  address: 'sales@example.com',
                  status: 'forwarded',
                  spf: 'pass',
                  dkim: 'pass',
                  dmarc: 'none',
                  timestamp: DateTime.parse('2026-03-09T10:15:00Z'),
                ),
              ],
            ),
            authRepository: FakeAuthRepository(),
            domainContext: domainContext,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('sales@example.com'), findsOneWidget);
    expect(
      find.text('forwarded · SPF pass · DKIM pass · DMARC none'),
      findsOneWidget,
    );
    expect(find.text('2026-03-09T10:15:00.000Z'), findsOneWidget);
    expect(
      find.text(AppStrings.activityListTitle('example.com')),
      findsOneWidget,
    );
    expect(find.text(AppStrings.activityLoadMoreButton), findsNothing);
  });

  testWidgets('loads more activity rows when requested', (
    WidgetTester tester,
  ) async {
    final domainContext = DomainContext(
      repository: FakeDomainRepository(
        domains: const [DomainSummary(id: 'zone-1', name: 'example.com')],
      ),
    )..selectDomain(const DomainSummary(id: 'zone-1', name: 'example.com'));

    final logs = List<ActivityLogEntry>.generate(
      25,
      (index) => ActivityLogEntry(
        address: 'alias-$index@example.com',
        status: 'forwarded',
        spf: 'pass',
        dkim: 'pass',
        dmarc: 'none',
        timestamp: DateTime.parse(
          '2026-03-09T10:15:00Z',
        ).add(Duration(minutes: index)),
      ),
    );

    final analyticsRepository = FakeAnalyticsRepository(logs: logs);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityLogsPage(
            analyticsRepository: analyticsRepository,
            authRepository: FakeAuthRepository(),
            domainContext: domainContext,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('alias-0@example.com'), findsOneWidget);
    expect(find.text('alias-24@example.com'), findsNothing);

    await tester.scrollUntilVisible(
      find.text(AppStrings.activityLoadMoreButton),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text(AppStrings.activityLoadMoreButton), findsOneWidget);

    await tester.tap(find.text(AppStrings.activityLoadMoreButton));
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('alias-24@example.com'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('alias-24@example.com'), findsOneWidget);
    expect(analyticsRepository.requestedLimits, [20, 40]);
  });

  testWidgets('shows retryable error on network failure without logout', (
    WidgetTester tester,
  ) async {
    final authRepository = FakeAuthRepository();
    final domainContext = DomainContext(
      repository: FakeDomainRepository(
        domains: const [DomainSummary(id: 'zone-1', name: 'example.com')],
      ),
    )..selectDomain(const DomainSummary(id: 'zone-1', name: 'example.com'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityLogsPage(
            analyticsRepository: FakeAnalyticsRepository(
              error: const AuthFailure.network(),
            ),
            authRepository: authRepository,
            domainContext: domainContext,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(authRepository.logoutCalls, 0);
    expect(find.text(AppStrings.activityLoadError), findsOneWidget);
    expect(find.text(AppStrings.retryButton), findsOneWidget);
  });

  testWidgets('shows snackbar when load more fails', (
    WidgetTester tester,
  ) async {
    final authRepository = FakeAuthRepository();
    final domainContext = DomainContext(
      repository: FakeDomainRepository(
        domains: const [DomainSummary(id: 'zone-1', name: 'example.com')],
      ),
    )..selectDomain(const DomainSummary(id: 'zone-1', name: 'example.com'));

    final analyticsRepository = FailingLoadMoreAnalyticsRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityLogsPage(
            analyticsRepository: analyticsRepository,
            authRepository: authRepository,
            domainContext: domainContext,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(AppStrings.activityLoadMoreButton),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text(AppStrings.activityLoadMoreButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(AppStrings.activityLoadMoreError), findsOneWidget);
    expect(analyticsRepository.requestedLimits, [20, 40]);
  });

  testWidgets('invalid token during load more invalidates session', (
    WidgetTester tester,
  ) async {
    final authRepository = FakeAuthRepository();
    final domainContext = DomainContext(
      repository: FakeDomainRepository(
        domains: const [DomainSummary(id: 'zone-1', name: 'example.com')],
      ),
    )..selectDomain(const DomainSummary(id: 'zone-1', name: 'example.com'));

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.login: (_) => const Scaffold(body: Text('Login Page')),
        },
        home: Scaffold(
          body: ActivityLogsPage(
            analyticsRepository: InvalidLoadMoreAnalyticsRepository(),
            authRepository: authRepository,
            domainContext: domainContext,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(AppStrings.activityLoadMoreButton),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text(AppStrings.activityLoadMoreButton));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(authRepository.logoutAttempts, 1);
    expect(find.text('Login Page'), findsOneWidget);
  });

  testWidgets('shows snackbar on load more auth network failure', (
    WidgetTester tester,
  ) async {
    final authRepository = FakeAuthRepository();
    final domainContext = DomainContext(
      repository: FakeDomainRepository(
        domains: const [DomainSummary(id: 'zone-1', name: 'example.com')],
      ),
    )..selectDomain(const DomainSummary(id: 'zone-1', name: 'example.com'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityLogsPage(
            analyticsRepository: AuthFailureLoadMoreAnalyticsRepository(),
            authRepository: authRepository,
            domainContext: domainContext,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(AppStrings.activityLoadMoreButton),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text(AppStrings.activityLoadMoreButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(AppStrings.activityLoadMoreError), findsOneWidget);
    expect(authRepository.logoutAttempts, 0);
  });

  testWidgets('invalid token invalidates session and navigates to login', (
    WidgetTester tester,
  ) async {
    final authRepository = FakeAuthRepository();
    final domainContext = DomainContext(
      repository: FakeDomainRepository(
        domains: const [DomainSummary(id: 'zone-1', name: 'example.com')],
      ),
    )..selectDomain(const DomainSummary(id: 'zone-1', name: 'example.com'));

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.login: (_) => const Scaffold(body: Text('Login Page')),
        },
        home: Scaffold(
          body: ActivityLogsPage(
            analyticsRepository: FakeAnalyticsRepository(
              error: const AuthFailure.invalidToken(),
            ),
            authRepository: authRepository,
            domainContext: domainContext,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(authRepository.logoutAttempts, 1);
    expect(find.text('Login Page'), findsOneWidget);
  });
}

class FakeAnalyticsRepository implements AnalyticsRepositoryContract {
  FakeAnalyticsRepository({this.logs = const [], this.error});

  final List<ActivityLogEntry> logs;
  final Exception? error;
  final List<int> requestedLimits = <int>[];

  @override
  Future<List<ActivityLogEntry>> listActivityLogs({
    required String zoneId,
    int limit = 20,
  }) async {
    requestedLimits.add(limit);

    if (error != null) {
      throw error!;
    }

    return List<ActivityLogEntry>.unmodifiable(logs.take(limit));
  }
}

class FailingLoadMoreAnalyticsRepository
    implements AnalyticsRepositoryContract {
  final List<int> requestedLimits = <int>[];

  @override
  Future<List<ActivityLogEntry>> listActivityLogs({
    required String zoneId,
    int limit = 20,
  }) async {
    requestedLimits.add(limit);

    if (limit > 20) {
      throw Exception('load more failed');
    }

    return List<ActivityLogEntry>.generate(
      25,
      (index) => ActivityLogEntry(
        address: 'alias-$index@example.com',
        status: 'forwarded',
        spf: 'pass',
        dkim: 'pass',
        dmarc: 'none',
        timestamp: DateTime.parse(
          '2026-03-09T10:15:00Z',
        ).add(Duration(minutes: index)),
      ),
    ).take(20).toList(growable: false);
  }
}

class InvalidLoadMoreAnalyticsRepository
    implements AnalyticsRepositoryContract {
  @override
  Future<List<ActivityLogEntry>> listActivityLogs({
    required String zoneId,
    int limit = 20,
  }) async {
    if (limit > 20) {
      throw const AuthFailure.invalidToken();
    }

    return List<ActivityLogEntry>.generate(
      25,
      (index) => ActivityLogEntry(
        address: 'alias-$index@example.com',
        status: 'forwarded',
        spf: 'pass',
        dkim: 'pass',
        dmarc: 'none',
        timestamp: DateTime.parse(
          '2026-03-09T10:15:00Z',
        ).add(Duration(minutes: index)),
      ),
    ).take(20).toList(growable: false);
  }
}

class AuthFailureLoadMoreAnalyticsRepository
    implements AnalyticsRepositoryContract {
  @override
  Future<List<ActivityLogEntry>> listActivityLogs({
    required String zoneId,
    int limit = 20,
  }) async {
    if (limit > 20) {
      throw const AuthFailure.network();
    }

    return List<ActivityLogEntry>.generate(
      25,
      (index) => ActivityLogEntry(
        address: 'alias-$index@example.com',
        status: 'forwarded',
        spf: 'pass',
        dkim: 'pass',
        dmarc: 'none',
        timestamp: DateTime.parse(
          '2026-03-09T10:15:00Z',
        ).add(Duration(minutes: index)),
      ),
    ).take(20).toList(growable: false);
  }
}

class FakeAuthRepository implements AuthRepository {
  int logoutCalls = 0;
  int logoutAttempts = 0;

  @override
  Future<bool> hasValidSession() async => true;

  @override
  Future<void> loginWithToken(String token) async {}

  @override
  Future<void> logout() async {
    logoutAttempts += 1;
    logoutCalls += 1;
  }

  @override
  Future<String?> readToken() async => 'token';
}

class FakeDomainRepository implements DomainRepositoryContract {
  FakeDomainRepository({this.domains = const []});

  final List<DomainSummary> domains;

  @override
  Future<List<DomainSummary>> listDomains() async => domains;
}
