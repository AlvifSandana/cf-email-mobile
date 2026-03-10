import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/core/utils/validators/email_validator.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/destinations/data/destination_repository.dart';
import 'package:bariskode_cf_email/features/destinations/domain/entities/destination_email.dart';
import 'package:bariskode_cf_email/features/domains/domain/entities/domain_summary.dart';
import 'package:bariskode_cf_email/shared/models/api_exception.dart';
import 'package:flutter/material.dart';

class DestinationEmailField extends StatefulWidget {
  const DestinationEmailField({
    super.key,
    required this.selectedDomain,
    required this.destinationRepository,
    required this.enabled,
    this.initialValue,
    this.errorText,
    this.onAuthFailure,
    required this.onChanged,
  });

  final DomainSummary selectedDomain;
  final DestinationRepositoryContract destinationRepository;
  final bool enabled;
  final String? initialValue;
  final String? errorText;
  final DestinationAuthFailureHandler? onAuthFailure;
  final ValueChanged<String?> onChanged;

  @override
  State<DestinationEmailField> createState() => _DestinationEmailFieldState();
}

class _DestinationEmailFieldState extends State<DestinationEmailField> {
  List<DestinationEmail> _destinations = const [];
  bool _isLoading = true;
  bool _isAdding = false;
  String? _selectedEmail;
  String? _loadError;

  void _notifySelectionChanged(String? value) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      widget.onChanged(value);
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedEmail = widget.initialValue;
    _loadDestinations();
  }

  Future<void> _loadDestinations() async {
    if (widget.selectedDomain.accountId.isEmpty) {
      setState(() {
        _destinations = const [];
        _selectedEmail = null;
        _isLoading = false;
        _loadError = AppStrings.destinationLoadError;
      });
      _notifySelectionChanged(null);
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final destinations = await widget.destinationRepository.listDestinations(
        accountId: widget.selectedDomain.accountId,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _destinations = destinations;
        final hasExistingVerified =
            _selectedEmail != null &&
            destinations.any(
              (item) => item.email == _selectedEmail && item.isVerified,
            );
        if (!hasExistingVerified) {
          _selectedEmail = destinations
              .where((item) => item.isVerified)
              .map((item) => item.email)
              .cast<String?>()
              .firstOrNull;
        }
      });

      _notifySelectionChanged(_selectedEmail);
    } on AuthFailure catch (failure) {
      if (!mounted) {
        return;
      }

      setState(() {
        _destinations = const [];
        _selectedEmail = null;
        _loadError = AppStrings.destinationLoadError;
      });
      _notifySelectionChanged(null);

      if ((failure.type == AuthFailureType.invalidToken ||
              failure.type == AuthFailureType.insufficientPermissions) &&
          widget.onAuthFailure != null) {
        await widget.onAuthFailure!(failure);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadError = AppStrings.destinationLoadError;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showAddDestinationDialog() async {
    final controller = TextEditingController();
    String? errorText;

    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(AppStrings.destinationDialogTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(AppStrings.destinationDialogDescription),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isAdding,
                    decoration: InputDecoration(
                      labelText: AppStrings.createAliasDestinationLabel,
                      hintText: AppStrings.createAliasDestinationHint,
                      border: const OutlineInputBorder(),
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isAdding
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text(AppStrings.createAliasCancelButton),
                ),
                FilledButton(
                  onPressed: _isAdding
                      ? null
                      : () async {
                          final value = controller.text.trim().toLowerCase();
                          if (value.isEmpty) {
                            setDialogState(() {
                              errorText =
                                  AppStrings.createAliasDestinationRequired;
                            });
                            return;
                          }

                          if (!EmailValidator.isValid(value)) {
                            setDialogState(() {
                              errorText =
                                  AppStrings.createAliasDestinationInvalid;
                            });
                            return;
                          }

                          setDialogState(() {
                            errorText = null;
                          });

                          setState(() {
                            _isAdding = true;
                          });

                          try {
                            await widget.destinationRepository
                                .createDestination(
                                  accountId: widget.selectedDomain.accountId,
                                  email: value,
                                );
                            if (!context.mounted) {
                              return;
                            }
                            Navigator.of(context).pop(true);
                          } on ApiException catch (error) {
                            setDialogState(() {
                              errorText = error.message;
                            });
                          } on AuthFailure catch (failure) {
                            if (failure.type == AuthFailureType.invalidToken ||
                                failure.type ==
                                    AuthFailureType.insufficientPermissions) {
                              if (widget.onAuthFailure != null) {
                                await widget.onAuthFailure!(failure);
                              }
                              if (context.mounted) {
                                Navigator.of(context).pop(false);
                              }
                              return;
                            }

                            setDialogState(() {
                              errorText = AppStrings.destinationCreateError;
                            });
                          } catch (_) {
                            setDialogState(() {
                              errorText = AppStrings.destinationCreateError;
                            });
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isAdding = false;
                              });
                            }
                          }
                        },
                  child: _isAdding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(AppStrings.destinationDialogSubmitButton),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (created == true && mounted) {
      await _loadDestinations();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.destinationCreateSuccess)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: AppStrings.createAliasDestinationLabel,
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(child: Text(AppStrings.destinationLoadingLabel)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: _destinations.any((item) => item.email == _selectedEmail)
              ? _selectedEmail
              : null,
          items: _destinations
              .map(
                (destination) => DropdownMenuItem<String>(
                  value: destination.email,
                  child: Text(
                    '${destination.email} · ${destination.isVerified ? AppStrings.destinationVerifiedBadge : AppStrings.destinationPendingBadge}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: widget.enabled
              ? (value) {
                  final selected = _destinations.firstWhere(
                    (item) => item.email == value,
                  );
                  if (!selected.isVerified) {
                    return;
                  }

                  setState(() {
                    _selectedEmail = value;
                  });
                  widget.onChanged(value);
                }
              : null,
          decoration: InputDecoration(
            labelText: AppStrings.createAliasDestinationLabel,
            hintText: AppStrings.destinationPickerHint,
            border: const OutlineInputBorder(),
            errorText: widget.errorText ?? _loadError,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                _destinations.where((item) => item.isVerified).isEmpty
                    ? AppStrings.destinationPickerEmpty
                    : AppStrings.destinationPickerHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            TextButton(
              onPressed: widget.enabled ? _showAddDestinationDialog : null,
              child: const Text(AppStrings.destinationPickerAddButton),
            ),
          ],
        ),
      ],
    );
  }
}

typedef DestinationAuthFailureHandler =
    Future<void> Function(AuthFailure failure);

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
