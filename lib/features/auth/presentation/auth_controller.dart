import 'package:bariskode_cf_email/core/utils/validators/token_validator.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository authRepository,
    TokenValidator tokenValidator = const TokenValidator(),
  }) : _authRepository = authRepository,
       _tokenValidator = tokenValidator;

  final AuthRepository _authRepository;
  final TokenValidator _tokenValidator;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<bool> submit(String rawToken) async {
    final validationResult = _tokenValidator.validate(rawToken);

    if (!validationResult.isValid) {
      _errorMessage = validationResult.errorMessage;
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.loginWithToken(validationResult.value!);
      return true;
    } on AuthFailure catch (failure) {
      _errorMessage = failure.message;
      return false;
    } catch (_) {
      _errorMessage = const AuthFailure.network().message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
