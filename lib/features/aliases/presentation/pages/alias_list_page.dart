import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/features/aliases/data/alias_repository.dart';
import 'package:bariskode_cf_email/features/aliases/presentation/create_alias_controller.dart';
import 'package:bariskode_cf_email/features/aliases/presentation/edit_alias_controller.dart';
import 'package:bariskode_cf_email/features/aliases/presentation/pages/alias_generator_page.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/auth/domain/repositories/auth_repository.dart';
import 'package:bariskode_cf_email/features/domains/domain/entities/domain_summary.dart';
import 'package:bariskode_cf_email/features/domains/presentation/domain_context.dart';
import 'package:bariskode_cf_email/shared/models/alias_model.dart';
import 'package:bariskode_cf_email/shared/utils/session_invalidator.dart';
import 'package:flutter/material.dart';

class AliasListPage extends StatefulWidget {
  const AliasListPage({
    super.key,
    required this.authRepository,
    required this.domainContext,
    required this.aliasRepository,
  });

  final AuthRepository authRepository;
  final DomainContext domainContext;
  final AliasRepositoryContract aliasRepository;

  @override
  State<AliasListPage> createState() => _AliasListPageState();
}

class _AliasListPageState extends State<AliasListPage> {
  List<AliasModel> _aliases = const [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _activeZoneId;
  bool _reloadRequested = false;
  final Set<String> _mutatingAliasIds = <String>{};

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
        _aliases = const [];
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

    await _loadAliases(zoneId: zoneId);
  }

