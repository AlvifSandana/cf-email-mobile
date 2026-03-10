import 'dart:async';

import 'package:bariskode_cf_email/core/constants/app_strings.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/domains/data/domain_repository.dart';
import 'package:bariskode_cf_email/features/domains/data/selected_domain_store.dart';
import 'package:bariskode_cf_email/features/domains/domain/entities/domain_summary.dart';
import 'package:flutter/foundation.dart';

class DomainContext extends ChangeNotifier {
  DomainContext({
    required DomainRepositoryContract repository,
    SelectedDomainStoreContract? selectedDomainStore,
  }) : _repository = repository,
       _selectedDomainStore =
           selectedDomainStore ?? const NoopSelectedDomainStore();

  final DomainRepositoryContract _repository;
  final SelectedDomainStoreContract _selectedDomainStore;

  List<DomainSummary> _domains = const [];
  DomainSummary? _selectedDomain;
  bool _isLoading = false;
  String? _errorMessage;
  AuthFailure? _authFailure;
  Future<void> _storeOperationQueue = Future<void>.value();

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
        String? persistedDomainId;
        try {
          persistedDomainId = await _selectedDomainStore.readSelectedDomainId();
        } catch (_) {
          persistedDomainId = null;
        }

        final hasExistingSelection =
            _selectedDomain != null &&
            _domains.any((domain) => domain.id == _selectedDomain!.id);
        DomainSummary? persistedSelection;
        if (persistedDomainId != null) {
          for (final domain in _domains) {
            if (domain.id == persistedDomainId) {
              persistedSelection = domain;
              break;
            }
          }
        }

        if (hasExistingSelection) {
          _persistSelectedDomain(_selectedDomain!);
        } else if (persistedSelection != null) {
          _selectedDomain = persistedSelection;
        } else {
          _selectedDomain = _domains.first;
          await _enqueueStoreOperation(() async {
            await _selectedDomainStore.saveSelectedDomainId(
              _selectedDomain!.id,
            );
          });
        }
      } else {
        _selectedDomain = null;
        await _enqueueStoreOperation(() async {
          await _selectedDomainStore.clearSelectedDomainId();
        });
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
    _persistSelectedDomain(domain);
    notifyListeners();
  }

  void clearSelection() {
    _domains = const [];
    _selectedDomain = null;
    _errorMessage = null;
    _isLoading = false;
    _authFailure = null;
    _clearPersistedSelection();
    notifyListeners();
  }

  void _persistSelectedDomain(DomainSummary domain) {
    unawaited(
      _enqueueStoreOperation(() async {
        await _selectedDomainStore.saveSelectedDomainId(domain.id);
      }),
    );
  }

  void _clearPersistedSelection() {
    unawaited(
      _enqueueStoreOperation(() async {
        await _selectedDomainStore.clearSelectedDomainId();
      }),
    );
  }

  Future<void> _enqueueStoreOperation(Future<void> Function() operation) {
    _storeOperationQueue = _storeOperationQueue.then((_) async {
      try {
        await operation();
      } catch (_) {}
    });

    return _storeOperationQueue;
  }
}
