import 'package:bariskode_cf_email/core/constants/app_strings.dart';

enum AuthFailureType { invalidToken, insufficientPermissions, network }

class AuthFailure implements Exception {
  const AuthFailure(this.type);

  const AuthFailure.invalidToken() : this(AuthFailureType.invalidToken);

  const AuthFailure.insufficientPermissions()
    : this(AuthFailureType.insufficientPermissions);

  const AuthFailure.network() : this(AuthFailureType.network);

  final AuthFailureType type;

  String get message {
    switch (type) {
      case AuthFailureType.invalidToken:
        return AppStrings.authErrorInvalidToken;
      case AuthFailureType.insufficientPermissions:
        return AppStrings.authErrorInsufficientPermissions;
      case AuthFailureType.network:
        return AppStrings.authErrorNetwork;
    }
  }
}
