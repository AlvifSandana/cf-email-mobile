import 'dart:math';

import 'package:bariskode_cf_email/core/utils/alias_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generates service-random local part', () {
    final generator = AliasGenerator(random: Random(1));

    final localPart = generator.generateLocalPart(service: 'github');

    expect(localPart, startsWith('github-'));
    expect(localPart.split('-').last, hasLength(5));
  });

  test('normalizes service to lowercase', () {
    final generator = AliasGenerator(random: Random(1));

    final localPart = generator.generateLocalPart(service: 'GitHub');

    expect(localPart, startsWith('github-'));
  });

  test('sanitizes unsupported characters', () {
    expect(AliasGenerator.normalizeService('Git Hub!'), 'git-hub');
  });

  test('throws for empty sanitized service', () {
    final generator = AliasGenerator(random: Random(1));

    expect(
      () => generator.generateLocalPart(service: ' !!! '),
      throwsA(isA<FormatException>()),
    );
  });

  test('generate address matches service-random@domain format', () {
    final generator = AliasGenerator(random: Random(1));

    final address = generator.generateAddress(
      service: 'amazon',
      domainName: 'example.com',
    );

    expect(address, startsWith('amazon-'));
    expect(address, endsWith('@example.com'));
  });
}
