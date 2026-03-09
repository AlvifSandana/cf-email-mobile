import 'package:bariskode_cf_email/features/auth/domain/services/session_store.dart';

class AuthHeaderProvider {
  const AuthHeaderProvider(this.sessionStore);

  final SessionStore sessionStore;

  Future<Map<String, String>> buildHeaders({
    Map<String, String>? baseHeaders,
  }) async {
    final headers = <String, String>{...?baseHeaders};
    final token = (await sessionStore.readToken())?.trim();

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
}
