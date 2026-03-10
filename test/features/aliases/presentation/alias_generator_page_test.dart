import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/core/constants/app_routes.dart';
import 'package:bariskode_cf_email/core/utils/alias_generator.dart';
import 'package:bariskode_cf_email/features/aliases/data/alias_repository.dart';
import 'package:bariskode_cf_email/features/aliases/presentation/pages/alias_generator_page.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/auth/domain/repositories/auth_repository.dart';
import 'package:bariskode_cf_email/features/destinations/data/destination_repository.dart';
import 'package:bariskode_cf_email/features/destinations/domain/entities/destination_email.dart';
import 'package:bariskode_cf_email/features/domains/data/domain_repository.dart';
import 'package:bariskode_cf_email/features/domains/domain/entities/domain_summary.dart';
import 'package:bariskode_cf_email/features/domains/presentation/domain_context.dart';
import 'package:bariskode_cf_email/shared/models/alias_model.dart';
import 'package:bariskode_cf_email/shared/models/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _selectVerifiedDestination(
  WidgetTester tester,
  String email,
) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining(email).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows generated alias preview and regenerate changes it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AliasGeneratorPage(
          domainName: 'example.com',
          zoneId: 'zone-1',
          aliasRepository: _FakeAliasRepository(),
          destinationRepository: _FakeDestinationRepository(),
          selectedDomain: const DomainSummary(
            id: 'zone-1',
            name: 'example.com',
            accountId: 'acc-1',
          ),
          authRepository: _FakeAuthRepository(),
          domainContext: DomainContext(repository: _FakeDomainRepository()),
          aliasGenerator: _SequenceAliasGenerator([
            'github-a1b2c',
            'github-z9y8x',
          ]),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.aliasGeneratorServiceLabel),
      'github',
    );
    await tester.tap(find.text(AppStrings.aliasGeneratorRegenerateButton));
    await tester.pumpAndSettle();

    expect(find.text('github-a1b2c@example.com'), findsOneWidget);

    await tester.tap(find.text(AppStrings.aliasGeneratorRegenerateButton));
    await tester.pumpAndSettle();

    expect(find.text('github-z9y8x@example.com'), findsOneWidget);
  });

  testWidgets('successful create submits generated alias', (
    WidgetTester tester,
  ) async {
    final repository = _FakeAliasRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: AliasGeneratorPage(
          domainName: 'example.com',
          zoneId: 'zone-1',
          aliasRepository: repository,
          destinationRepository: _FakeDestinationRepository(),
          selectedDomain: const DomainSummary(
            id: 'zone-1',
            name: 'example.com',
            accountId: 'acc-1',
          ),
          authRepository: _FakeAuthRepository(),
          domainContext: DomainContext(repository: _FakeDomainRepository()),
          aliasGenerator: _SequenceAliasGenerator(['github-a1b2c']),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.aliasGeneratorServiceLabel),
      'github',
    );
    await tester.tap(find.text(AppStrings.aliasGeneratorRegenerateButton));
    await tester.pumpAndSettle();
    await _selectVerifiedDestination(tester, 'dest@example.net');
    await tester.tap(find.text(AppStrings.aliasGeneratorCreateButton));
    await tester.pumpAndSettle();

    expect(
      repository.createCalls.single.aliasAddress,
      'github-a1b2c@example.com',
    );
    expect(repository.createCalls.single.destination, 'dest@example.net');
  });

  testWidgets('create submits the alias currently shown in preview', (
    WidgetTester tester,
  ) async {
    final repository = _FakeAliasRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: AliasGeneratorPage(
          domainName: 'example.com',
          zoneId: 'zone-1',
          aliasRepository: repository,
          destinationRepository: _FakeDestinationRepository(),
          selectedDomain: const DomainSummary(
            id: 'zone-1',
            name: 'example.com',
            accountId: 'acc-1',
          ),
          authRepository: _FakeAuthRepository(),
          domainContext: DomainContext(repository: _FakeDomainRepository()),
          aliasGenerator: _SequenceAliasGenerator([
            'github-a1b2c',
            'github-z9y8x',
          ]),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.aliasGeneratorServiceLabel),
      'github',
    );
    await tester.tap(find.text(AppStrings.aliasGeneratorRegenerateButton));
    await tester.pumpAndSettle();

    expect(find.text('github-a1b2c@example.com'), findsOneWidget);

    await _selectVerifiedDestination(tester, 'dest@example.net');
    await tester.tap(find.text(AppStrings.aliasGeneratorCreateButton));
    await tester.pumpAndSettle();

    expect(
      repository.createCalls.single.aliasAddress,
      'github-a1b2c@example.com',
    );
  });

  testWidgets('changing service clears stale preview', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AliasGeneratorPage(
          domainName: 'example.com',
          zoneId: 'zone-1',
          aliasRepository: _FakeAliasRepository(),
          destinationRepository: _FakeDestinationRepository(),
          selectedDomain: const DomainSummary(
            id: 'zone-1',
            name: 'example.com',
            accountId: 'acc-1',
          ),
          authRepository: _FakeAuthRepository(),
          domainContext: DomainContext(repository: _FakeDomainRepository()),
          aliasGenerator: _SequenceAliasGenerator(['github-a1b2c']),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.aliasGeneratorServiceLabel),
      'github',
    );
    await tester.tap(find.text(AppStrings.aliasGeneratorRegenerateButton));
    await tester.pumpAndSettle();

    expect(find.text('github-a1b2c@example.com'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.aliasGeneratorServiceLabel),
      'amazon',
    );
    await tester.pumpAndSettle();

    expect(find.text('github-a1b2c@example.com'), findsNothing);
    expect(
      find.text(AppStrings.aliasGeneratorPreviewPlaceholder),
      findsOneWidget,
    );
  });

  testWidgets('api error stays on page and shows error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AliasGeneratorPage(
          domainName: 'example.com',
          zoneId: 'zone-1',
          aliasRepository: _FakeAliasRepository(
            createError: const ApiException('Alias already exists.'),
          ),
          destinationRepository: _FakeDestinationRepository(),
          selectedDomain: const DomainSummary(
            id: 'zone-1',
            name: 'example.com',
            accountId: 'acc-1',
          ),
          authRepository: _FakeAuthRepository(),
          domainContext: DomainContext(repository: _FakeDomainRepository()),
          aliasGenerator: _SequenceAliasGenerator(['github-a1b2c']),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.aliasGeneratorServiceLabel),
      'github',
    );
    await tester.tap(find.text(AppStrings.aliasGeneratorRegenerateButton));
    await tester.pumpAndSettle();
    await _selectVerifiedDestination(tester, 'dest@example.net');
    await tester.tap(find.text(AppStrings.aliasGeneratorCreateButton));
    await tester.pumpAndSettle();

    expect(find.text('Alias already exists.'), findsOneWidget);
    expect(find.text(AppStrings.aliasGeneratorTitle), findsOneWidget);
  });

  testWidgets('network failure does not logout', (WidgetTester tester) async {
    final authRepository = _FakeAuthRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: AliasGeneratorPage(
          domainName: 'example.com',
          zoneId: 'zone-1',
          aliasRepository: _FakeAliasRepository(
            createAuthFailure: const AuthFailure.network(),
          ),
          destinationRepository: _FakeDestinationRepository(),
          selectedDomain: const DomainSummary(
            id: 'zone-1',
            name: 'example.com',
            accountId: 'acc-1',
          ),
          authRepository: authRepository,
          domainContext: DomainContext(repository: _FakeDomainRepository()),
          aliasGenerator: _SequenceAliasGenerator(['github-a1b2c']),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.aliasGeneratorServiceLabel),
      'github',
    );
    await tester.tap(find.text(AppStrings.aliasGeneratorRegenerateButton));
    await tester.pumpAndSettle();
    await _selectVerifiedDestination(tester, 'dest@example.net');
    await tester.tap(find.text(AppStrings.aliasGeneratorCreateButton));
    await tester.pumpAndSettle();

    expect(authRepository.logoutCalls, 0);
    expect(find.text(AppStrings.aliasGeneratorTitle), findsOneWidget);
  });

  testWidgets('invalid token invalidates session', (WidgetTester tester) async {
    final authRepository = _FakeAuthRepository();

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.login: (_) => const Scaffold(body: Text('Login Page')),
        },
        home: AliasGeneratorPage(
          domainName: 'example.com',
          zoneId: 'zone-1',
          aliasRepository: _FakeAliasRepository(
            createAuthFailure: const AuthFailure.invalidToken(),
          ),
          destinationRepository: _FakeDestinationRepository(),
          selectedDomain: const DomainSummary(
            id: 'zone-1',
            name: 'example.com',
            accountId: 'acc-1',
          ),
          authRepository: authRepository,
          domainContext: DomainContext(repository: _FakeDomainRepository()),
          aliasGenerator: _SequenceAliasGenerator(['github-a1b2c']),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.aliasGeneratorServiceLabel),
      'github',
    );
    await tester.tap(find.text(AppStrings.aliasGeneratorRegenerateButton));
    await tester.pumpAndSettle();
    await _selectVerifiedDestination(tester, 'dest@example.net');
    await tester.tap(find.text(AppStrings.aliasGeneratorCreateButton));
    await tester.pumpAndSettle();

    expect(authRepository.logoutCalls, 1);
  });
}

