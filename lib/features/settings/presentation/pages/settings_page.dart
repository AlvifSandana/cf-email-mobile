import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/features/domains/presentation/domain_context.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.domainContext,
    required this.onOpenDomainSelector,
    required this.onLogout,
  });

  final DomainContext domainContext;
  final VoidCallback onOpenDomainSelector;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: domainContext,
      builder: (context, _) {
        final selectedDomain = domainContext.selectedDomain;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              AppStrings.settingsTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.public),
                    title: const Text(AppStrings.settingsDomainSectionTitle),
                    subtitle: Text(
                      selectedDomain?.name ??
                          AppStrings.settingsNoDomainSelected,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.swap_horiz),
                    title: const Text(AppStrings.settingsChangeDomainButton),
                    subtitle: const Text(AppStrings.settingsChangeDomainHint),
                    onTap: onOpenDomainSelector,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.lock_outline),
                    title: Text(AppStrings.settingsSessionSectionTitle),
                    subtitle: Text(AppStrings.settingsSessionDescription),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text(AppStrings.logoutButton),
                    subtitle: const Text(AppStrings.settingsLogoutHint),
                    onTap: onLogout,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text(AppStrings.settingsAboutSectionTitle),
                    subtitle: Text(AppStrings.settingsAboutDescription),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
