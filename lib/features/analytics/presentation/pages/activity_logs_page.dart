import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/features/analytics/data/analytics_repository.dart';
import 'package:bariskode_cf_email/features/analytics/domain/entities/activity_log_entry.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/auth/domain/repositories/auth_repository.dart';
import 'package:bariskode_cf_email/features/domains/presentation/domain_context.dart';
import 'package:bariskode_cf_email/shared/utils/session_invalidator.dart';
import 'package:flutter/material.dart';

class ActivityLogsPage extends StatefulWidget {
  const ActivityLogsPage({
    super.key,
    required this.analyticsRepository,
    required this.authRepository,
    required this.domainContext,
  });

  final AnalyticsRepositoryContract analyticsRepository;
  final AuthRepository authRepository;
  final DomainContext domainContext;

  @override
  State<ActivityLogsPage> createState() => _ActivityLogsPageState();
}

class _ActivityLogsPageState extends State<ActivityLogsPage> {
  List<ActivityLogEntry> _logs = const [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _activeZoneId;
  bool _reloadRequested = false;

  @override
  void initState() {
    super.initState();
    widget.domainContext.addListener(_handleDomainChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleDomainChange(forceReload: true);
    });
  }

  @override
  void dispose() {
    widget.domainContext.removeListener(_handleDomainChange);
    super.dispose();
  }

  Future<void> _handleDomainChange({bool forceReload = false}) async {
    final zoneId = widget.domainContext.selectedDomain?.id;

    if (zoneId == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _activeZoneId = null;
        _logs = const [];
        _errorMessage = null;
        _isLoading = false;
      });
      return;
    }

    if (!forceReload && _activeZoneId == zoneId) {
      return;
    }

    if (_isLoading) {
      _activeZoneId = zoneId;
      _reloadRequested = true;
      return;
    }

    await _loadLogs(zoneId: zoneId);
  }

  Future<void> _loadLogs({String? zoneId}) async {
    final requestedZoneId = zoneId ?? widget.domainContext.selectedDomain?.id;
    if (requestedZoneId == null || _isLoading) {
      return;
    }

    _activeZoneId = requestedZoneId;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final logs = await widget.analyticsRepository.listActivityLogs(
        zoneId: requestedZoneId,
      );

      if (!mounted) {
        return;
      }

      if (widget.domainContext.selectedDomain?.id != requestedZoneId) {
        _reloadRequested = true;
        return;
      }

      setState(() {
        _logs = logs;
      });
    } on AuthFailure catch (failure) {
      if (!mounted) {
        return;
      }

      if (failure.type == AuthFailureType.invalidToken ||
          failure.type == AuthFailureType.insufficientPermissions) {
        await invalidateSessionAndReturnToLogin(
          context: context,
          authRepository: widget.authRepository,
          domainContext: widget.domainContext,
        );
        return;
      }

      setState(() {
        _errorMessage = AppStrings.activityLoadError;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = AppStrings.activityLoadError;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      final selectedZoneId = widget.domainContext.selectedDomain?.id;
      if (mounted &&
          selectedZoneId != null &&
          selectedZoneId != requestedZoneId) {
        _reloadRequested = true;
      }

      if (_reloadRequested && mounted) {
        _reloadRequested = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleDomainChange(forceReload: true);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.domainContext,
      builder: (context, _) {
        final selectedDomain = widget.domainContext.selectedDomain;

        if (selectedDomain == null) {
          return const Center(child: Text(AppStrings.activityNoDomainSelected));
        }

        if (_isLoading) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(AppStrings.activityLoadingLabel),
              ],
            ),
          );
        }

        if (_errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loadLogs,
                    child: const Text(AppStrings.retryButton),
                  ),
                ],
              ),
            ),
          );
        }

        if (_logs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.activityEmptyState(selectedDomain.name),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _loadLogs,
                    icon: const Icon(Icons.refresh),
                    label: const Text(AppStrings.activityRefreshButton),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadLogs,
          child: ListView.builder(
            itemCount: _logs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: Text(
                    AppStrings.activityListTitle(selectedDomain.name),
                  ),
                  subtitle: const Text(AppStrings.activityListSubtitle),
                  trailing: IconButton(
                    onPressed: _loadLogs,
                    icon: const Icon(Icons.refresh),
                    tooltip: AppStrings.activityRefreshButton,
                  ),
                );
              }

              final log = _logs[index - 1];
              return ListTile(
                title: Text(log.address),
                subtitle: Text(
                  '${log.status} · SPF ${log.spf} · DKIM ${log.dkim} · DMARC ${log.dmarc}',
                ),
                trailing: Text(log.timestamp.toIso8601String()),
              );
            },
          ),
        );
      },
    );
  }
}
