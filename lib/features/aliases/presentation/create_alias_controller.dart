import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/core/utils/validators/email_validator.dart';
import 'package:bariskode_cf_email/features/aliases/data/alias_repository.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/shared/models/api_exception.dart';
import 'package:flutter/foundation.dart';

class CreateAliasController extends ChangeNotifier {
  CreateAliasController({required AliasRepositoryContract aliasRepository})
    : _aliasRepository = aliasRepository;

  static final _aliasLocalPartPattern = RegExp(
    r'^[a-z0-9](?:[a-z0-9._+-]*[a-z0-9])?$',
  );

  final AliasRepositoryContract _aliasRepository;

  bool _isSubmitting = false;
  String? _aliasError;
  String? _destinationError;
  String? _submitError;

  bool get isSubmitting => _isSubmitting;
  String? get aliasError => _aliasError;
  String? get destinationError => _destinationError;
  String? get submitError => _submitError;

  void clearSubmitError() {
    if (_submitError == null) {
      return;
    }

    _submitError = null;
    notifyListeners();
  }

  bool validate({
    required String aliasLocalPart,
    required String? destination,
  }) {
    final normalizedAlias = aliasLocalPart.trim();
    final normalizedDestination = destination?.trim() ?? '';

    _aliasError = null;
    _destinationError = null;
    _submitError = null;

    if (normalizedAlias.isEmpty) {
      _aliasError = AppStrings.createAliasAliasRequired;
    } else if (normalizedAlias.contains('@')) {
      _aliasError = AppStrings.createAliasAliasLocalPartOnly;
    } else if (!_aliasLocalPartPattern.hasMatch(
      normalizedAlias.toLowerCase(),
    )) {
      _aliasError = AppStrings.createAliasAliasInvalid;
    }

    if (normalizedDestination.isEmpty) {
      _destinationError = AppStrings.createAliasDestinationRequired;
    }

    notifyListeners();
    return _aliasError == null && _destinationError == null;
  }

  Future<CreateAliasResult> submit({
    required String zoneId,
    required String domainName,
    required String aliasLocalPart,
    required String? destination,
  }) async {
    if (!validate(aliasLocalPart: aliasLocalPart, destination: destination)) {
      return const CreateAliasResult.validationFailed();
    }

    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      final normalizedAlias = aliasLocalPart.trim().toLowerCase();
      final normalizedDestination = destination!.trim().toLowerCase();

      await _aliasRepository.createAlias(
        zoneId: zoneId,
        aliasAddress: '$normalizedAlias@$domainName',
        destination: normalizedDestination,
      );

      return const CreateAliasResult.success();
    } on AuthFailure catch (failure) {
      return CreateAliasResult.authFailure(failure);
    } on ApiException catch (exception) {
      _submitError = exception.message;
      return const CreateAliasResult.serverError();
    } catch (_) {
      _submitError = AppStrings.createAliasGenericError;
      return const CreateAliasResult.serverError();
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}

class CreateAliasResult {
  const CreateAliasResult._({this.authFailure, required this.status});

  const CreateAliasResult.success() : this._(status: CreateAliasStatus.success);

  const CreateAliasResult.validationFailed()
    : this._(status: CreateAliasStatus.validationFailed);

  const CreateAliasResult.serverError()
    : this._(status: CreateAliasStatus.serverError);

  const CreateAliasResult.authFailure(AuthFailure failure)
    : this._(status: CreateAliasStatus.authFailure, authFailure: failure);

  final CreateAliasStatus status;
  final AuthFailure? authFailure;

  bool get isSuccess => status == CreateAliasStatus.success;
}

enum CreateAliasStatus { success, validationFailed, serverError, authFailure }
