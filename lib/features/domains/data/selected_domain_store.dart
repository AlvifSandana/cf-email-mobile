import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SelectedDomainStoreContract {
  Future<void> saveSelectedDomainId(String domainId);

  Future<String?> readSelectedDomainId();

  Future<void> clearSelectedDomainId();
}

class SelectedDomainStore implements SelectedDomainStoreContract {
  SelectedDomainStore(this._storage);

  static const _selectedDomainKey = 'selected_domain_id';

  final FlutterSecureStorage _storage;

  @override
  Future<void> clearSelectedDomainId() {
    return _storage.delete(key: _selectedDomainKey);
  }

  @override
  Future<String?> readSelectedDomainId() {
    return _storage.read(key: _selectedDomainKey);
  }

  @override
  Future<void> saveSelectedDomainId(String domainId) {
    return _storage.write(key: _selectedDomainKey, value: domainId);
  }
}

class NoopSelectedDomainStore implements SelectedDomainStoreContract {
  const NoopSelectedDomainStore();

  @override
  Future<void> clearSelectedDomainId() async {}

  @override
  Future<String?> readSelectedDomainId() async => null;

  @override
  Future<void> saveSelectedDomainId(String domainId) async {}
}
