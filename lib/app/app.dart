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
        AppRoutes.startup: (_) => AppStartup(authRepository: authRepository),
        AppRoutes.login: (_) => LoginPage(authRepository: authRepository),
        AppRoutes.shell: (_) => AppShell(
          authRepository: authRepository,
          domainContext: domainContext,
          aliasRepository: aliasRepository,
          catchAllRepository: catchAllRepository,
          analyticsRepository: analyticsRepository,
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