  Future<void> _loadAliases({String? zoneId}) async {
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
      final aliases = await widget.aliasRepository.listAliases(
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
        _aliases = aliases;
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
        _errorMessage = AppStrings.aliasLoadError;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = AppStrings.aliasLoadError;
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
          return const Center(child: Text(AppStrings.aliasNoDomainSelected));
        }

        if (_isLoading) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(AppStrings.aliasLoadingLabel),
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
                    onPressed: _loadAliases,
                    child: const Text(AppStrings.retryButton),
                  ),
                ],
              ),
            ),
          );
        }

        if (_aliases.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.aliasEmptyState(selectedDomain.name),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _loadAliases,
                    icon: const Icon(Icons.refresh),
                    label: const Text(AppStrings.aliasRefreshButton),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _openCreateAliasSheet(selectedDomain),
                    icon: const Icon(Icons.add),
                    label: const Text(AppStrings.createAliasButton),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _openAliasGeneratorPage(selectedDomain),
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text(AppStrings.aliasGeneratorButton),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadAliases,
          child: ListView.builder(
            itemCount: _aliases.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: Text(AppStrings.aliasListTitle(selectedDomain.name)),
                  subtitle: const Text(AppStrings.aliasListSubtitle),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () =>
                            _openAliasGeneratorPage(selectedDomain),
                        icon: const Icon(Icons.auto_awesome_outlined),
                        tooltip: AppStrings.aliasGeneratorButton,
                      ),
                      IconButton(
                        onPressed: () => _openCreateAliasSheet(selectedDomain),
                        icon: const Icon(Icons.add),
                        tooltip: AppStrings.createAliasButton,
                      ),
                      IconButton(
                        onPressed: _loadAliases,
                        icon: const Icon(Icons.refresh),
                        tooltip: AppStrings.aliasRefreshButton,
                      ),
                    ],
                  ),
                );
              }

              final alias = _aliases[index - 1];

              return ListTile(
                title: Text(alias.address),
                subtitle: Text(
                  alias.isSupported
                      ? alias.destination
                      : AppStrings.aliasUnsupportedRule,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      alias.isEnabled
                          ? AppStrings.aliasStatusEnabled
                          : AppStrings.aliasStatusDisabled,
                    ),
                    if (alias.isSupported) ...[
                      const SizedBox(width: 8),
                      Switch(
                        value: alias.isEnabled,
                        onChanged: _mutatingAliasIds.contains(alias.id)
                            ? null
                            : (value) => _toggleAliasEnabled(
                                selectedDomain: selectedDomain,
                                alias: alias,
                                isEnabled: value,
                              ),
                      ),
                      IconButton(
                        onPressed: _mutatingAliasIds.contains(alias.id)
                            ? null
                            : () => _openEditAliasSheet(
                                selectedDomain: selectedDomain,
                                alias: alias,
                              ),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: AppStrings.editAliasTitle,
                      ),
                      IconButton(
                        onPressed: _mutatingAliasIds.contains(alias.id)
                            ? null
                            : () => _confirmDeleteAlias(
                                selectedDomain: selectedDomain,
                                alias: alias,
                              ),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: AppStrings.deleteAliasTooltip,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openCreateAliasSheet(DomainSummary selectedDomain) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return CreateAliasSheet(
          domainName: selectedDomain.name,
          zoneId: selectedDomain.id,
          aliasRepository: widget.aliasRepository,
          authRepository: widget.authRepository,
          domainContext: widget.domainContext,
        );
      },
    );

    if (result == true && mounted) {
      await _loadAliases();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.createAliasSuccess)),
      );
    }
  }

  Future<void> _openEditAliasSheet({
    required DomainSummary selectedDomain,
    required AliasModel alias,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return EditAliasSheet(
          domainName: selectedDomain.name,
          zoneId: selectedDomain.id,
          alias: alias,
          aliasRepository: widget.aliasRepository,
          authRepository: widget.authRepository,
          domainContext: widget.domainContext,
        );
      },
    );

    if (result == true && mounted) {
      await _loadAliases();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.editAliasSuccess)),
      );
    }
  }

  Future<void> _openAliasGeneratorPage(DomainSummary selectedDomain) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) {
          return AliasGeneratorPage(
            domainName: selectedDomain.name,
            zoneId: selectedDomain.id,
            aliasRepository: widget.aliasRepository,
            authRepository: widget.authRepository,
            domainContext: widget.domainContext,
          );
        },
      ),
    );

    if (result == true && mounted) {
      await _loadAliases();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.createAliasSuccess)),
      );
    }
  }

  Future<void> _confirmDeleteAlias({
    required DomainSummary selectedDomain,
    required AliasModel alias,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.deleteAliasTitle),
          content: Text('${AppStrings.deleteAliasMessage}\n\n${alias.address}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(AppStrings.createAliasCancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(AppStrings.deleteAliasConfirmButton),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteAlias(selectedDomain: selectedDomain, alias: alias);
    }
  }

  Future<void> _deleteAlias({
    required DomainSummary selectedDomain,
    required AliasModel alias,
  }) async {
    setState(() {
      _mutatingAliasIds.add(alias.id);
    });

    try {
      await widget.aliasRepository.deleteAlias(
        zoneId: selectedDomain.id,
        ruleId: alias.id,
      );

      if (!mounted) {
        return;
      }

      await _loadAliases();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.deleteAliasSuccess)),
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
        const SnackBar(content: Text(AppStrings.deleteAliasGenericError)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.deleteAliasGenericError)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _mutatingAliasIds.remove(alias.id);
        });
      }
    }
  }

  Future<void> _toggleAliasEnabled({
    required DomainSummary selectedDomain,
    required AliasModel alias,
    required bool isEnabled,
  }) async {
    setState(() {
      _mutatingAliasIds.add(alias.id);
    });

    try {
      await widget.aliasRepository.updateAlias(
        zoneId: selectedDomain.id,
        ruleId: alias.id,
        aliasAddress: alias.address,
        destination: alias.destination,
        isEnabled: isEnabled,
      );

      if (!mounted) {
        return;
      }

      await _loadAliases();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEnabled
                ? AppStrings.toggleAliasEnableSuccess
                : AppStrings.toggleAliasDisableSuccess,
          ),
        ),
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
        const SnackBar(content: Text(AppStrings.toggleAliasGenericError)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.toggleAliasGenericError)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _mutatingAliasIds.remove(alias.id);
        });
      }
    }
  }
}

class CreateAliasSheet extends StatefulWidget {
  const CreateAliasSheet({
    super.key,
    required this.domainName,
    required this.zoneId,
    required this.aliasRepository,
    required this.authRepository,
    required this.domainContext,
    this.initialAliasLocalPart,
  });

  final String domainName;
  final String zoneId;
  final AliasRepositoryContract aliasRepository;
  final AuthRepository authRepository;
  final DomainContext domainContext;
  final String? initialAliasLocalPart;

  @override
  State<CreateAliasSheet> createState() => _CreateAliasSheetState();
}

