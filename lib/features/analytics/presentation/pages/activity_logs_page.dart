import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/features/analytics/data/analytics_repository.dart';
import 'package:bariskode_cf_email/features/analytics/domain/entities/activity_log_entry.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/auth/domain/repositories/auth_repository.dart';
import 'package:bariskode_cf_email/features/domains/presentation/domain_context.dart';
import 'package:bariskode_cf_email/shared/utils/session_invalidator.dart';
import 'package:bariskode_cf_email/shared/widgets/state_views.dart';
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
  static const int _pageSize = 20;
  static const int _maxLimit = 100;

  List<ActivityLogEntry> _logs = const [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _activeZoneId;
  bool _reloadRequested = false;
  int _currentLimit = _pageSize;
  bool _hasMore = true;

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
        _isLoadingMore = false;
        _currentLimit = _pageSize;
        _hasMore = true;
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

    _currentLimit = _pageSize;
    _hasMore = true;
    await _loadLogs(zoneId: zoneId, limit: _currentLimit);
  }

  Future<void> _loadLogs({String? zoneId, int? limit}) async {
    final requestedZoneId = zoneId ?? widget.domainContext.selectedDomain?.id;
    if (requestedZoneId == null || _isLoading) {
      return;
    }

    final requestedLimit = (limit ?? _currentLimit).clamp(1, _maxLimit);

    _activeZoneId = requestedZoneId;

    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _errorMessage = null;
    });

    try {
      final logs = await widget.analyticsRepository.listActivityLogs(
        zoneId: requestedZoneId,
        limit: requestedLimit,
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
        _currentLimit = requestedLimit;
        _hasMore = logs.length >= requestedLimit && requestedLimit < _maxLimit;
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

  Future<void> _loadMoreLogs() async {
    final zoneId = widget.domainContext.selectedDomain?.id;
    if (zoneId == null || _isLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    final requestedLimit = (_currentLimit + _pageSize).clamp(1, _maxLimit);

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final logs = await widget.analyticsRepository.listActivityLogs(
        zoneId: zoneId,
        limit: requestedLimit,
      );

      if (!mounted) {
        return;
      }

      if (widget.domainContext.selectedDomain?.id != zoneId) {
        _reloadRequested = true;
        return;
      }

      setState(() {
        _logs = logs;
        _currentLimit = requestedLimit;
        _hasMore = logs.length >= requestedLimit && requestedLimit < _maxLimit;
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.activityLoadMoreError)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.activityLoadMoreError)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
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
          return const AppCenteredState(
            icon: Icons.public_off_outlined,
            message: AppStrings.activityNoDomainSelected,
          );
        }

        if (_isLoading && _logs.isEmpty) {
          return const AppLoadingState(label: AppStrings.activityLoadingLabel);
        }

        if (_errorMessage != null) {
          return AppCenteredState(
            icon: Icons.cloud_off_outlined,
            message: _errorMessage!,
            actions: [
              FilledButton(
                onPressed: _loadLogs,
                child: const Text(AppStrings.retryButton),
              ),
            ],
          );
        }

        if (_logs.isEmpty) {
          return AppCenteredState(
            icon: Icons.query_stats_outlined,
            message: AppStrings.activityEmptyState(selectedDomain.name),
            actions: [
              OutlinedButton.icon(
                onPressed: _loadLogs,
                icon: const Icon(Icons.refresh),
                label: const Text(AppStrings.activityRefreshButton),
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: () {
            _currentLimit = _pageSize;
            _hasMore = true;
            return _loadLogs(limit: _currentLimit);
          },
          child: ListView.builder(
            itemCount: _logs.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: Text(
                    AppStrings.activityListTitle(selectedDomain.name),
                  ),
                  subtitle: const Text(AppStrings.activityListSubtitle),
                  trailing: IconButton(
                    onPressed: () {
                      _currentLimit = _pageSize;
                      _hasMore = true;
                      _loadLogs(limit: _currentLimit);
                    },
                    icon: const Icon(Icons.refresh),
                    tooltip: AppStrings.activityRefreshButton,
                  ),
                );
              }

              if (index == _logs.length + 1) {
                if (_isLoadingMore) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text(AppStrings.activityLoadingMoreLabel),
                        ],
                      ),
                    ),
                  );
                }

                if (!_hasMore) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: OutlinedButton(
                    onPressed: _loadMoreLogs,
                    child: const Text(AppStrings.activityLoadMoreButton),
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
