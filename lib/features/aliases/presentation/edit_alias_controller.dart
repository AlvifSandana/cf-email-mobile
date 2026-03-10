import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/core/utils/validators/email_validator.dart';
import 'package:bariskode_cf_email/features/aliases/data/alias_repository.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/shared/models/api_exception.dart';
import 'package:flutter/foundation.dart';

class EditAliasController extends ChangeNotifier {
  EditAliasController({required AliasRepositoryContract aliasRepository})
    : _aliasRepository = aliasRepository;

  final AliasRepositoryContract _aliasRepository;

  bool _isSubmitting = false;
  String? _destinationError;
  String? _submitError;

  bool get isSubmitting => _isSubmitting;
  String? get destinationError => _destinationError;
  String? get submitError => _submitError;

  void clearSubmitError() {
    if (_submitError == null) {
      return;
    }

    _submitError = null;
    notifyListeners();
  }

  bool validate({required String? destination}) {
    final normalizedDestination = destination?.trim() ?? '';

    _destinationError = null;
    _submitError = null;

    if (normalizedDestination.isEmpty) {
      _destinationError = AppStrings.createAliasDestinationRequired;
    }

    notifyListeners();
    return _destinationError == null;
  }

  Future<EditAliasResult> submit({
    required String zoneId,
    required String ruleId,
    required String aliasAddress,
    required bool isEnabled,
    required String? destination,
  }) async {
    if (!validate(destination: destination)) {
      return const EditAliasResult.validationFailed();
    }

    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      await _aliasRepository.updateAlias(
        zoneId: zoneId,
        ruleId: ruleId,
        aliasAddress: aliasAddress,
        destination: destination!.trim().toLowerCase(),
        isEnabled: isEnabled,
      );

      return const EditAliasResult.success();
    } on AuthFailure catch (failure) {
      return EditAliasResult.authFailure(failure);
    } on ApiException catch (exception) {
      _submitError = exception.message;
      return const EditAliasResult.serverError();
    } catch (_) {
      _submitError = AppStrings.editAliasGenericError;
      return const EditAliasResult.serverError();
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}

class EditAliasResult {
  const EditAliasResult._({this.authFailure, required this.status});

  const EditAliasResult.success() : this._(status: EditAliasStatus.success);

  const EditAliasResult.validationFailed()
    : this._(status: EditAliasStatus.validationFailed);

  const EditAliasResult.serverError()
    : this._(status: EditAliasStatus.serverError);

  const EditAliasResult.authFailure(AuthFailure failure)
    : this._(status: EditAliasStatus.authFailure, authFailure: failure);

  final EditAliasStatus status;
  final AuthFailure? authFailure;

  bool get isSuccess => status == EditAliasStatus.success;
}

enum EditAliasStatus { success, validationFailed, serverError, authFailure }
