import 'package:bariskode_cf_email/core/network/api_client.dart';
import 'dart:convert';

import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/domains/domain/entities/domain_summary.dart';
import 'package:http/http.dart' as http;

class CloudflareAuthApi {
  CloudflareAuthApi({required http.Client client}) : _client = client;

  static const _requestTimeout = Duration(seconds: 15);

  final http.Client _client;

  static final _zonesUri = Uri.parse(
    'https://api.cloudflare.com/client/v4/zones',
  );

  Future<void> validateToken(String token) async {
    final response = await _performRawValidation(token);
    _validateResponse(response);
  }

  Future<void> validateCurrentSession(ApiClient apiClient) async {
    final response = await _performAuthenticatedRequest(apiClient);

    _validateResponse(response);
  }

  Future<List<DomainSummary>> fetchZones(ApiClient apiClient) async {
    final response = await _performAuthenticatedRequest(apiClient);
    _validateResponse(response);

    final body = _parseBody(response);
    final result = body['result'];

    if (result is! List) {
      throw const AuthFailure.network();
    }

    return result
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const AuthFailure.network();
          }

          final id = item['id'];
          final name = item['name'];
          final account = item['account'];
          final accountId = account is Map<String, dynamic>
              ? account['id']
              : null;

          if (id is! String ||
              name is! String ||
              accountId is! String ||
              id.isEmpty ||
              name.isEmpty ||
              accountId.isEmpty) {
            throw const AuthFailure.network();
          }

          return DomainSummary(id: id, name: name, accountId: accountId);
        })
        .toList(growable: false);
  }

  Future<http.Response> _performRawValidation(String token) async {
    http.Response response;

    try {
      response = await _client
          .get(
            _zonesUri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(_requestTimeout);
    } catch (_) {
      throw const AuthFailure.network();
    }

    return response;
  }

  Future<http.Response> _performAuthenticatedRequest(
    ApiClient apiClient,
  ) async {
    try {
      return await apiClient.get(
        _zonesUri,
        headers: {'Content-Type': 'application/json'},
      );
    } catch (_) {
      throw const AuthFailure.network();
    }
  }

  void _validateResponse(http.Response response) {
    if (response.statusCode == 401) {
      throw const AuthFailure.invalidToken();
    }

    if (response.statusCode == 403) {
      throw const AuthFailure.insufficientPermissions();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const AuthFailure.network();
    }

    final body = _parseBody(response);
    final success = body['success'];

    if (success != true) {
      throw const AuthFailure.invalidToken();
    }
  }

  Map<String, dynamic> _parseBody(http.Response response) {
    try {
      final body = jsonDecode(response.body);

      if (body is! Map<String, dynamic>) {
        throw const AuthFailure.network();
      }

      return body;
    } catch (_) {
      throw const AuthFailure.network();
    }
  }
}
