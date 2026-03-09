abstract class SessionStore {
  Future<void> saveToken(String token);

  Future<String?> readToken();

  Future<void> clearToken();
}
