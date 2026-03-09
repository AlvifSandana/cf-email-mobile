import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/domains/data/domain_repository.dart';
import 'package:bariskode_cf_email/features/domains/domain/entities/domain_summary.dart';
import 'package:flutter/foundation.dart';

class DomainContext extends ChangeNotifier {
  DomainContext({required DomainRepositoryContract repository})
    : _repository = repository;

  final DomainRepositoryContract _repository;

  List<DomainSummary> _domains = const [];
  DomainSummary? _selectedDomain;
  bool _isLoading = false;
  String? _errorMessage;
  AuthFailure? _authFailure;

  List<DomainSummary> get domains => _domains;
  DomainSummary? get selectedDomain => _selectedDomain;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AuthFailure? get authFailure => _authFailure;

  Future<void> loadDomains() async {
    _isLoading = true;
    _errorMessage = null;
    _authFailure = null;
    notifyListeners();

    try {
      final domains = await _repository.listDomains();
      _domains = domains;

      if (_domains.isNotEmpty) {
        final hasExistingSelection =
            _selectedDomain != null &&
            _domains.any((domain) => domain.id == _selectedDomain!.id);

        if (!hasExistingSelection) {
          _selectedDomain = _domains.first;
        }
      } else {
        _selectedDomain = null;
      }
    } on AuthFailure catch (failure) {
      if (failure.type == AuthFailureType.invalidToken ||
          failure.type == AuthFailureType.insufficientPermissions) {
        _domains = const [];
        _selectedDomain = null;
        _authFailure = failure;
        _errorMessage = null;
      } else {
        _errorMessage = AppStrings.domainLoadError;
      }
    } catch (_) {
      _errorMessage = AppStrings.domainLoadError;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectDomain(DomainSummary domain) {
    _selectedDomain = domain;
    notifyListeners();
  }

  void clearSelection() {
    _domains = const [];
    _selectedDomain = null;
    _errorMessage = null;
    _isLoading = false;
    _authFailure = null;
    notifyListeners();
  }
}
