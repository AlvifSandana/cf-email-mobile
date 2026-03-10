import 'package:bariskode_cf_email/app/app_startup.dart';
import 'package:bariskode_cf_email/features/analytics/data/analytics_repository.dart';
import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/core/constants/app_routes.dart';
import 'package:bariskode_cf_email/features/auth/domain/repositories/auth_repository.dart';
import 'package:bariskode_cf_email/features/aliases/data/alias_repository.dart';
import 'package:bariskode_cf_email/features/catchall/data/catchall_repository.dart';
import 'package:bariskode_cf_email/features/auth/presentation/login_page.dart';
import 'package:bariskode_cf_email/features/domains/presentation/domain_context.dart';
import 'package:bariskode_cf_email/features/domains/presentation/domain_selector_page.dart';
import 'package:bariskode_cf_email/shared/utils/session_invalidator.dart';
import 'package:bariskode_cf_email/shared/utils/session_resolution.dart';
import 'package:bariskode_cf_email/shared/themes/app_theme.dart';
import 'package:bariskode_cf_email/shared/widgets/app_shell.dart';
import 'package:flutter/material.dart';

class BariskodeCfEmailApp extends StatelessWidget {
  const BariskodeCfEmailApp({
    super.key,
    required this.authRepository,
    required this.domainContext,
    required this.aliasRepository,
    required this.catchAllRepository,
    required this.analyticsRepository,
  });

  final AuthRepository authRepository;
  final DomainContext domainContext;
  final AliasRepositoryContract aliasRepository;
  final CatchAllRepositoryContract catchAllRepository;
  final AnalyticsRepositoryContract analyticsRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.light(),
      initialRoute: AppRoutes.startup,
      routes: {
        AppRoutes.startup: (_) => AppStartup(
          authRepository: authRepository,
          domainContext: domainContext,
        ),
        AppRoutes.login: (_) => LoginPage(authRepository: authRepository),
        AppRoutes.shell: (_) => ProtectedShellRoute(
          authRepository: authRepository,
          domainContext: domainContext,
          child: AppShell(
            authRepository: authRepository,
            domainContext: domainContext,
            aliasRepository: aliasRepository,
            catchAllRepository: catchAllRepository,
            analyticsRepository: analyticsRepository,
          ),
        ),
        AppRoutes.domainSelector: (_) => DomainSelectorPage(
          domainContext: domainContext,
          authRepository: authRepository,
        ),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class ProtectedShellRoute extends StatefulWidget {
  const ProtectedShellRoute({
    super.key,
    required this.authRepository,
    required this.domainContext,
    required this.child,
  });

  final AuthRepository authRepository;
  final DomainContext domainContext;
  final Widget child;

  @override
  State<ProtectedShellRoute> createState() => _ProtectedShellRouteState();
}

class _ProtectedShellRouteState extends State<ProtectedShellRoute> {
  late Future<_ProtectedShellDecision> _accessDecisionFuture;
  bool _redirectScheduled = false;

  @override
  void initState() {
    super.initState();
    _accessDecisionFuture = _resolveAccess();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProtectedShellDecision>(
      future: _accessDecisionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      AppStrings.authStartupError,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _redirectScheduled = false;
                          _accessDecisionFuture = _resolveAccess();
                        });
                      },
                      child: const Text(AppStrings.retryButton),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final decision = snapshot.data;

        if (decision?.hasValidSession == true) {
          return widget.child;
        }

        _scheduleRedirect(decision);

        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }

  Future<_ProtectedShellDecision> _resolveAccess() async {
    final resolution = await resolveSession(
      authRepository: widget.authRepository,
      domainContext: widget.domainContext,
    );

    return _ProtectedShellDecision(
      hasValidSession: resolution.hasValidSession,
      shouldInvalidateSession: resolution.shouldInvalidateSession,
      hadStoredToken: resolution.hadStoredToken,
    );
  }

  void _scheduleRedirect(_ProtectedShellDecision? decision) {
    if (_redirectScheduled) {
      return;
    }

    _redirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (decision?.shouldInvalidateSession == true) {
        invalidateSessionAndReturnToLogin(
          context: context,
          authRepository: widget.authRepository,
          domainContext: widget.domainContext,
        );
        return;
      }

      if (decision?.hadStoredToken == true) {
        widget.domainContext.clearSelection();
      }

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    });
  }
}

class _ProtectedShellDecision {
  const _ProtectedShellDecision({
    required this.hasValidSession,
    required this.hadStoredToken,
    required this.shouldInvalidateSession,
  });

  final bool hasValidSession;
  final bool hadStoredToken;
  final bool shouldInvalidateSession;
}
