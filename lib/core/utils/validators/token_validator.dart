import 'package:bariskode_cf_email/core/constants/app_strings.dart';

class TokenValidationResult {
  const TokenValidationResult({this.value, this.errorMessage});

  final String? value;
  final String? errorMessage;

  bool get isValid => value != null && errorMessage == null;
}

class TokenValidator {
  const TokenValidator();

  TokenValidationResult validate(String rawValue) {
    final normalized = rawValue.trim();

    if (normalized.isEmpty) {
      return const TokenValidationResult(
        errorMessage: AppStrings.loginValidationEmpty,
      );
    }

    if (normalized.toLowerCase().startsWith('bearer ')) {
      return const TokenValidationResult(
        errorMessage: AppStrings.loginValidationBearerPrefix,
      );
    }

    if (RegExp(r'\s').hasMatch(normalized)) {
      return const TokenValidationResult(
        errorMessage: AppStrings.loginValidationWhitespace,
      );
    }

    if (normalized.length < 20) {
      return const TokenValidationResult(
        errorMessage: AppStrings.loginValidationTooShort,
      );
    }

    return TokenValidationResult(value: normalized);
  }
}
