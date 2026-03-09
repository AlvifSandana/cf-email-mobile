import 'package:bariskode_cf_email/features/auth/domain/services/session_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthLocalDataSource implements SessionStore {
  AuthLocalDataSource(this._storage);

  static const _tokenKey = 'cloudflare_api_token';

  final FlutterSecureStorage _storage;

  @override
  Future<void> clearToken() {
    return _storage.delete(key: _tokenKey);
  }

  @override
  Future<String?> readToken() {
    return _storage.read(key: _tokenKey);
  }

  @override
  Future<void> saveToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }
}