class _SequenceAliasGenerator extends AliasGenerator {
  _SequenceAliasGenerator(this.values);

  final List<String> values;
  int _index = 0;

  @override
  String generateAddress({
    required String service,
    required String domainName,
    int suffixLength = 5,
  }) {
    final value = values[_index < values.length ? _index : values.length - 1];
    _index += 1;
    return '$value@$domainName';
  }
}

class _FakeAliasRepository implements AliasRepositoryContract {
  _FakeAliasRepository({this.createError, this.createAuthFailure});

  final Exception? createError;
  final AuthFailure? createAuthFailure;
  final List<_CreateAliasCall> createCalls = <_CreateAliasCall>[];

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

    if (createError != null) {
      throw createError!;
    }

    createCalls.add(
      _CreateAliasCall(
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
  Future<void> deleteAlias({
    required String zoneId,
    required String ruleId,
  }) async {}

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
}

class _FakeDestinationRepository implements DestinationRepositoryContract {
  @override
  Future<DestinationEmail> createDestination({
    required String accountId,
    required String email,
  }) async {
    return DestinationEmail(id: 'dest-1', email: email, isVerified: true);
  }

  @override
  Future<List<DestinationEmail>> listDestinations({
    required String accountId,
  }) async {
    return const [
      DestinationEmail(
        id: 'dest-1',
        email: 'dest@example.net',
        isVerified: true,
      ),
    ];
  }
}

class _CreateAliasCall {
  const _CreateAliasCall({
    required this.zoneId,
    required this.aliasAddress,
    required this.destination,
  });

  final String zoneId;
  final String aliasAddress;
  final String destination;
}

class _FakeAuthRepository implements AuthRepository {
  int logoutCalls = 0;

  @override
  Future<bool> hasValidSession() async => true;

  @override
  Future<void> loginWithToken(String token) async {}

  @override
  Future<void> logout() async {
    logoutCalls += 1;
  }

  @override
  Future<String?> readToken() async => 'token';
}

class _FakeDomainRepository implements DomainRepositoryContract {
  @override
  Future<List<DomainSummary>> listDomains() async => const [];
}
