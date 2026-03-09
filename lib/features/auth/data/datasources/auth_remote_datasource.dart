import 'package:bariskode_cf_email/core/network/api_client.dart';
import 'package:bariskode_cf_email/core/network/cloudflare_auth_api.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource({
    required CloudflareAuthApi authApi,
    required ApiClient apiClient,
  }) : _authApi = authApi,
       _apiClient = apiClient;

  final CloudflareAuthApi _authApi;
  final ApiClient _apiClient;

  Future<void> validateToken(String token) {
    return _authApi.validateToken(token);
  }

  Future<void> validateStoredSession() {
    return _authApi.validateCurrentSession(_apiClient);
  }
}
