import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/core/utils/validators/token_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validator = TokenValidator();

  test('rejects empty token', () {
    final result = validator.validate('   ');

    expect(result.isValid, isFalse);
    expect(result.errorMessage, AppStrings.loginValidationEmpty);
  });

  test('rejects bearer prefix', () {
    final result = validator.validate('Bearer abcdefghijklmnopqrstuvwxyz');

    expect(result.isValid, isFalse);
    expect(result.errorMessage, AppStrings.loginValidationBearerPrefix);
  });

  test('rejects whitespace inside token', () {
    final result = validator.validate('abc defghijklmnopqrstuvwxyz');

    expect(result.isValid, isFalse);
    expect(result.errorMessage, AppStrings.loginValidationWhitespace);
  });

  test('returns normalized valid token', () {
    final result = validator.validate('  abcdefghijklmnopqrstuvwxyz123456  ');

    expect(result.isValid, isTrue);
    expect(result.value, 'abcdefghijklmnopqrstuvwxyz123456');
  });
}
