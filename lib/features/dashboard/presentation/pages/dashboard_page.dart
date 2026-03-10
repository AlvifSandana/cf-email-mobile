import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/features/domains/presentation/domain_context.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.domainContext,
    required this.onOpenDomainSelector,
    required this.onOpenAliases,
    required this.onOpenCatchAll,
    required this.onOpenActivity,
  });

  final DomainContext domainContext;
  final VoidCallback onOpenDomainSelector;
  final VoidCallback onOpenAliases;
  final VoidCallback onOpenCatchAll;
  final VoidCallback onOpenActivity;

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
              AppStrings.dashboardTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              selectedDomain == null
                  ? AppStrings.dashboardNoDomainDescription
                  : AppStrings.dashboardReadyDescription(selectedDomain.name),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.dashboardActiveDomainLabel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedDomain?.name ?? AppStrings.dashboardNoDomainTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedDomain == null
                          ? AppStrings.dashboardNoDomainHint
                          : AppStrings.dashboardDomainHint,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: onOpenDomainSelector,
                      icon: const Icon(Icons.public),
                      label: Text(
                        selectedDomain == null
                            ? AppStrings.dashboardSelectDomainButton
                            : AppStrings.dashboardChangeDomainButton,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.dashboardQuickActionsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickActionButton(
                  icon: Icons.alternate_email_outlined,
                  label: AppStrings.aliasesTab,
                  onPressed: onOpenAliases,
                ),
                _QuickActionButton(
                  icon: Icons.mark_email_unread_outlined,
                  label: AppStrings.catchAllTab,
                  onPressed: onOpenCatchAll,
                ),
                _QuickActionButton(
                  icon: Icons.query_stats_outlined,
                  label: AppStrings.activityTab,
                  onPressed: onOpenActivity,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.dashboardSummaryTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(AppStrings.dashboardSummaryBody),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}
