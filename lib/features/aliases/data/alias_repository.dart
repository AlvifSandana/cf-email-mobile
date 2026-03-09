import 'dart:convert';

import 'package:bariskode_cf_email/core/network/api_client.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/shared/models/api_exception.dart';
import 'package:bariskode_cf_email/shared/models/alias_model.dart';
import 'package:http/http.dart' as http;

class AliasRepository implements AliasRepositoryContract {
  const AliasRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<AliasModel>> listAliases({required String zoneId}) async {
    final response = await _performListRequest(zoneId);
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

          try {
            return AliasModel.fromApi(item);
          } on FormatException {
            throw const AuthFailure.network();
          }
        })
        .toList(growable: false);
  }

  @override
  Future<AliasModel> createAlias({
    required String zoneId,
    required String aliasAddress,
    required String destination,
  }) async {
    final response = await _performCreateRequest(
      zoneId: zoneId,
      aliasAddress: aliasAddress,
      destination: destination,
    );
    _validateResponse(response);

    final body = _parseBody(response);
    final result = body['result'];

    if (result is! Map<String, dynamic>) {
      throw const AuthFailure.network();
    }

    try {
      return AliasModel.fromApi(result);
    } on FormatException {
      throw const AuthFailure.network();
    }
  }

  @override
  Future<AliasModel> updateAlias({
    required String zoneId,
    required String ruleId,
    required String aliasAddress,
    required String destination,
    required bool isEnabled,
  }) async {
    final response = await _performUpdateRequest(
      zoneId: zoneId,
      ruleId: ruleId,
      aliasAddress: aliasAddress,
      destination: destination,
      isEnabled: isEnabled,
    );
    _validateResponse(response);

    final body = _parseBody(response);
    final result = body['result'];

    if (result is! Map<String, dynamic>) {
      throw const AuthFailure.network();
    }

    try {
      return AliasModel.fromApi(result);
    } on FormatException {
      throw const AuthFailure.network();
    }
  }

  @override
  Future<void> deleteAlias({
    required String zoneId,
    required String ruleId,
  }) async {
    final response = await _performDeleteRequest(
      zoneId: zoneId,
      ruleId: ruleId,
    );
    _validateResponse(response);
  }

  Future<http.Response> _performListRequest(String zoneId) async {
    try {
      return await apiClient.get(
        Uri.parse(
          'https://api.cloudflare.com/client/v4/zones/$zoneId/email/routing/rules',
        ),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (_) {
      throw const AuthFailure.network();
    }
  }

  Future<http.Response> _performCreateRequest({
    required String zoneId,
    required String aliasAddress,
    required String destination,
  }) async {
    try {
      return await apiClient.post(
        Uri.parse(
          'https://api.cloudflare.com/client/v4/zones/$zoneId/email/routing/rules',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'matchers': [
            {'type': 'literal', 'field': 'to', 'value': aliasAddress},
          ],
          'actions': [
            {
              'type': 'forward',
              'value': [destination],
            },
          ],
          'enabled': true,
        }),
      );
    } catch (_) {
      throw const AuthFailure.network();
    }
  }

  Future<http.Response> _performUpdateRequest({
    required String zoneId,
    required String ruleId,
    required String aliasAddress,
    required String destination,
    required bool isEnabled,
  }) async {
    try {
      return await apiClient.put(
        Uri.parse(
          'https://api.cloudflare.com/client/v4/zones/$zoneId/email/routing/rules/$ruleId',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'matchers': [
            {'type': 'literal', 'field': 'to', 'value': aliasAddress},
          ],
          'actions': [
            {
              'type': 'forward',
              'value': [destination],
            },
          ],
          'enabled': isEnabled,
        }),
      );
    } catch (_) {
      throw const AuthFailure.network();
    }
  }

  Future<http.Response> _performDeleteRequest({
    required String zoneId,
    required String ruleId,
  }) async {
    try {
      return await apiClient.delete(
        Uri.parse(
          'https://api.cloudflare.com/client/v4/zones/$zoneId/email/routing/rules/$ruleId',
        ),
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
    if (body['success'] != true) {
      throw ApiException(_extractErrorMessage(body) ?? 'Alias request failed.');
    }
  }

  String? _extractErrorMessage(Map<String, dynamic> body) {
    final errors = body['errors'];

    if (errors is! List) {
      return null;
    }

    for (final error in errors) {
      if (error is! Map<String, dynamic>) {
        continue;
      }

      final message = error['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    return null;
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

abstract class AliasRepositoryContract {
  Future<List<AliasModel>> listAliases({required String zoneId});

  Future<AliasModel> createAlias({
    required String zoneId,
    required String aliasAddress,
    required String destination,
  });

  Future<AliasModel> updateAlias({
    required String zoneId,
    required String ruleId,
    required String aliasAddress,
    required String destination,
    required bool isEnabled,
  });

  Future<void> deleteAlias({required String zoneId, required String ruleId});
}
