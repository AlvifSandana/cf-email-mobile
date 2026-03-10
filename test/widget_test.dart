import 'dart:async';

import 'package:bariskode_cf_email/app/app.dart';
import 'package:bariskode_cf_email/core/constants/app_routes.dart';
import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/features/analytics/data/analytics_repository.dart';
import 'package:bariskode_cf_email/features/analytics/domain/entities/activity_log_entry.dart';
import 'package:bariskode_cf_email/features/aliases/data/alias_repository.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/auth/domain/repositories/auth_repository.dart';
import 'package:bariskode_cf_email/features/catchall/data/catchall_repository.dart';
import 'package:bariskode_cf_email/features/catchall/domain/entities/catchall_entry.dart';
import 'package:bariskode_cf_email/features/domains/data/domain_repository.dart';
import 'package:bariskode_cf_email/features/domains/data/selected_domain_store.dart';
import 'package:bariskode_cf_email/features/domains/domain/entities/domain_summary.dart';
import 'package:bariskode_cf_email/features/domains/presentation/domain_context.dart';
import 'package:bariskode_cf_email/shared/models/alias_model.dart';
import 'package:bariskode_cf_email/shared/models/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('app startup routing', () {
    testWidgets('shows login when there is no saved session', (
      WidgetTester tester,
    ) async {
      final selectedDomainStore = FakeSelectedDomainStore(
        initialDomainId: 'zone-1',
      );
      final domainContext = DomainContext(
        repository: FakeDomainRepository(),
        selectedDomainStore: selectedDomainStore,
      )..selectDomain(const DomainSummary(id: 'zone-1', name: 'example.com'));

      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(),
          domainContext: domainContext,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(AppStrings.loginTitle), findsOneWidget);
      expect(find.text(AppStrings.loginButton), findsOneWidget);
      expect(domainContext.selectedDomain?.id, 'zone-1');
      expect(selectedDomainStore.clearCalls, 0);
    });

    testWidgets('shows app shell when there is a saved session', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NavigationDestination), findsNWidgets(5));
      expect(find.text(AppStrings.dashboardTitle), findsWidgets);
    });

    testWidgets('shows retryable startup error on network failure', (
      WidgetTester tester,
    ) async {
      final authRepository = FakeAuthRepository(
        startupFailure: const AuthFailure.network(),
      );

      await tester.pumpWidget(buildTestApp(authRepository: authRepository));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.authStartupError), findsOneWidget);
      expect(find.text(AppStrings.retryButton), findsOneWidget);

      authRepository.startupFailure = null;
      await tester.tap(find.text(AppStrings.retryButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.loginTitle), findsOneWidget);
    });

    testWidgets(
      'startup clears selected domain when saved session becomes invalid',
      (WidgetTester tester) async {
        final selectedDomainStore = FakeSelectedDomainStore(
          initialDomainId: 'zone-1',
        );
        final domainContext = DomainContext(
          repository: FakeDomainRepository(),
          selectedDomainStore: selectedDomainStore,
        )..selectDomain(const DomainSummary(id: 'zone-1', name: 'example.com'));
        final authRepository = FakeAuthRepository(
          initialToken: _validToken,
          hasValidSessionResult: false,
        );

        await tester.pumpWidget(
          buildTestApp(
            authRepository: authRepository,
            domainContext: domainContext,
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text(AppStrings.loginTitle), findsOneWidget);
        expect(domainContext.selectedDomain, isNull);
        expect(selectedDomainStore.clearCalls, greaterThanOrEqualTo(1));
      },
    );

    testWidgets('shell route guard redirects unauthenticated access to login', (
      WidgetTester tester,
    ) async {
      final selectedDomainStore = FakeSelectedDomainStore(
        initialDomainId: 'zone-1',
      );
      final domainContext = DomainContext(
        repository: FakeDomainRepository(),
        selectedDomainStore: selectedDomainStore,
      )..selectDomain(const DomainSummary(id: 'zone-1', name: 'example.com'));

      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.shell,
          routes: {
            AppRoutes.shell: (_) => ProtectedShellRoute(
              authRepository: FakeAuthRepository(hasValidSessionResult: false),
              domainContext: domainContext,
              child: const Scaffold(body: Text('Shell Page')),
            ),
            AppRoutes.login: (_) =>
                const Scaffold(body: Text(AppStrings.loginTitle)),
          },
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.loginTitle), findsOneWidget);
      expect(find.text('Shell Page'), findsNothing);
      expect(domainContext.selectedDomain?.id, 'zone-1');
      expect(selectedDomainStore.clearCalls, 0);
    });

    testWidgets(
      'shell route guard clears selected domain when saved session becomes invalid',
      (WidgetTester tester) async {
        final selectedDomainStore = FakeSelectedDomainStore(
          initialDomainId: 'zone-1',
        );
        final domainContext = DomainContext(
          repository: FakeDomainRepository(),
          selectedDomainStore: selectedDomainStore,
        )..selectDomain(const DomainSummary(id: 'zone-1', name: 'example.com'));

        await tester.pumpWidget(
          MaterialApp(
            initialRoute: AppRoutes.shell,
            routes: {
              AppRoutes.shell: (_) => ProtectedShellRoute(
                authRepository: FakeAuthRepository(
                  initialToken: _validToken,
                  hasValidSessionResult: false,
                ),
                domainContext: domainContext,
                child: const Scaffold(body: Text('Shell Page')),
              ),
              AppRoutes.login: (_) =>
                  const Scaffold(body: Text(AppStrings.loginTitle)),
            },
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.loginTitle), findsOneWidget);
        expect(find.text('Shell Page'), findsNothing);
        expect(domainContext.selectedDomain, isNull);
        expect(selectedDomainStore.clearCalls, greaterThanOrEqualTo(1));
      },
    );

    testWidgets(
      'shell route guard retry recovers after transient session check failure',
      (WidgetTester tester) async {
        final authRepository = FakeAuthRepository(
          initialToken: _validToken,
          startupFailure: const AuthFailure.network(),
        );

        final domainContext = DomainContext(
          repository: FakeDomainRepository(),
        )..selectDomain(const DomainSummary(id: 'zone-1', name: 'example.com'));

        await tester.pumpWidget(
          MaterialApp(
            initialRoute: AppRoutes.shell,
            routes: {
              AppRoutes.shell: (_) => ProtectedShellRoute(
                authRepository: authRepository,
                domainContext: domainContext,
                child: const Scaffold(body: Text('Shell Page')),
              ),
              AppRoutes.login: (_) =>
                  const Scaffold(body: Text(AppStrings.loginTitle)),
            },
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.authStartupError), findsOneWidget);

        authRepository.startupFailure = null;
        await tester.tap(find.text(AppStrings.retryButton));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Shell Page'), findsOneWidget);
        expect(find.text(AppStrings.loginTitle), findsNothing);
      },
    );

    testWidgets(
      'shell route guard invalidates session when domain load reports invalid auth',
      (WidgetTester tester) async {
        final selectedDomainStore = FakeSelectedDomainStore(
          initialDomainId: 'zone-1',
        );
        final domainContext = DomainContext(
          repository: FakeDomainRepository(
            authFailure: const AuthFailure.invalidToken(),
          ),
          selectedDomainStore: selectedDomainStore,
        );
        final authRepository = FakeAuthRepository(initialToken: _validToken);

        await tester.pumpWidget(
          MaterialApp(
            initialRoute: AppRoutes.shell,
            routes: {
              AppRoutes.shell: (_) => ProtectedShellRoute(
                authRepository: authRepository,
                domainContext: domainContext,
                child: const Scaffold(body: Text('Shell Page')),
              ),
              AppRoutes.login: (_) =>
                  const Scaffold(body: Text(AppStrings.loginTitle)),
            },
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.loginTitle), findsOneWidget);
        expect(find.text('Shell Page'), findsNothing);
        expect(domainContext.selectedDomain, isNull);
        expect(selectedDomainStore.clearCalls, greaterThanOrEqualTo(1));
        expect(authRepository.logoutAttempts, 1);
      },
    );

    testWidgets(
      'shell route guard shows cleanup warning when logout fails during invalidation',
      (WidgetTester tester) async {
        final selectedDomainStore = FakeSelectedDomainStore(
          initialDomainId: 'zone-1',
        );
        final domainContext = DomainContext(
          repository: FakeDomainRepository(
            authFailure: const AuthFailure.invalidToken(),
          ),
          selectedDomainStore: selectedDomainStore,
        );
        final authRepository = FakeAuthRepository(
          initialToken: _validToken,
          logoutFailure: Exception('secure storage delete failed'),
        );

        await tester.pumpWidget(
          MaterialApp(
            initialRoute: AppRoutes.shell,
            routes: {
              AppRoutes.shell: (_) => ProtectedShellRoute(
                authRepository: authRepository,
                domainContext: domainContext,
                child: const Scaffold(body: Text('Shell Page')),
              ),
              AppRoutes.login: (_) =>
                  const Scaffold(body: Text(AppStrings.loginTitle)),
            },
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.loginTitle), findsOneWidget);
        expect(find.text(AppStrings.authSessionCleanupWarning), findsOneWidget);
        expect(authRepository.logoutAttempts, 1);
        expect(selectedDomainStore.clearCalls, greaterThanOrEqualTo(1));
      },
    );

    testWidgets(
      'shell route guard invalidates session on insufficient permissions',
      (WidgetTester tester) async {
        final selectedDomainStore = FakeSelectedDomainStore(
          initialDomainId: 'zone-1',
        );
        final domainContext = DomainContext(
          repository: FakeDomainRepository(
            authFailure: const AuthFailure.insufficientPermissions(),
          ),
          selectedDomainStore: selectedDomainStore,
        );
        final authRepository = FakeAuthRepository(initialToken: _validToken);

        await tester.pumpWidget(
          MaterialApp(
            initialRoute: AppRoutes.shell,
            routes: {
              AppRoutes.shell: (_) => ProtectedShellRoute(
                authRepository: authRepository,
                domainContext: domainContext,
                child: const Scaffold(body: Text('Shell Page')),
              ),
              AppRoutes.login: (_) =>
                  const Scaffold(body: Text(AppStrings.loginTitle)),
            },
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.loginTitle), findsOneWidget);
        expect(find.text('Shell Page'), findsNothing);
        expect(domainContext.selectedDomain, isNull);
        expect(selectedDomainStore.clearCalls, greaterThanOrEqualTo(1));
        expect(authRepository.logoutAttempts, 1);
      },
    );

    testWidgets(
      'shell route guard shows retryable error on session check failure',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            initialRoute: AppRoutes.shell,
            routes: {
              AppRoutes.shell: (_) => ProtectedShellRoute(
                authRepository: FakeAuthRepository(
                  startupFailure: const AuthFailure.network(),
                ),
                domainContext: DomainContext(
                  repository: FakeDomainRepository(),
                ),
                child: const Scaffold(body: Text('Shell Page')),
              ),
              AppRoutes.login: (_) =>
                  const Scaffold(body: Text(AppStrings.loginTitle)),
            },
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.authStartupError), findsOneWidget);
        expect(find.text(AppStrings.retryButton), findsOneWidget);
      },
    );
  });

  group('login flow', () {
    testWidgets('validates empty token locally', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(authRepository: FakeAuthRepository()),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.loginButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.loginValidationEmpty), findsOneWidget);
    });

    testWidgets('saves token and navigates to shell after successful login', (
      WidgetTester tester,
    ) async {
      final authRepository = FakeAuthRepository();

      await tester.pumpWidget(buildTestApp(authRepository: authRepository));

      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), _validToken);
      await tester.tap(find.text(AppStrings.loginButton));
      await tester.pumpAndSettle();

      expect(authRepository.savedTokens, [_validToken]);
      expect(find.text(AppStrings.dashboardTitle), findsWidgets);
    });

    testWidgets('shows invalid token error from repository failure', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(
            loginFailure: const AuthFailure.invalidToken(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), _validToken);
      await tester.tap(find.text(AppStrings.loginButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.authErrorInvalidToken), findsOneWidget);
    });
  });

  group('logout flow', () {
    testWidgets('clears session and returns to login', (
      WidgetTester tester,
    ) async {
      final authRepository = FakeAuthRepository(initialToken: _validToken);

      await tester.pumpWidget(buildTestApp(authRepository: authRepository));

      await tester.pumpAndSettle();
      await tapNavTab(tester, AppStrings.settingsTab);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.logoutButton));
      await tester.pumpAndSettle();

      expect(authRepository.logoutCalls, 1);
      expect(find.text(AppStrings.loginTitle), findsOneWidget);
    });

    testWidgets('shows snackbar and stays in shell when logout fails', (
      WidgetTester tester,
    ) async {
      final authRepository = FakeAuthRepository(
        initialToken: _validToken,
        logoutFailure: Exception('storage failed'),
      );

      await tester.pumpWidget(buildTestApp(authRepository: authRepository));
      await tester.pumpAndSettle();
      await tapNavTab(tester, AppStrings.settingsTab);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.logoutButton));
      await tester.pumpAndSettle();

      expect(authRepository.logoutAttempts, 1);
      expect(find.text(AppStrings.logoutError), findsOneWidget);
      expect(find.text(AppStrings.settingsTitle), findsWidgets);
    });
  });

  group('dashboard and settings', () {
    testWidgets('dashboard shows selected domain context and quick actions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
                selectedDomainStore: FakeSelectedDomainStore(),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(AppStrings.dashboardTitle), findsWidgets);
      expect(find.text('example.com'), findsWidgets);
      expect(find.text(AppStrings.dashboardQuickActionsTitle), findsOneWidget);
      expect(find.text(AppStrings.aliasesTab), findsWidgets);
      expect(find.text(AppStrings.catchAllTab), findsWidgets);
      expect(find.text(AppStrings.activityTab), findsWidgets);
    });

    testWidgets('settings shows active domain and change-domain action', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
                selectedDomainStore: FakeSelectedDomainStore(),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
        ),
      );

      await tester.pumpAndSettle();
      await tapNavTab(tester, AppStrings.settingsTab);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.settingsTitle), findsWidgets);
      expect(find.text(AppStrings.settingsDomainSectionTitle), findsOneWidget);
      expect(find.text(AppStrings.settingsChangeDomainButton), findsOneWidget);
      expect(find.text('example.com'), findsWidgets);
    });
  });

  group('catch-all flow', () {
    testWidgets('shows select-domain state when no domain is active', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
        ),
      );

      await tester.pumpAndSettle();
      await tapNavTab(tester, AppStrings.catchAllTab);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.catchAllNoDomainSelected), findsOneWidget);
    });

    testWidgets('shows empty state when no detected addresses exist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          catchAllRepository: FakeCatchAllRepository(entriesByZone: const {}),
        ),
      );

      await tester.pumpAndSettle();
      await tapNavTab(tester, AppStrings.catchAllTab);
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.catchAllEmptyState('example.com')),
        findsOneWidget,
      );
    });

    testWidgets('shows detected addresses and supports ignore', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          catchAllRepository: FakeCatchAllRepository(
            entriesByZone: const {
              'zone-1': [
                CatchAllEntry(address: 'amazon@example.com'),
                CatchAllEntry(address: 'github@example.com'),
              ],
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tapNavTab(tester, AppStrings.catchAllTab);
      await tester.pumpAndSettle();

      expect(find.text('amazon@example.com'), findsOneWidget);
      expect(find.text('github@example.com'), findsOneWidget);

      await tester.tap(
        find
            .widgetWithText(OutlinedButton, AppStrings.catchAllIgnoreButton)
            .first,
      );
      await tester.pumpAndSettle();

      expect(find.text('amazon@example.com'), findsNothing);
      expect(find.text('github@example.com'), findsOneWidget);
    });

    testWidgets('create alias from catch-all prefills alias and submits', (
      WidgetTester tester,
    ) async {
      final aliasRepository = FakeAliasRepository();

      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: aliasRepository,
          catchAllRepository: FakeCatchAllRepository(
            entriesByZone: const {
              'zone-1': [CatchAllEntry(address: 'amazon@example.com')],
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tapNavTab(tester, AppStrings.catchAllTab);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, AppStrings.createAliasButton),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.createAliasTitle), findsWidgets);
      expect(
        find.widgetWithText(TextField, AppStrings.createAliasAliasLabel),
        findsOneWidget,
      );
      expect(find.text('amazon'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, AppStrings.createAliasDestinationLabel),
        'dest@example.net',
      );
      await tester.tap(find.text(AppStrings.createAliasSubmitButton));
      await tester.pumpAndSettle();

      expect(aliasRepository.createCalls, hasLength(1));
      expect(aliasRepository.createCalls.single.zoneId, 'zone-1');
      expect(
        aliasRepository.createCalls.single.aliasAddress,
        'amazon@example.com',
      );
      expect(
        aliasRepository.createCalls.single.destination,
        'dest@example.net',
      );
      expect(find.text(AppStrings.createAliasSuccess), findsOneWidget);
      expect(find.text('amazon@example.com'), findsNothing);
    });

    testWidgets('load auth failure redirects back to login', (
      WidgetTester tester,
    ) async {
      final authRepository = FakeAuthRepository(initialToken: _validToken);

      await tester.pumpWidget(
        buildTestApp(
          authRepository: authRepository,
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          catchAllRepository: FakeCatchAllRepository(
            authFailure: const AuthFailure.invalidToken(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tapNavTab(tester, AppStrings.catchAllTab);
      await tester.pumpAndSettle();

      expect(authRepository.logoutAttempts, 1);
      expect(find.text(AppStrings.loginTitle), findsOneWidget);
    });

    testWidgets('load network failure stays in shell and shows retry', (
      WidgetTester tester,
    ) async {
      final authRepository = FakeAuthRepository(initialToken: _validToken);

      await tester.pumpWidget(
        buildTestApp(
          authRepository: authRepository,
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          catchAllRepository: FakeCatchAllRepository(
            error: const AuthFailure.network(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tapNavTab(tester, AppStrings.catchAllTab);
      await tester.pumpAndSettle();

      expect(authRepository.logoutCalls, 0);
      expect(find.text(AppStrings.catchAllLoadError), findsOneWidget);
      expect(find.text(AppStrings.retryButton), findsOneWidget);
    });
  });

  group('activity flow', () {
    testWidgets('shows selected domain activity rows', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
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
        ),
      );

      await tester.pumpAndSettle();
      await tapNavTab(tester, AppStrings.activityTab);
      await tester.pumpAndSettle();

      expect(find.text('sales@example.com'), findsOneWidget);
      expect(
        find.text('forwarded · SPF pass · DKIM pass · DMARC none'),
        findsOneWidget,
      );
    });

    testWidgets('network failure does not logout and shows retry state', (
      WidgetTester tester,
    ) async {
      final authRepository = FakeAuthRepository(initialToken: _validToken);

      await tester.pumpWidget(
        buildTestApp(
          authRepository: authRepository,
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          analyticsRepository: FakeAnalyticsRepository(
            authFailure: const AuthFailure.network(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tapNavTab(tester, AppStrings.activityTab);
      await tester.pumpAndSettle();

      expect(authRepository.logoutCalls, 0);
      expect(find.text(AppStrings.activityLoadError), findsOneWidget);
      expect(find.text(AppStrings.retryButton), findsOneWidget);
    });
  });

  group('domain selector flow', () {
    testWidgets('shows selected domain in shell after loading domains', (
      WidgetTester tester,
    ) async {
      final domainContext = DomainContext(
        repository: FakeDomainRepository(
          domains: const [
            DomainSummary(id: '1', name: 'example.com'),
            DomainSummary(id: '2', name: 'startup.io'),
          ],
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext: domainContext,
        ),
      );
      await tester.pumpAndSettle();

      await tapDomainSelectorButton(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('startup.io'));
      await tester.pumpAndSettle();

      expect(find.text('startup.io'), findsWidgets);
    });

    testWidgets('shows retry UI when domain loading fails', (
      WidgetTester tester,
    ) async {
      final domainContext = DomainContext(
        repository: FakeDomainRepository(error: Exception('network down')),
      );

      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext: domainContext,
        ),
      );
      await tester.pumpAndSettle();

      await tapDomainSelectorButton(tester);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.domainLoadError), findsOneWidget);
      expect(find.text(AppStrings.retryButton), findsOneWidget);
    });

    testWidgets('shows empty state when no domains are returned', (
      WidgetTester tester,
    ) async {
      final domainContext = DomainContext(
        repository: FakeDomainRepository(domains: const []),
      );

      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext: domainContext,
        ),
      );
      await tester.pumpAndSettle();

      await tapDomainSelectorButton(tester);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.domainEmptyState), findsOneWidget);
    });

    testWidgets('returns to login when domain load detects invalid session', (
      WidgetTester tester,
    ) async {
      final authRepository = FakeAuthRepository(initialToken: _validToken);
      final domainContext = DomainContext(
        repository: FakeDomainRepository(
          authFailure: const AuthFailure.invalidToken(),
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          authRepository: authRepository,
          domainContext: domainContext,
        ),
      );
      await tester.pumpAndSettle();

      expect(authRepository.logoutAttempts, 1);
      expect(find.text(AppStrings.loginTitle), findsOneWidget);
    });

    testWidgets(
      'still returns to login when domain auth failure logout cleanup fails',
      (WidgetTester tester) async {
        final authRepository = FakeAuthRepository(
          initialToken: _validToken,
          logoutFailure: Exception('secure storage delete failed'),
        );
        final domainContext = DomainContext(
          repository: FakeDomainRepository(
            authFailure: const AuthFailure.invalidToken(),
          ),
        );

        await tester.pumpWidget(
          buildTestApp(
            authRepository: authRepository,
            domainContext: domainContext,
          ),
        );
        await tester.pumpAndSettle();

        expect(authRepository.logoutAttempts, 1);
        expect(find.text(AppStrings.authSessionCleanupError), findsOneWidget);
        expect(find.text(AppStrings.loginTitle), findsNothing);
        expect(find.text(AppStrings.retryButton), findsOneWidget);
      },
    );

    testWidgets(
      'startup returns to login on insufficient permissions and logs out',
      (WidgetTester tester) async {
        final authRepository = FakeAuthRepository(initialToken: _validToken);
        final domainContext = DomainContext(
          repository: FakeDomainRepository(
            authFailure: const AuthFailure.insufficientPermissions(),
          ),
        );

        await tester.pumpWidget(
          buildTestApp(
            authRepository: authRepository,
            domainContext: domainContext,
          ),
        );
        await tester.pumpAndSettle();

        expect(authRepository.logoutAttempts, 1);
        expect(find.text(AppStrings.loginTitle), findsOneWidget);
        expect(domainContext.selectedDomain, isNull);
        expect(domainContext.domains, isEmpty);
      },
    );

    testWidgets('recovers after transient startup domain load failure', (
      WidgetTester tester,
    ) async {
      final domainContext = DomainContext(
        repository: FlakyDomainRepository(
          domains: const [DomainSummary(id: '1', name: 'example.com')],
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext: domainContext,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.dashboardNoDomainTitle), findsOneWidget);

      await tapDomainSelectorButton(tester);
      await tester.pumpAndSettle();

      expect(find.text('example.com'), findsWidgets);
      expect(find.text(AppStrings.domainLoadError), findsNothing);
    });
  });

  group('alias list flow', () {
    testWidgets('shows aliases for the selected domain', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: FakeAliasRepository(
            aliases: const [
              AliasModel(
                id: 'rule-1',
                address: 'hello@example.com',
                destination: 'dest@example.net',
                isEnabled: true,
                isSupported: true,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();

      expect(find.text('hello@example.com'), findsOneWidget);
      expect(find.text('dest@example.net'), findsOneWidget);
      expect(find.text(AppStrings.aliasStatusEnabled), findsOneWidget);
    });

    testWidgets('shows empty state when selected domain has no aliases', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: FakeAliasRepository(),
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.aliasEmptyState('example.com')),
        findsOneWidget,
      );
    });

    testWidgets('shows retryable alias load error and recovers on retry', (
      WidgetTester tester,
    ) async {
      final aliasRepository = FlakyAliasRepository(
        aliases: const [
          AliasModel(
            id: 'rule-1',
            address: 'hello@example.com',
            destination: 'dest@example.net',
            isEnabled: true,
            isSupported: true,
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: aliasRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.aliasLoadError), findsOneWidget);
      await tester.tap(find.text(AppStrings.retryButton));
      await tester.pumpAndSettle();

      expect(find.text('hello@example.com'), findsOneWidget);
      expect(find.text(AppStrings.aliasLoadError), findsNothing);
    });

    testWidgets('returns to login when alias load detects invalid session', (
      WidgetTester tester,
    ) async {
      final authRepository = FakeAuthRepository(initialToken: _validToken);

      await tester.pumpWidget(
        buildTestApp(
          authRepository: authRepository,
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: FakeAliasRepository(
            authFailure: const AuthFailure.invalidToken(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();

      expect(authRepository.logoutAttempts, 1);
      expect(find.text(AppStrings.loginTitle), findsOneWidget);
    });

    testWidgets(
      'returns to login when alias load detects insufficient permissions',
      (WidgetTester tester) async {
        final authRepository = FakeAuthRepository(initialToken: _validToken);

        await tester.pumpWidget(
          buildTestApp(
            authRepository: authRepository,
            domainContext:
                DomainContext(
                  repository: FakeDomainRepository(
                    domains: const [
                      DomainSummary(id: 'zone-1', name: 'example.com'),
                    ],
                  ),
                )..selectDomain(
                  const DomainSummary(id: 'zone-1', name: 'example.com'),
                ),
            aliasRepository: FakeAliasRepository(
              authFailure: const AuthFailure.insufficientPermissions(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tapNavTab(tester, AppStrings.aliasesTab);
        await tester.pumpAndSettle();

        expect(authRepository.logoutAttempts, 1);
        expect(find.text(AppStrings.loginTitle), findsOneWidget);
      },
    );

    testWidgets('keeps alias data aligned when selected domain changes', (
      WidgetTester tester,
    ) async {
      final domainContext = DomainContext(
        repository: FakeDomainRepository(
          domains: const [
            DomainSummary(id: 'zone-1', name: 'example.com'),
            DomainSummary(id: 'zone-2', name: 'startup.io'),
          ],
        ),
      )..selectDomain(const DomainSummary(id: 'zone-1', name: 'example.com'));
      final aliasRepository = DelayedSwitchingAliasRepository(
        responses: {
          'zone-1': const [
            AliasModel(
              id: 'rule-a',
              address: 'one@example.com',
              destination: 'a@example.net',
              isEnabled: true,
              isSupported: true,
            ),
          ],
          'zone-2': const [
            AliasModel(
              id: 'rule-b',
              address: 'two@startup.io',
              destination: 'b@example.net',
              isEnabled: true,
              isSupported: true,
            ),
          ],
        },
      );

      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext: domainContext,
          aliasRepository: aliasRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pump();

      domainContext.selectDomain(
        const DomainSummary(id: 'zone-2', name: 'startup.io'),
      );
      aliasRepository.complete('zone-1');
      await tester.pump();
      aliasRepository.complete('zone-2');
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.aliasListTitle('startup.io')),
        findsOneWidget,
      );
      expect(find.text('two@startup.io'), findsOneWidget);
      expect(find.text('one@example.com'), findsNothing);
    });

    testWidgets('opens create alias sheet from empty state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: FakeAliasRepository(),
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.createAliasButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.createAliasTitle), findsWidgets);
      expect(find.text('example.com'), findsWidgets);
      expect(find.text(AppStrings.createAliasSubmitButton), findsOneWidget);
    });

    testWidgets('shows local validation errors in create alias sheet', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: FakeAliasRepository(),
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.createAliasButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.createAliasSubmitButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.createAliasAliasRequired), findsOneWidget);
      expect(
        find.text(AppStrings.createAliasDestinationRequired),
        findsOneWidget,
      );
      expect(find.text(AppStrings.createAliasTitle), findsWidgets);
    });

    testWidgets('successful create refreshes aliases and shows snackbar', (
      WidgetTester tester,
    ) async {
      final aliasRepository = FakeAliasRepository();

      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: aliasRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.createAliasButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'sales');
      await tester.enterText(find.byType(TextField).at(1), 'dest@example.net');
      await tester.tap(find.text(AppStrings.createAliasSubmitButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.createAliasSuccess), findsOneWidget);
      expect(find.text('sales@example.com'), findsOneWidget);
      expect(find.text('dest@example.net'), findsOneWidget);
      expect(aliasRepository.createCalls, hasLength(1));
    });

    testWidgets('create alias API error keeps sheet open and shows error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: FakeAliasRepository(
            createError: const ApiException('Alias already exists.'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.createAliasButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'sales');
      await tester.enterText(find.byType(TextField).at(1), 'dest@example.net');
      await tester.tap(find.text(AppStrings.createAliasSubmitButton));
      await tester.pumpAndSettle();

      expect(find.text('Alias already exists.'), findsOneWidget);
      expect(find.text(AppStrings.createAliasTitle), findsWidgets);
    });

    testWidgets('create alias auth failure redirects back to login', (
      WidgetTester tester,
    ) async {
      final authRepository = FakeAuthRepository(initialToken: _validToken);

      await tester.pumpWidget(
        buildTestApp(
          authRepository: authRepository,
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: FakeAliasRepository(
            createAuthFailure: const AuthFailure.invalidToken(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.createAliasButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'sales');
      await tester.enterText(find.byType(TextField).at(1), 'dest@example.net');
      await tester.tap(find.text(AppStrings.createAliasSubmitButton));
      await tester.pumpAndSettle();

      expect(authRepository.logoutAttempts, 1);
      expect(find.text(AppStrings.loginTitle), findsOneWidget);
    });

    testWidgets('create alias network failure keeps session and sheet open', (
      WidgetTester tester,
    ) async {
      final authRepository = FakeAuthRepository(initialToken: _validToken);

      await tester.pumpWidget(
        buildTestApp(
          authRepository: authRepository,
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: FakeAliasRepository(
            createAuthFailure: const AuthFailure.network(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.createAliasButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'sales');
      await tester.enterText(find.byType(TextField).at(1), 'dest@example.net');
      await tester.tap(find.text(AppStrings.createAliasSubmitButton));
      await tester.pumpAndSettle();

      expect(authRepository.logoutAttempts, 0);
      expect(find.text(AppStrings.loginTitle), findsNothing);
      expect(find.text(AppStrings.createAliasTitle), findsWidgets);
    });

    testWidgets('opens edit alias sheet for supported alias', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: FakeAliasRepository(
            aliases: const [
              AliasModel(
                id: 'rule-1',
                address: 'sales@example.com',
                destination: 'dest@example.net',
                isEnabled: true,
                isSupported: true,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(AppStrings.editAliasTitle));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.editAliasTitle), findsWidgets);
      expect(find.text('sales@example.com'), findsWidgets);
      expect(find.text(AppStrings.editAliasSubmitButton), findsOneWidget);
    });

    testWidgets('successful edit refreshes aliases and shows snackbar', (
      WidgetTester tester,
    ) async {
      final aliasRepository = FakeAliasRepository(
        aliases: const [
          AliasModel(
            id: 'rule-1',
            address: 'sales@example.com',
            destination: 'dest@example.net',
            isEnabled: true,
            isSupported: true,
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: aliasRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(AppStrings.editAliasTitle));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).at(1),
        'edited@example.net',
      );
      await tester.tap(find.text(AppStrings.editAliasSubmitButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.editAliasSuccess), findsOneWidget);
      expect(find.text('edited@example.net'), findsOneWidget);
      expect(aliasRepository.updateCalls, hasLength(1));
    });

    testWidgets('edit alias auth failure redirects back to login', (
      WidgetTester tester,
    ) async {
      final authRepository = FakeAuthRepository(initialToken: _validToken);

      await tester.pumpWidget(
        buildTestApp(
          authRepository: authRepository,
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: FakeAliasRepository(
            aliases: const [
              AliasModel(
                id: 'rule-1',
                address: 'sales@example.com',
                destination: 'dest@example.net',
                isEnabled: true,
                isSupported: true,
              ),
            ],
            updateAuthFailure: const AuthFailure.invalidToken(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(AppStrings.editAliasTitle));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).at(1),
        'edited@example.net',
      );
      await tester.tap(find.text(AppStrings.editAliasSubmitButton));
      await tester.pumpAndSettle();

      expect(authRepository.logoutAttempts, 1);
      expect(find.text(AppStrings.loginTitle), findsOneWidget);
    });

    testWidgets('edit alias validation keeps sheet open on empty destination', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: FakeAliasRepository(
            aliases: const [
              AliasModel(
                id: 'rule-1',
                address: 'sales@example.com',
                destination: 'dest@example.net',
                isEnabled: true,
                isSupported: true,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(AppStrings.editAliasTitle));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(1), ' ');
      await tester.tap(find.text(AppStrings.editAliasSubmitButton));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.createAliasDestinationRequired),
        findsOneWidget,
      );
      expect(find.text(AppStrings.editAliasTitle), findsWidgets);
    });

    testWidgets('edit alias API error keeps sheet open and shows error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: FakeAliasRepository(
            aliases: const [
              AliasModel(
                id: 'rule-1',
                address: 'sales@example.com',
                destination: 'dest@example.net',
                isEnabled: true,
                isSupported: true,
              ),
            ],
            updateError: const ApiException('Destination already used.'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(AppStrings.editAliasTitle));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).at(1),
        'edited@example.net',
      );
      await tester.tap(find.text(AppStrings.editAliasSubmitButton));
      await tester.pumpAndSettle();

      expect(find.text('Destination already used.'), findsOneWidget);
      expect(find.text(AppStrings.editAliasTitle), findsWidgets);
    });

    testWidgets('unsupported alias hides edit, toggle, and delete actions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: FakeAliasRepository(
            aliases: const [
              AliasModel(
                id: 'rule-unsupported',
                address: 'Unsupported routing rule',
                destination: 'Unsupported destination',
                isEnabled: true,
                isSupported: false,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();

      expect(find.byTooltip(AppStrings.editAliasTitle), findsNothing);
      expect(find.byTooltip(AppStrings.deleteAliasTooltip), findsNothing);
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('successful delete refreshes aliases and shows snackbar', (
      WidgetTester tester,
    ) async {
      final aliasRepository = FakeAliasRepository(
        aliases: const [
          AliasModel(
            id: 'rule-1',
            address: 'sales@example.com',
            destination: 'dest@example.net',
            isEnabled: true,
            isSupported: true,
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: aliasRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(AppStrings.deleteAliasTooltip));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.deleteAliasConfirmButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.deleteAliasSuccess), findsOneWidget);
      expect(find.text('sales@example.com'), findsNothing);
      expect(aliasRepository.deleteCalls, hasLength(1));
    });

    testWidgets('delete alias auth failure redirects back to login', (
      WidgetTester tester,
    ) async {
      final authRepository = FakeAuthRepository(initialToken: _validToken);

      await tester.pumpWidget(
        buildTestApp(
          authRepository: authRepository,
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: FakeAliasRepository(
            aliases: const [
              AliasModel(
                id: 'rule-1',
                address: 'sales@example.com',
                destination: 'dest@example.net',
                isEnabled: true,
                isSupported: true,
              ),
            ],
            deleteAuthFailure: const AuthFailure.invalidToken(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(AppStrings.deleteAliasTooltip));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.deleteAliasConfirmButton));
      await tester.pumpAndSettle();

      expect(authRepository.logoutAttempts, 1);
      expect(find.text(AppStrings.loginTitle), findsOneWidget);
    });

    testWidgets('delete alias API error keeps session and shows snackbar', (
      WidgetTester tester,
    ) async {
      final authRepository = FakeAuthRepository(initialToken: _validToken);

      await tester.pumpWidget(
        buildTestApp(
          authRepository: authRepository,
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: FakeAliasRepository(
            aliases: const [
              AliasModel(
                id: 'rule-1',
                address: 'sales@example.com',
                destination: 'dest@example.net',
                isEnabled: true,
                isSupported: true,
              ),
            ],
            deleteError: const ApiException('Alias could not be deleted.'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(AppStrings.deleteAliasTooltip));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.deleteAliasConfirmButton));
      await tester.pumpAndSettle();

      expect(authRepository.logoutAttempts, 0);
      expect(find.text(AppStrings.loginTitle), findsNothing);
      expect(find.text(AppStrings.deleteAliasGenericError), findsOneWidget);
      expect(find.text('sales@example.com'), findsOneWidget);
    });

    testWidgets('successful disable refreshes aliases and shows snackbar', (
      WidgetTester tester,
    ) async {
      final aliasRepository = FakeAliasRepository(
        aliases: const [
          AliasModel(
            id: 'rule-1',
            address: 'sales@example.com',
            destination: 'dest@example.net',
            isEnabled: true,
            isSupported: true,
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: aliasRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.toggleAliasDisableSuccess), findsOneWidget);
      expect(find.text(AppStrings.aliasStatusDisabled), findsOneWidget);
      expect(aliasRepository.updateCalls, hasLength(1));
      expect(aliasRepository.updateCalls.single.isEnabled, isFalse);
    });

    testWidgets('successful enable refreshes aliases and shows snackbar', (
      WidgetTester tester,
    ) async {
      final aliasRepository = FakeAliasRepository(
        aliases: const [
          AliasModel(
            id: 'rule-1',
            address: 'sales@example.com',
            destination: 'dest@example.net',
            isEnabled: false,
            isSupported: true,
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: aliasRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.toggleAliasEnableSuccess), findsOneWidget);
      expect(find.text(AppStrings.aliasStatusEnabled), findsOneWidget);
      expect(aliasRepository.updateCalls, hasLength(1));
      expect(aliasRepository.updateCalls.single.isEnabled, isTrue);
    });

    testWidgets('toggle alias auth failure redirects back to login', (
      WidgetTester tester,
    ) async {
      final authRepository = FakeAuthRepository(initialToken: _validToken);

      await tester.pumpWidget(
        buildTestApp(
          authRepository: authRepository,
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: FakeAliasRepository(
            aliases: const [
              AliasModel(
                id: 'rule-1',
                address: 'sales@example.com',
                destination: 'dest@example.net',
                isEnabled: true,
                isSupported: true,
              ),
            ],
            updateAuthFailure: const AuthFailure.insufficientPermissions(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(authRepository.logoutAttempts, 1);
      expect(find.text(AppStrings.loginTitle), findsOneWidget);
    });

    testWidgets('toggle alias API error keeps session and shows snackbar', (
      WidgetTester tester,
    ) async {
      final authRepository = FakeAuthRepository(initialToken: _validToken);

      await tester.pumpWidget(
        buildTestApp(
          authRepository: authRepository,
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: FakeAliasRepository(
            aliases: const [
              AliasModel(
                id: 'rule-1',
                address: 'sales@example.com',
                destination: 'dest@example.net',
                isEnabled: true,
                isSupported: true,
              ),
            ],
            updateError: const ApiException('Destination already used.'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(authRepository.logoutAttempts, 0);
      expect(find.text(AppStrings.loginTitle), findsNothing);
      expect(find.text(AppStrings.toggleAliasGenericError), findsOneWidget);
      expect(find.text(AppStrings.aliasStatusEnabled), findsOneWidget);
    });

    testWidgets('opens alias generator page from empty state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: FakeAliasRepository(),
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.aliasGeneratorButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.aliasGeneratorTitle), findsOneWidget);
      expect(find.text('example.com'), findsOneWidget);
    });

    testWidgets('successful generated alias create refreshes aliases', (
      WidgetTester tester,
    ) async {
      final aliasRepository = FakeAliasRepository();

      await tester.pumpWidget(
        buildTestApp(
          authRepository: FakeAuthRepository(initialToken: _validToken),
          domainContext:
              DomainContext(
                repository: FakeDomainRepository(
                  domains: const [
                    DomainSummary(id: 'zone-1', name: 'example.com'),
                  ],
                ),
              )..selectDomain(
                const DomainSummary(id: 'zone-1', name: 'example.com'),
              ),
          aliasRepository: aliasRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tapNavTab(tester, AppStrings.aliasesTab);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.aliasGeneratorButton));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, AppStrings.aliasGeneratorServiceLabel),
        'amazon',
      );
      await tester.enterText(
        find.widgetWithText(TextField, AppStrings.createAliasDestinationLabel),
        'dest@example.net',
      );
      await tester.tap(find.text(AppStrings.aliasGeneratorRegenerateButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.aliasGeneratorCreateButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.createAliasSuccess), findsOneWidget);
      expect(find.textContaining('amazon-'), findsWidgets);
      expect(find.text('dest@example.net'), findsOneWidget);
      expect(aliasRepository.createCalls, hasLength(1));
    });
  });
}

BariskodeCfEmailApp buildTestApp({
  required FakeAuthRepository authRepository,
  DomainContext? domainContext,
  AliasRepositoryContract? aliasRepository,
  CatchAllRepositoryContract? catchAllRepository,
  AnalyticsRepositoryContract? analyticsRepository,
}) {
  return BariskodeCfEmailApp(
    authRepository: authRepository,
    domainContext:
        domainContext ??
        DomainContext(
          repository: FakeDomainRepository(),
          selectedDomainStore: FakeSelectedDomainStore(),
        ),
    aliasRepository: aliasRepository ?? FakeAliasRepository(),
    catchAllRepository: catchAllRepository ?? const FakeCatchAllRepository(),
    analyticsRepository: analyticsRepository ?? FakeAnalyticsRepository(),
  );
}

const _validToken = 'abcdefghijklmnopqrstuvwxyz123456';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.initialToken,
    this.loginFailure,
    this.hasValidSessionResult,
    this.logoutFailure,
    this.startupFailure,
  });

  final String? initialToken;
  final AuthFailure? loginFailure;
  final bool? hasValidSessionResult;
  final Exception? logoutFailure;
  AuthFailure? startupFailure;
  final List<String> savedTokens = <String>[];
  int logoutCalls = 0;
  int logoutAttempts = 0;
  String? _token;

  @override
  Future<bool> hasValidSession() async {
    if (startupFailure != null) {
      throw startupFailure!;
    }

    if (hasValidSessionResult != null) {
      return hasValidSessionResult!;
    }

    _token ??= initialToken;
    return _token != null && _token!.isNotEmpty;
  }

  @override
  Future<void> loginWithToken(String token) async {
    if (loginFailure != null) {
      throw loginFailure!;
    }

    _token = token;
    savedTokens.add(token);
  }

  @override
  Future<void> logout() async {
    logoutAttempts += 1;

    if (logoutFailure != null) {
      throw logoutFailure!;
    }

    logoutCalls += 1;
    _token = null;
  }

  @override
  Future<String?> readToken() async => _token ?? initialToken;
}

class FakeDomainRepository implements DomainRepositoryContract {
  FakeDomainRepository({this.domains = const [], this.error, this.authFailure});

  final List<DomainSummary> domains;
  final Exception? error;
  final AuthFailure? authFailure;

  @override
  Future<List<DomainSummary>> listDomains() async {
    if (authFailure != null) {
      throw authFailure!;
    }

    if (error != null) {
      throw error!;
    }

    return domains;
  }
}

class FakeSelectedDomainStore implements SelectedDomainStoreContract {
  FakeSelectedDomainStore({this.initialDomainId});

  final String? initialDomainId;
  int clearCalls = 0;
  String? currentDomainId;
  final List<String> savedDomainIds = <String>[];

  @override
  Future<void> clearSelectedDomainId() async {
    clearCalls += 1;
    currentDomainId = null;
  }

  @override
  Future<String?> readSelectedDomainId() async =>
      currentDomainId ?? initialDomainId;

  @override
  Future<void> saveSelectedDomainId(String domainId) async {
    currentDomainId = domainId;
    savedDomainIds.add(domainId);
  }
}

Future<void> tapNavTab(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(NavigationDestination, label));
}

Future<void> tapDomainSelectorButton(WidgetTester tester) async {
  await tester.tap(find.byType(TextButton).first);
}

class FlakyDomainRepository implements DomainRepositoryContract {
  FlakyDomainRepository({required this.domains});

  final List<DomainSummary> domains;
  int callCount = 0;

  @override
  Future<List<DomainSummary>> listDomains() async {
    callCount += 1;

    if (callCount == 1) {
      throw Exception('temporary outage');
    }

    return domains;
  }
}

class FakeCatchAllRepository implements CatchAllRepositoryContract {
  const FakeCatchAllRepository({
    this.entriesByZone = const {},
    this.error,
    this.authFailure,
  });

  final Map<String, List<CatchAllEntry>> entriesByZone;
  final Exception? error;
  final AuthFailure? authFailure;

  @override
  Future<List<CatchAllEntry>> listDetectedAddresses({
    required String zoneId,
    required String domainName,
  }) async {
    if (authFailure != null) {
      throw authFailure!;
    }

    if (error != null) {
      throw error!;
    }

    return List<CatchAllEntry>.unmodifiable(entriesByZone[zoneId] ?? const []);
  }
}

class FakeAnalyticsRepository implements AnalyticsRepositoryContract {
  FakeAnalyticsRepository({this.logs = const [], this.authFailure, this.error});

  final List<ActivityLogEntry> logs;
  final AuthFailure? authFailure;
  final Exception? error;
  final List<int> requestedLimits = <int>[];

  @override
  Future<List<ActivityLogEntry>> listActivityLogs({
    required String zoneId,
    int limit = 20,
  }) async {
    requestedLimits.add(limit);

    if (authFailure != null) {
      throw authFailure!;
    }

    if (error != null) {
      throw error!;
    }

    return List<ActivityLogEntry>.unmodifiable(logs.take(limit));
  }
}

class FakeAliasRepository implements AliasRepositoryContract {
  FakeAliasRepository({
    List<AliasModel> aliases = const [],
    this.error,
    this.authFailure,
    this.createError,
    this.createAuthFailure,
    this.updateError,
    this.updateAuthFailure,
    this.deleteError,
    this.deleteAuthFailure,
  }) : _aliases = List<AliasModel>.of(aliases);

  final List<AliasModel> _aliases;
  final Exception? error;
  final AuthFailure? authFailure;
  final Exception? createError;
  final AuthFailure? createAuthFailure;
  final Exception? updateError;
  final AuthFailure? updateAuthFailure;
  final Exception? deleteError;
  final AuthFailure? deleteAuthFailure;
  final List<CreateAliasCall> createCalls = <CreateAliasCall>[];
  final List<UpdateAliasCall> updateCalls = <UpdateAliasCall>[];
  final List<DeleteAliasCall> deleteCalls = <DeleteAliasCall>[];

  @override
  Future<List<AliasModel>> listAliases({required String zoneId}) async {
    if (authFailure != null) {
      throw authFailure!;
    }

    if (error != null) {
      throw error!;
    }

    return List<AliasModel>.unmodifiable(_aliases);
  }

  @override
  Future<AliasModel> createAlias({
    required String zoneId,
    required String aliasAddress,
    required String destination,
  }) async {
    if (createAuthFailure != null) {
      throw createAuthFailure!;
    }

    if (createError != null) {
      throw createError!;
    }

    createCalls.add(
      CreateAliasCall(
        zoneId: zoneId,
        aliasAddress: aliasAddress,
        destination: destination,
      ),
    );

    final alias = AliasModel(
      id: 'created-${createCalls.length}',
      address: aliasAddress,
      destination: destination,
      isEnabled: true,
      isSupported: true,
    );
    _aliases.add(alias);
    return alias;
  }

  @override
  Future<AliasModel> updateAlias({
    required String zoneId,
    required String ruleId,
    required String aliasAddress,
    required String destination,
    required bool isEnabled,
  }) async {
    if (updateAuthFailure != null) {
      throw updateAuthFailure!;
    }

    if (updateError != null) {
      throw updateError!;
    }

    updateCalls.add(
      UpdateAliasCall(
        zoneId: zoneId,
        ruleId: ruleId,
        aliasAddress: aliasAddress,
        destination: destination,
        isEnabled: isEnabled,
      ),
    );

    final index = _aliases.indexWhere((alias) => alias.id == ruleId);
    final updatedAlias = AliasModel(
      id: ruleId,
      address: aliasAddress,
      destination: destination,
      isEnabled: isEnabled,
      isSupported: true,
    );

    if (index >= 0) {
      _aliases[index] = updatedAlias;
    }

    return updatedAlias;
  }

  @override
  Future<void> deleteAlias({
    required String zoneId,
    required String ruleId,
  }) async {
    if (deleteAuthFailure != null) {
      throw deleteAuthFailure!;
    }

    if (deleteError != null) {
      throw deleteError!;
    }

    deleteCalls.add(DeleteAliasCall(zoneId: zoneId, ruleId: ruleId));
    _aliases.removeWhere((alias) => alias.id == ruleId);
  }
}

class FlakyAliasRepository implements AliasRepositoryContract {
  FlakyAliasRepository({required this.aliases});

  final List<AliasModel> aliases;
  int callCount = 0;

  @override
  Future<List<AliasModel>> listAliases({required String zoneId}) async {
    callCount += 1;

    if (callCount == 1) {
      throw const AuthFailure.network();
    }

    return aliases;
  }

  @override
  Future<AliasModel> createAlias({
    required String zoneId,
    required String aliasAddress,
    required String destination,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AliasModel> updateAlias({
    required String zoneId,
    required String ruleId,
    required String aliasAddress,
    required String destination,
    required bool isEnabled,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAlias({
    required String zoneId,
    required String ruleId,
  }) async {
    throw UnimplementedError();
  }
}

class DelayedSwitchingAliasRepository implements AliasRepositoryContract {
  DelayedSwitchingAliasRepository({required this.responses});

  final Map<String, List<AliasModel>> responses;
  final Map<String, Completer<List<AliasModel>>> _completers =
      <String, Completer<List<AliasModel>>>{};

  @override
  Future<List<AliasModel>> listAliases({required String zoneId}) {
    final completer = Completer<List<AliasModel>>();
    _completers[zoneId] = completer;
    return completer.future;
  }

  @override
  Future<AliasModel> createAlias({
    required String zoneId,
    required String aliasAddress,
    required String destination,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AliasModel> updateAlias({
    required String zoneId,
    required String ruleId,
    required String aliasAddress,
    required String destination,
    required bool isEnabled,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAlias({
    required String zoneId,
    required String ruleId,
  }) async {
    throw UnimplementedError();
  }

  void complete(String zoneId) {
    _completers[zoneId]?.complete(responses[zoneId] ?? const []);
  }
}

class CreateAliasCall {
  const CreateAliasCall({
    required this.zoneId,
    required this.aliasAddress,
    required this.destination,
  });

  final String zoneId;
  final String aliasAddress;
  final String destination;
}

class UpdateAliasCall {
  const UpdateAliasCall({
    required this.zoneId,
    required this.ruleId,
    required this.aliasAddress,
    required this.destination,
    required this.isEnabled,
  });

  final String zoneId;
  final String ruleId;
  final String aliasAddress;
  final String destination;
  final bool isEnabled;
}

class DeleteAliasCall {
  const DeleteAliasCall({required this.zoneId, required this.ruleId});

  final String zoneId;
  final String ruleId;
}
