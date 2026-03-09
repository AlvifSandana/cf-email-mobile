import 'package:bariskode_cf_email/core/network/auth_header_provider.dart';
import 'package:bariskode_cf_email/features/auth/domain/services/session_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('merges authorization header when token exists', () async {
    final provider = AuthHeaderProvider(FakeSessionStore(' token-123 '));

    final headers = await provider.buildHeaders(
      baseHeaders: {'Content-Type': 'application/json'},
    );

    expect(headers['Content-Type'], 'application/json');
    expect(headers['Authorization'], 'Bearer token-123');
  });

  test('does not add authorization header when token is missing', () async {
    final provider = AuthHeaderProvider(FakeSessionStore(null));

    final headers = await provider.buildHeaders();

    expect(headers.containsKey('Authorization'), isFalse);
  });
}

class FakeSessionStore implements SessionStore {
  FakeSessionStore(this.token);

  final String? token;

  @override
  Future<void> clearToken() async {}

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String token) async {}
}
