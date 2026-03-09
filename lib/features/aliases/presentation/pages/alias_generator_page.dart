import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/core/utils/alias_generator.dart';
import 'package:bariskode_cf_email/core/utils/validators/email_validator.dart';
import 'package:bariskode_cf_email/features/aliases/data/alias_repository.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/auth/domain/repositories/auth_repository.dart';
import 'package:bariskode_cf_email/features/domains/presentation/domain_context.dart';
import 'package:bariskode_cf_email/shared/models/api_exception.dart';
import 'package:bariskode_cf_email/shared/utils/session_invalidator.dart';
import 'package:flutter/material.dart';

class AliasGeneratorPage extends StatefulWidget {
  AliasGeneratorPage({
    super.key,
    required this.domainName,
    required this.zoneId,
    required this.aliasRepository,
    required this.authRepository,
    required this.domainContext,
    AliasGenerator? aliasGenerator,
  }) : aliasGenerator = aliasGenerator ?? AliasGenerator();

  final String domainName;
  final String zoneId;
  final AliasRepositoryContract aliasRepository;
  final AuthRepository authRepository;
  final DomainContext domainContext;
  final AliasGenerator aliasGenerator;

  @override
  State<AliasGeneratorPage> createState() => _AliasGeneratorPageState();
}

class _AliasGeneratorPageState extends State<AliasGeneratorPage> {
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  String? _serviceError;
  String? _destinationError;
  String? _submitError;
  String? _generatedAlias;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _serviceController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _regenerate() {
    final normalizedService = AliasGenerator.normalizeService(
      _serviceController.text,
    );

    setState(() {
      _serviceError = normalizedService.isEmpty
          ? AppStrings.aliasGeneratorServiceRequired
          : null;
      _submitError = null;
      _generatedAlias = normalizedService.isEmpty
          ? null
          : widget.aliasGenerator.generateAddress(
              service: normalizedService,
              domainName: widget.domainName,
            );
    });
  }

  bool _validateInputs() {
    final normalizedService = AliasGenerator.normalizeService(
      _serviceController.text,
    );
    final normalizedDestination = _destinationController.text.trim();

    _serviceError = null;
    _destinationError = null;
    _submitError = null;

    if (normalizedService.isEmpty) {
      _serviceError = AppStrings.aliasGeneratorServiceRequired;
    }

    if (normalizedDestination.isEmpty) {
      _destinationError = AppStrings.createAliasDestinationRequired;
    } else if (!EmailValidator.isValid(normalizedDestination)) {
      _destinationError = AppStrings.createAliasDestinationInvalid;
    }

    setState(() {});
    return _serviceError == null && _destinationError == null;
  }

  Future<void> _submit() async {
    if (!_validateInputs()) {
      return;
    }

    final aliasAddress = _generatedAlias;
    if (aliasAddress == null) {
      setState(() {
        _submitError = AppStrings.aliasGeneratorPreviewPlaceholder;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      await widget.aliasRepository.createAlias(
        zoneId: widget.zoneId,
        aliasAddress: aliasAddress,
        destination: _destinationController.text.trim().toLowerCase(),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
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
        _submitError = AppStrings.createAliasGenericError;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _submitError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _submitError = AppStrings.createAliasGenericError;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.aliasGeneratorTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Text(
              widget.domainName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _serviceController,
              enabled: !_isSubmitting,
              onChanged: (_) {
                setState(() {
                  _serviceError = null;
                  _submitError = null;
                  _generatedAlias = null;
                });
              },
              decoration: InputDecoration(
                labelText: AppStrings.aliasGeneratorServiceLabel,
                hintText: AppStrings.aliasGeneratorServiceHint,
                border: const OutlineInputBorder(),
                errorText: _serviceError,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _destinationController,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) {
                if (_destinationError != null || _submitError != null) {
                  setState(() {
                    _destinationError = null;
                    _submitError = null;
                  });
                }
              },
              decoration: InputDecoration(
                labelText: AppStrings.createAliasDestinationLabel,
                hintText: AppStrings.createAliasDestinationHint,
                border: const OutlineInputBorder(),
                errorText: _destinationError,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _regenerate,
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.aliasGeneratorRegenerateButton),
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: AppStrings.aliasGeneratorPreviewLabel,
                border: OutlineInputBorder(),
              ),
              child: Text(
                _generatedAlias ?? AppStrings.aliasGeneratorPreviewPlaceholder,
              ),
            ),
            if (_submitError != null) ...[
              const SizedBox(height: 16),
              Text(
                _submitError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text(AppStrings.createAliasCancelButton),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSubmitting || _generatedAlias == null
                        ? null
                        : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(AppStrings.aliasGeneratorCreateButton),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
