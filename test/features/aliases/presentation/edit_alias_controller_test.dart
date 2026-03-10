import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/features/aliases/data/alias_repository.dart';
import 'package:bariskode_cf_email/features/aliases/presentation/edit_alias_controller.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/shared/models/alias_model.dart';
import 'package:bariskode_cf_email/shared/models/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validates empty destination', () {
    final controller = EditAliasController(
      aliasRepository: FakeAliasRepository(),
    );

    final isValid = controller.validate(destination: ' ');

    expect(isValid, isFalse);
    expect(
      controller.destinationError,
      AppStrings.createAliasDestinationRequired,
    );
  });

  test('accepts any non-empty destination value from verified picker', () {
    final controller = EditAliasController(
      aliasRepository: FakeAliasRepository(),
    );

    final isValid = controller.validate(destination: 'not-an-email');

    expect(isValid, isTrue);
    expect(controller.destinationError, isNull);
  });

  test('submits normalized destination and preserves alias metadata', () async {
    final repository = FakeAliasRepository();
    final controller = EditAliasController(aliasRepository: repository);

    final result = await controller.submit(
      zoneId: 'zone-123',
      ruleId: 'rule-1',
      aliasAddress: 'sales@example.com',
      isEnabled: true,
      destination: ' DEST@example.net ',
    );

    expect(result.isSuccess, isTrue);
    expect(repository.updateCalls.single.zoneId, 'zone-123');
    expect(repository.updateCalls.single.ruleId, 'rule-1');
    expect(repository.updateCalls.single.aliasAddress, 'sales@example.com');
    expect(repository.updateCalls.single.destination, 'dest@example.net');
    expect(repository.updateCalls.single.isEnabled, isTrue);
  });

  test('surfaces API error message on edit failure', () async {
    final controller = EditAliasController(
      aliasRepository: FakeAliasRepository(
        updateException: const ApiException('Destination already used.'),
      ),
    );

    final result = await controller.submit(
      zoneId: 'zone-123',
      ruleId: 'rule-1',
      aliasAddress: 'sales@example.com',
      isEnabled: true,
      destination: 'dest@example.net',
    );

    expect(result.status, EditAliasStatus.serverError);
    expect(controller.submitError, 'Destination already used.');
  });

  test('returns auth failure without masking it', () async {
    final controller = EditAliasController(
      aliasRepository: FakeAliasRepository(
        updateAuthFailure: const AuthFailure.invalidToken(),
      ),
    );

    final result = await controller.submit(
      zoneId: 'zone-123',
      ruleId: 'rule-1',
      aliasAddress: 'sales@example.com',
      isEnabled: true,
      destination: 'dest@example.net',
    );

    expect(result.status, EditAliasStatus.authFailure);
    expect(result.authFailure?.type, AuthFailureType.invalidToken);
  });
}

class FakeAliasRepository implements AliasRepositoryContract {
  FakeAliasRepository({this.updateException, this.updateAuthFailure});

  final Exception? updateException;
  final AuthFailure? updateAuthFailure;
  final List<UpdateCall> updateCalls = <UpdateCall>[];

  @override
  Future<AliasModel> createAlias({
    required String zoneId,
    required String aliasAddress,
    String? destination,
    String actionType = 'forward',
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<AliasModel>> listAliases({required String zoneId}) async =>
      const [];

  @override
  Future<AliasModel> updateAlias({
    required String zoneId,
    required String ruleId,
    required String aliasAddress,
    String? destination,
    required bool isEnabled,
    String actionType = 'forward',
  }) async {
    if (updateAuthFailure != null) {
      throw updateAuthFailure!;
    }

    if (updateException != null) {
      throw updateException!;
    }

    updateCalls.add(
      UpdateCall(
        zoneId: zoneId,
        ruleId: ruleId,
        aliasAddress: aliasAddress,
        destination: destination!,
        isEnabled: isEnabled,
      ),
    );

    return AliasModel(
      id: ruleId,
      address: aliasAddress,
      destination: destination!,
      isEnabled: isEnabled,
      isSupported: true,
    );
  }

  @override
  Future<void> deleteAlias({
    required String zoneId,
    required String ruleId,
  }) async {
    throw UnimplementedError();
  }
}

class UpdateCall {
  const UpdateCall({
    required this.zoneId,
    required this.ruleId,
    required this.aliasAddress,
    required this.destination,
    required this.isEnabled,
  });

  final String zoneId;
  final String ruleId;
  final String aliasAddress;
  final String destination;
  final bool isEnabled;
}
