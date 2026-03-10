import 'dart:convert';

import 'package:bariskode_cf_email/core/network/api_client.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/destinations/domain/entities/destination_email.dart';
import 'package:bariskode_cf_email/shared/models/api_exception.dart';
import 'package:http/http.dart' as http;

class DestinationRepository implements DestinationRepositoryContract {
  const DestinationRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<DestinationEmail>> listDestinations({
    required String accountId,
  }) async {
    final response = await _performListRequest(accountId);
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
            return DestinationEmail.fromApi(item);
          } on FormatException {
            throw const AuthFailure.network();
          }
        })
        .toList(growable: false);
  }

  @override
  Future<DestinationEmail> createDestination({
    required String accountId,
    required String email,
  }) async {
    final response = await _performCreateRequest(
      accountId: accountId,
      email: email,
    );
    _validateResponse(response);
    final body = _parseBody(response);
    final result = body['result'];

    if (result is! Map<String, dynamic>) {
      throw const AuthFailure.network();
    }

    try {
      return DestinationEmail.fromApi(result);
    } on FormatException {
      throw const AuthFailure.network();
    }
  }

  Future<http.Response> _performListRequest(String accountId) async {
    try {
      return await apiClient.get(
        Uri.parse(
          'https://api.cloudflare.com/client/v4/accounts/$accountId/email/routing/addresses',
        ),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (_) {
      throw const AuthFailure.network();
    }
  }

  Future<http.Response> _performCreateRequest({
    required String accountId,
    required String email,
  }) async {
    try {
      return await apiClient.post(
        Uri.parse(
          'https://api.cloudflare.com/client/v4/accounts/$accountId/email/routing/addresses',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
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
      throw ApiException(
        _extractErrorMessage(body) ?? 'Destination request failed.',
      );
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

abstract class DestinationRepositoryContract {
  Future<List<DestinationEmail>> listDestinations({required String accountId});

  Future<DestinationEmail> createDestination({
    required String accountId,
    required String email,
  });
}