class _CreateAliasSheetState extends State<CreateAliasSheet> {
  late final CreateAliasController _controller;
  late final TextEditingController _aliasController;
  final TextEditingController _destinationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = CreateAliasController(
      aliasRepository: widget.aliasRepository,
    );
    _aliasController = TextEditingController(
      text: widget.initialAliasLocalPart ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _aliasController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final result = await _controller.submit(
      zoneId: widget.zoneId,
      domainName: widget.domainName,
      aliasLocalPart: _aliasController.text,
      destination: _destinationController.text,
    );

    if (!mounted) {
      return;
    }

    if (result.status == CreateAliasStatus.authFailure &&
        result.authFailure != null) {
      final failure = result.authFailure!;

      if (failure.type == AuthFailureType.invalidToken ||
          failure.type == AuthFailureType.insufficientPermissions) {
        await invalidateSessionAndReturnToLogin(
          context: context,
          authRepository: widget.authRepository,
          domainContext: widget.domainContext,
        );
      }

      return;
    }

    if (result.isSuccess) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.createAliasTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(widget.domainName),
                const SizedBox(height: 16),
                TextField(
                  controller: _aliasController,
                  enabled: !_controller.isSubmitting,
                  onChanged: (_) => _controller.clearSubmitError(),
                  decoration: InputDecoration(
                    labelText: AppStrings.createAliasAliasLabel,
                    hintText: AppStrings.createAliasAliasHint,
                    border: const OutlineInputBorder(),
                    errorText: _controller.aliasError,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _destinationController,
                  enabled: !_controller.isSubmitting,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => _controller.clearSubmitError(),
                  decoration: InputDecoration(
                    labelText: AppStrings.createAliasDestinationLabel,
                    hintText: AppStrings.createAliasDestinationHint,
                    border: const OutlineInputBorder(),
                    errorText: _controller.destinationError,
                  ),
                ),
                if (_controller.submitError != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _controller.submitError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _controller.isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: const Text(AppStrings.createAliasCancelButton),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _controller.isSubmitting ? null : _submit,
                        child: _controller.isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(AppStrings.createAliasSubmitButton),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class EditAliasSheet extends StatefulWidget {
  const EditAliasSheet({
    super.key,
    required this.domainName,
    required this.zoneId,
    required this.alias,
    required this.aliasRepository,
    required this.authRepository,
    required this.domainContext,
  });

  final String domainName;
  final String zoneId;
  final AliasModel alias;
  final AliasRepositoryContract aliasRepository;
  final AuthRepository authRepository;
  final DomainContext domainContext;

  @override
  State<EditAliasSheet> createState() => _EditAliasSheetState();
}

class _EditAliasSheetState extends State<EditAliasSheet> {
  late final EditAliasController _controller;
  late final TextEditingController _aliasAddressController;
  late final TextEditingController _destinationController;

  @override
  void initState() {
    super.initState();
    _controller = EditAliasController(aliasRepository: widget.aliasRepository);
    _aliasAddressController = TextEditingController(text: widget.alias.address);
    _destinationController = TextEditingController(
      text: widget.alias.destination,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _aliasAddressController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final result = await _controller.submit(
      zoneId: widget.zoneId,
      ruleId: widget.alias.id,
      aliasAddress: widget.alias.address,
      isEnabled: widget.alias.isEnabled,
      destination: _destinationController.text,
    );

    if (!mounted) {
      return;
    }

    if (result.status == EditAliasStatus.authFailure &&
        result.authFailure != null) {
      final failure = result.authFailure!;

      if (failure.type == AuthFailureType.invalidToken ||
          failure.type == AuthFailureType.insufficientPermissions) {
        await invalidateSessionAndReturnToLogin(
          context: context,
          authRepository: widget.authRepository,
          domainContext: widget.domainContext,
        );
      }

      return;
    }

    if (result.isSuccess) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.editAliasTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(widget.domainName),
                const SizedBox(height: 16),
                TextField(
                  controller: _aliasAddressController,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: AppStrings.editAliasAliasLabel,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _destinationController,
                  enabled: !_controller.isSubmitting,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => _controller.clearSubmitError(),
                  decoration: InputDecoration(
                    labelText: AppStrings.editAliasDestinationLabel,
                    hintText: AppStrings.createAliasDestinationHint,
                    border: const OutlineInputBorder(),
                    errorText: _controller.destinationError,
                  ),
                ),
                if (_controller.submitError != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _controller.submitError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _controller.isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: const Text(AppStrings.createAliasCancelButton),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _controller.isSubmitting ? null : _submit,
                        child: _controller.isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(AppStrings.editAliasSubmitButton),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
