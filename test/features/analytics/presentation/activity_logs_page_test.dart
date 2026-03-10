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
        ).subtract(Duration(minutes: index)),
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
    expect(analyticsRepository.requestedLimits, [20, 20]);
    expect(analyticsRepository.requestedBeforeValues, [null, isNotNull]);
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
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.activityLoadMoreError), findsOneWidget);
    expect(analyticsRepository.requestedLimits, [20, 20]);
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
    await tester.pumpAndSettle();

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
  final List<DateTime?> requestedBeforeValues = <DateTime?>[];

  @override
  Future<ActivityLogPage> listActivityLogs({
    required String zoneId,
    int limit = 20,
    DateTime? before,
  }) async {
    requestedLimits.add(limit);
    requestedBeforeValues.add(before);

    if (error != null) {
      throw error!;
    }

    final startIndex = before == null
        ? 0
        : logs.indexWhere((entry) => entry.timestamp.isBefore(before));
    final safeStartIndex = startIndex < 0 ? logs.length : startIndex;
    final pageEntries = logs
        .skip(safeStartIndex)
        .take(limit)
        .toList(growable: false);

    return ActivityLogPage(
      entries: List<ActivityLogEntry>.unmodifiable(pageEntries),
      hasMore: safeStartIndex + pageEntries.length < logs.length,
      nextBefore: pageEntries.length < limit
          ? null
          : pageEntries.last.timestamp.subtract(
              const Duration(milliseconds: 1),
            ),
    );
  }
}

class FailingLoadMoreAnalyticsRepository
    implements AnalyticsRepositoryContract {
  final List<int> requestedLimits = <int>[];

  @override
  Future<ActivityLogPage> listActivityLogs({
    required String zoneId,
    int limit = 20,
    DateTime? before,
  }) async {
    requestedLimits.add(limit);

    if (before != null) {
      throw Exception('load more failed');
    }

    final entries = List<ActivityLogEntry>.generate(
      25,
      (index) => ActivityLogEntry(
        address: 'alias-$index@example.com',
        status: 'forwarded',
        spf: 'pass',
        dkim: 'pass',
        dmarc: 'none',
        timestamp: DateTime.parse(
          '2026-03-09T10:15:00Z',
        ).subtract(Duration(minutes: index)),
      ),
    ).take(20).toList(growable: false);

    return ActivityLogPage(
      entries: entries,
      hasMore: true,
      nextBefore: entries.last.timestamp.subtract(
        const Duration(milliseconds: 1),
      ),
    );
  }
}

class InvalidLoadMoreAnalyticsRepository
    implements AnalyticsRepositoryContract {
  @override
  Future<ActivityLogPage> listActivityLogs({
    required String zoneId,
    int limit = 20,
    DateTime? before,
  }) async {
    if (before != null) {
      throw const AuthFailure.invalidToken();
    }

    final entries = List<ActivityLogEntry>.generate(
      25,
      (index) => ActivityLogEntry(
        address: 'alias-$index@example.com',
        status: 'forwarded',
        spf: 'pass',
        dkim: 'pass',
        dmarc: 'none',
        timestamp: DateTime.parse(
          '2026-03-09T10:15:00Z',
        ).subtract(Duration(minutes: index)),
      ),
    ).take(20).toList(growable: false);

    return ActivityLogPage(
      entries: entries,
      hasMore: true,
      nextBefore: entries.last.timestamp.subtract(
        const Duration(milliseconds: 1),
      ),
    );
  }
}

class AuthFailureLoadMoreAnalyticsRepository
    implements AnalyticsRepositoryContract {
  @override
  Future<ActivityLogPage> listActivityLogs({
    required String zoneId,
    int limit = 20,
    DateTime? before,
  }) async {
    if (before != null) {
      throw const AuthFailure.network();
    }

    final entries = List<ActivityLogEntry>.generate(
      25,
      (index) => ActivityLogEntry(
        address: 'alias-$index@example.com',
        status: 'forwarded',
        spf: 'pass',
        dkim: 'pass',
        dmarc: 'none',
        timestamp: DateTime.parse(
          '2026-03-09T10:15:00Z',
        ).subtract(Duration(minutes: index)),
      ),
    ).take(20).toList(growable: false);

    return ActivityLogPage(
      entries: entries,
      hasMore: true,
      nextBefore: entries.last.timestamp.subtract(
        const Duration(milliseconds: 1),
      ),
    );
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
