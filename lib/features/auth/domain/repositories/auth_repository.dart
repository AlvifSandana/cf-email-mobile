abstract class AuthRepository {
  Future<bool> hasValidSession();

  Future<void> loginWithToken(String token);

  Future<void> logout();

  Future<String?> readToken();
}
