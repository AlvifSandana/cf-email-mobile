import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/core/constants/app_routes.dart';
import 'package:bariskode_cf_email/features/auth/domain/repositories/auth_repository.dart';
import 'package:bariskode_cf_email/features/analytics/data/analytics_repository.dart';
import 'package:bariskode_cf_email/features/analytics/presentation/pages/activity_logs_page.dart';
import 'package:bariskode_cf_email/features/aliases/data/alias_repository.dart';
import 'package:bariskode_cf_email/features/aliases/presentation/pages/alias_list_page.dart';
import 'package:bariskode_cf_email/features/catchall/data/catchall_repository.dart';
import 'package:bariskode_cf_email/features/catchall/presentation/pages/catchall_page.dart';
import 'package:bariskode_cf_email/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:bariskode_cf_email/features/destinations/data/destination_repository.dart';
import 'package:bariskode_cf_email/features/domains/presentation/domain_context.dart';
import 'package:bariskode_cf_email/features/settings/presentation/pages/settings_page.dart';
import 'package:bariskode_cf_email/shared/utils/session_invalidator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.authRepository,
    required this.domainContext,
    required this.aliasRepository,
    required this.catchAllRepository,
    required this.analyticsRepository,
    required this.destinationRepository,
  });

  final AuthRepository authRepository;
  final DomainContext domainContext;
  final AliasRepositoryContract aliasRepository;
  final CatchAllRepositoryContract catchAllRepository;
  final AnalyticsRepositoryContract analyticsRepository;
  final DestinationRepositoryContract destinationRepository;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _tabs = <_AppTab>[
    _AppTab(label: AppStrings.dashboardTab, icon: Icons.dashboard_outlined),
    _AppTab(label: AppStrings.aliasesTab, icon: Icons.alternate_email_outlined),
    _AppTab(
      label: AppStrings.catchAllTab,
      icon: Icons.mark_email_unread_outlined,
    ),
    _AppTab(label: AppStrings.activityTab, icon: Icons.query_stats_outlined),
    _AppTab(label: AppStrings.settingsTab, icon: Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedTab = _tabs[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          TextButton.icon(
            onPressed: _openDomainSelector,
            icon: const Icon(Icons.public),
            label: AnimatedBuilder(
              animation: widget.domainContext,
              builder: (context, _) {
                return Text(
                  widget.domainContext.selectedDomain?.name ??
                      AppStrings.domainActionLabel,
                );
              },
            ),
          ),
        ],
        bottom: kDebugMode
            ? const PreferredSize(
                preferredSize: Size.fromHeight(32),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(AppStrings.planningBanner),
                ),
              )
            : null,
      ),
      body: _buildPage(selectedTab),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: _tabs
            .map(
              (tab) =>
                  NavigationDestination(icon: Icon(tab.icon), label: tab.label),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPage(_AppTab selectedTab) {
    if (selectedTab.label == AppStrings.settingsTab) {
      return SettingsPage(
        domainContext: widget.domainContext,
        onOpenDomainSelector: _openDomainSelector,
        onLogout: _handleLogout,
      );
    }

    if (selectedTab.label == AppStrings.dashboardTab) {
      return DashboardPage(
        domainContext: widget.domainContext,
        onOpenDomainSelector: _openDomainSelector,
        onOpenAliases: () => _selectTabByLabel(AppStrings.aliasesTab),
        onOpenCatchAll: () => _selectTabByLabel(AppStrings.catchAllTab),
        onOpenActivity: () => _selectTabByLabel(AppStrings.activityTab),
      );
    }

    if (selectedTab.label == AppStrings.aliasesTab) {
      return AliasListPage(
        authRepository: widget.authRepository,
        domainContext: widget.domainContext,
        aliasRepository: widget.aliasRepository,
        destinationRepository: widget.destinationRepository,
      );
    }

    if (selectedTab.label == AppStrings.catchAllTab) {
      return CatchAllPage(
        authRepository: widget.authRepository,
        domainContext: widget.domainContext,
        aliasRepository: widget.aliasRepository,
        destinationRepository: widget.destinationRepository,
        catchAllRepository: widget.catchAllRepository,
      );
    }

    if (selectedTab.label == AppStrings.activityTab) {
      return ActivityLogsPage(
        analyticsRepository: widget.analyticsRepository,
        authRepository: widget.authRepository,
        domainContext: widget.domainContext,
      );
    }

    return _PlaceholderPage(tabLabel: selectedTab.label);
  }

  Future<void> _handleLogout() async {
    await invalidateSessionAndReturnToLogin(
      context: context,
      authRepository: widget.authRepository,
      domainContext: widget.domainContext,
    );
  }

  Future<void> _openDomainSelector() async {
    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushNamed(AppRoutes.domainSelector);
  }

  void _selectTabByLabel(String tabLabel) {
    final index = _tabs.indexWhere((tab) => tab.label == tabLabel);
    if (index < 0) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.tabLabel});

  final String tabLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_rounded,
              size: 56,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.placeholderTitle(tabLabel),
              key: ValueKey('${tabLabel.toLowerCase()}-page-title'),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.placeholderDescription(tabLabel),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppTab {
  const _AppTab({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
