import 'dart:math';

class AliasGenerator {
  AliasGenerator({Random? random}) : _random = random ?? Random.secure();

  static const _randomChars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final Random _random;

  String generateLocalPart({required String service, int suffixLength = 5}) {
    final normalizedService = normalizeService(service);
    if (normalizedService.isEmpty) {
      throw const FormatException('Service is required.');
    }

    final suffix = List.generate(
      suffixLength,
      (_) => _randomChars[_random.nextInt(_randomChars.length)],
    ).join();

    return '$normalizedService-$suffix';
  }

  String generateAddress({
    required String service,
    required String domainName,
    int suffixLength = 5,
  }) {
    final localPart = generateLocalPart(
      service: service,
      suffixLength: suffixLength,
    );
    return '$localPart@$domainName';
  }

  static String normalizeService(String service) {
    final normalized = service.trim().toLowerCase();
    final buffer = StringBuffer();
    var lastWasSeparator = false;

    for (final rune in normalized.runes) {
      final char = String.fromCharCode(rune);
      final isAlphaNumeric = RegExp(r'[a-z0-9]').hasMatch(char);
      final isSupportedSeparator =
          char == '.' || char == '_' || char == '+' || char == '-';

      if (isAlphaNumeric) {
        buffer.write(char);
        lastWasSeparator = false;
        continue;
      }

      if ((char == ' ' || isSupportedSeparator) &&
          buffer.isNotEmpty &&
          !lastWasSeparator) {
        buffer.write('-');
        lastWasSeparator = true;
      }
    }

    return buffer.toString().replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
