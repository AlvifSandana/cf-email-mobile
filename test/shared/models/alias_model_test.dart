import 'package:bariskode_cf_email/shared/models/alias_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps supported routing rule payload into alias model', () {
    final alias = AliasModel.fromApi({
      'id': 'rule-1',
      'enabled': true,
      'matchers': [
        {'type': 'literal', 'field': 'to', 'value': 'hello@example.com'},
      ],
      'actions': [
        {
          'type': 'forward',
          'value': ['dest@example.net'],
        },
      ],
    });

    expect(alias.id, 'rule-1');
    expect(alias.address, 'hello@example.com');
    expect(alias.destination, 'dest@example.net');
    expect(alias.isEnabled, isTrue);
    expect(alias.isSupported, isTrue);
  });

  test('maps simple drop routing rule into blocked alias', () {
    final alias = AliasModel.fromApi({
      'id': 'rule-2',
      'enabled': false,
      'matchers': [
        {'type': 'literal', 'field': 'to', 'value': 'blocked@example.com'},
      ],
      'actions': [
        {'type': 'drop'},
      ],
    });

    expect(alias.isEnabled, isFalse);
    expect(alias.isSupported, isTrue);
    expect(alias.isBlocked, isTrue);
    expect(alias.address, 'blocked@example.com');
    expect(alias.destination, 'Blocked');
  });

  test('throws when required alias id is missing', () {
    expect(
      () => AliasModel.fromApi({
        'enabled': true,
        'matchers': const [],
        'actions': const [],
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('marks rule with extra matcher as unsupported', () {
    final alias = AliasModel.fromApi({
      'id': 'rule-3',
      'enabled': true,
      'matchers': [
        {'type': 'literal', 'field': 'to', 'value': 'hello@example.com'},
        {'type': 'regex', 'field': 'from', 'value': '.*@partner.com'},
      ],
      'actions': [
        {
          'type': 'forward',
          'value': ['dest@example.net'],
        },
      ],
    });

    expect(alias.isSupported, isFalse);
    expect(alias.address, 'Unsupported routing rule');
    expect(alias.destination, 'dest@example.net');
  });

  test('marks rule with extra action as unsupported', () {
    final alias = AliasModel.fromApi({
      'id': 'rule-4',
      'enabled': true,
      'matchers': [
        {'type': 'literal', 'field': 'to', 'value': 'hello@example.com'},
      ],
      'actions': [
        {
          'type': 'forward',
          'value': ['dest@example.net'],
        },
        {'type': 'drop'},
      ],
    });

    expect(alias.isSupported, isFalse);
    expect(alias.address, 'hello@example.com');
    expect(alias.destination, 'Unsupported destination');
  });
}
