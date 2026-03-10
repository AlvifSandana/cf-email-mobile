import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/features/aliases/data/alias_repository.dart';
import 'package:bariskode_cf_email/features/aliases/presentation/create_alias_controller.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/shared/models/alias_model.dart';
import 'package:bariskode_cf_email/shared/models/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validates empty alias and destination', () {
    final controller = CreateAliasController(
      aliasRepository: FakeAliasRepository(),
    );

    final isValid = controller.validate(aliasLocalPart: ' ', destination: ' ');

    expect(isValid, isFalse);
    expect(controller.aliasError, AppStrings.createAliasAliasRequired);
    expect(
      controller.destinationError,
      AppStrings.createAliasDestinationRequired,
    );
  });

  test('validates alias local part and destination presence', () {
    final controller = CreateAliasController(
      aliasRepository: FakeAliasRepository(),
    );

    final isValid = controller.validate(
      aliasLocalPart: 'sales@example.com',
      destination: ' ',
    );

    expect(isValid, isFalse);
    expect(controller.aliasError, AppStrings.createAliasAliasLocalPartOnly);
    expect(
      controller.destinationError,
      AppStrings.createAliasDestinationRequired,
    );
  });

  test('validates invalid alias characters', () {
    final controller = CreateAliasController(
      aliasRepository: FakeAliasRepository(),
    );

    final isValid = controller.validate(
      aliasLocalPart: 'sales team',
      destination: 'dest@example.net',
    );

    expect(isValid, isFalse);
    expect(controller.aliasError, AppStrings.createAliasAliasInvalid);
    expect(controller.destinationError, isNull);
  });

  test('submits normalized alias address and destination', () async {
    final repository = FakeAliasRepository();
    final controller = CreateAliasController(aliasRepository: repository);

    final result = await controller.submit(
      zoneId: 'zone-123',
      domainName: 'example.com',
      aliasLocalPart: ' Sales ',
      destination: ' DEST@example.net ',
    );

    expect(result.isSuccess, isTrue);
    expect(repository.createCalls.single.zoneId, 'zone-123');
    expect(repository.createCalls.single.aliasAddress, 'sales@example.com');
    expect(repository.createCalls.single.destination, 'dest@example.net');
  });

  test('surfaces API error message on create failure', () async {
    final controller = CreateAliasController(
      aliasRepository: FakeAliasRepository(
        createException: const ApiException('Alias already exists.'),
      ),
    );

    final result = await controller.submit(
      zoneId: 'zone-123',
      domainName: 'example.com',
      aliasLocalPart: 'sales',
      destination: 'dest@example.net',
    );

    expect(result.status, CreateAliasStatus.serverError);
    expect(controller.submitError, 'Alias already exists.');
  });

  test('returns auth failure without masking it', () async {
    final controller = CreateAliasController(
      aliasRepository: FakeAliasRepository(
        createAuthFailure: const AuthFailure.invalidToken(),
      ),
    );

    final result = await controller.submit(
      zoneId: 'zone-123',
      domainName: 'example.com',
      aliasLocalPart: 'sales',
      destination: 'dest@example.net',
    );

    expect(result.status, CreateAliasStatus.authFailure);
    expect(result.authFailure?.type, AuthFailureType.invalidToken);
  });
}

class FakeAliasRepository implements AliasRepositoryContract {
  FakeAliasRepository({this.createException, this.createAuthFailure});

  final Exception? createException;
  final AuthFailure? createAuthFailure;
  final List<CreateCall> createCalls = <CreateCall>[];

  @override
  Future<AliasModel> createAlias({
    required String zoneId,
    required String aliasAddress,
    String? destination,
    String actionType = 'forward',
  }) async {
    if (createAuthFailure != null) {
      throw createAuthFailure!;
    }

    if (createException != null) {
      throw createException!;
    }

    createCalls.add(
      CreateCall(
        zoneId: zoneId,
        aliasAddress: aliasAddress,
        destination: destination!,
      ),
    );

    return AliasModel(
      id: 'rule-1',
      address: aliasAddress,
      destination: destination!,
      isEnabled: true,
      isSupported: true,
    );
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
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAlias({
    required String zoneId,
    required String ruleId,
  }) async {
    throw UnimplementedError();
  }
}

class CreateCall {
  const CreateCall({
    required this.zoneId,
    required this.aliasAddress,
    required this.destination,
  });

  final String zoneId;
  final String aliasAddress;
  final String destination;
}
