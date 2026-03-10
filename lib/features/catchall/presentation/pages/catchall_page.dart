import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/features/aliases/data/alias_repository.dart';
import 'package:bariskode_cf_email/features/aliases/presentation/pages/alias_list_page.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/auth/domain/repositories/auth_repository.dart';
import 'package:bariskode_cf_email/features/destinations/data/destination_repository.dart';
import 'package:bariskode_cf_email/features/catchall/data/catchall_repository.dart';
import 'package:bariskode_cf_email/features/catchall/domain/entities/catchall_entry.dart';
import 'package:bariskode_cf_email/features/domains/domain/entities/domain_summary.dart';
import 'package:bariskode_cf_email/features/domains/presentation/domain_context.dart';
import 'package:bariskode_cf_email/shared/utils/session_invalidator.dart';
import 'package:bariskode_cf_email/shared/widgets/state_views.dart';
import 'package:flutter/material.dart';

class CatchAllPage extends StatefulWidget {
  const CatchAllPage({
    super.key,
    required this.authRepository,
    required this.domainContext,
    required this.aliasRepository,
    required this.destinationRepository,
    required this.catchAllRepository,
  });

  final AuthRepository authRepository;
  final DomainContext domainContext;
  final AliasRepositoryContract aliasRepository;
  final DestinationRepositoryContract destinationRepository;
  final CatchAllRepositoryContract catchAllRepository;

  @override
  State<CatchAllPage> createState() => _CatchAllPageState();
}

class _CatchAllPageState extends State<CatchAllPage> {
  List<CatchAllEntry> _entries = const [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _activeZoneId;
  bool _reloadRequested = false;
  final Set<String> _ignoredAddresses = <String>{};
  final Set<String> _blockedAddresses = <String>{};
  final Set<String> _mutatingAddresses = <String>{};

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
    final selectedDomain = widget.domainContext.selectedDomain;
    final zoneId = selectedDomain?.id;

    if (zoneId == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _activeZoneId = null;
        _entries = const [];
        _errorMessage = null;
        _isLoading = false;
        _ignoredAddresses.clear();
        _blockedAddresses.clear();
        _mutatingAddresses.clear();
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

    await _loadEntries(zoneId: zoneId, domainName: selectedDomain!.name);
  }

  Future<void> _loadEntries({String? zoneId, String? domainName}) async {
    final selectedDomain = widget.domainContext.selectedDomain;
    final requestedZoneId = zoneId ?? selectedDomain?.id;
    final requestedDomainName = domainName ?? selectedDomain?.name;

    if (requestedZoneId == null || requestedDomainName == null || _isLoading) {
      return;
    }

    _activeZoneId = requestedZoneId;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final entries = await widget.catchAllRepository.listDetectedAddresses(
        zoneId: requestedZoneId,
        domainName: requestedDomainName,
      );

      if (!mounted) {
        return;
      }

      if (widget.domainContext.selectedDomain?.id != requestedZoneId) {
        _reloadRequested = true;
        return;
      }

      setState(() {
        _entries = entries;
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
        _errorMessage = AppStrings.catchAllLoadError;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = AppStrings.catchAllLoadError;
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

  List<CatchAllEntry> get _visibleEntries => _entries
      .where(
        (entry) =>
            !_ignoredAddresses.contains(entry.address) &&
            !_blockedAddresses.contains(entry.address),
      )
      .toList(growable: false);

  void _ignoreEntry(CatchAllEntry entry) {
    setState(() {
      _ignoredAddresses.add(entry.address);
    });
  }

  Future<void> _blockEntry({
    required DomainSummary selectedDomain,
    required CatchAllEntry entry,
  }) async {
    setState(() {
      _mutatingAddresses.add(entry.address);
    });

    try {
      await widget.aliasRepository.createAlias(
        zoneId: selectedDomain.id,
        aliasAddress: entry.address,
        actionType: 'drop',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _blockedAddresses.add(entry.address);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.catchAllBlockSuccess)),
      );
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
        const SnackBar(content: Text(AppStrings.catchAllBlockError)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.catchAllBlockError)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _mutatingAddresses.remove(entry.address);
        });
      }
    }
  }

  Future<void> _openCreateAliasSheet({
    required DomainSummary selectedDomain,
    required CatchAllEntry entry,
  }) async {
    final aliasLocalPart = entry.address.split('@').first;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return CreateAliasSheet(
          domainName: selectedDomain.name,
          zoneId: selectedDomain.id,
          aliasRepository: widget.aliasRepository,
          destinationRepository: widget.destinationRepository,
          selectedDomain: selectedDomain,
          authRepository: widget.authRepository,
          domainContext: widget.domainContext,
          initialAliasLocalPart: aliasLocalPart,
        );
      },
    );

    if (result == true && mounted) {
      setState(() {
        _ignoredAddresses.add(entry.address);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.createAliasSuccess)),
      );
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
            message: AppStrings.catchAllNoDomainSelected,
          );
        }

        if (_isLoading) {
          return const AppLoadingState(label: AppStrings.catchAllLoadingLabel);
        }

        if (_errorMessage != null) {
          return AppCenteredState(
            icon: Icons.cloud_off_outlined,
            message: _errorMessage!,
            actions: [
              FilledButton(
                onPressed: _loadEntries,
                child: const Text(AppStrings.retryButton),
              ),
            ],
          );
        }

        final visibleEntries = _visibleEntries;
        if (visibleEntries.isEmpty) {
          return AppCenteredState(
            icon: Icons.mark_email_unread_outlined,
            message: AppStrings.catchAllEmptyState(selectedDomain.name),
            actions: [
              OutlinedButton.icon(
                onPressed: _loadEntries,
                icon: const Icon(Icons.refresh),
                label: const Text(AppStrings.catchAllRefreshButton),
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: _loadEntries,
          child: ListView.builder(
            itemCount: visibleEntries.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: Text(
                    AppStrings.catchAllListTitle(selectedDomain.name),
                  ),
                  subtitle: const Text(AppStrings.catchAllListSubtitle),
                  trailing: IconButton(
                    onPressed: _loadEntries,
                    icon: const Icon(Icons.refresh),
                    tooltip: AppStrings.catchAllRefreshButton,
                  ),
                );
              }

              final entry = visibleEntries[index - 1];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.address,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.lastSeenLabel ??
                            AppStrings.catchAllDetectedSubtitle,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonal(
                            onPressed: () => _openCreateAliasSheet(
                              selectedDomain: selectedDomain,
                              entry: entry,
                            ),
                            child: const Text(AppStrings.createAliasButton),
                          ),
                          OutlinedButton(
                            onPressed:
                                _mutatingAddresses.contains(entry.address)
                                ? null
                                : () => _ignoreEntry(entry),
                            child: const Text(AppStrings.catchAllIgnoreButton),
                          ),
                          OutlinedButton(
                            onPressed:
                                _mutatingAddresses.contains(entry.address)
                                ? null
                                : () => _blockEntry(
                                    selectedDomain: selectedDomain,
                                    entry: entry,
                                  ),
                            child: const Text(AppStrings.catchAllBlockButton),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
