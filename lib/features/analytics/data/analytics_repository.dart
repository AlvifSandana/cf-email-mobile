import 'dart:convert';

import 'package:bariskode_cf_email/core/network/api_client.dart';
import 'package:bariskode_cf_email/features/analytics/domain/entities/activity_log_entry.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/shared/models/api_exception.dart';
import 'package:http/http.dart' as http;

class AnalyticsRepository implements AnalyticsRepositoryContract {
  const AnalyticsRepository({required this.apiClient});

  static final Uri _graphqlUri = Uri.parse(
    'https://api.cloudflare.com/client/v4/graphql',
  );

  static const String _activityQuery = r'''
query EmailRoutingActivity($zoneTag: String!, $limit: Int!) {
  viewer {
    zones(filter: { zoneTag: $zoneTag }) {
      emailRouting: emailRoutingAnalyticsAdaptiveGroups(
        limit: $limit
        orderBy: [datetime_DESC]
      ) {
        dimensions {
          datetime
          emailTo
          action
          spf
          dkim
          dmarc
        }
      }
    }
  }
}
''';

  final ApiClient apiClient;

  @override
  Future<List<ActivityLogEntry>> listActivityLogs({
    required String zoneId,
    int limit = 20,
  }) async {
    final safeLimit = limit.clamp(1, 100);
    final response = await _performActivityRequest(
      zoneId: zoneId,
      limit: safeLimit,
    );
    final body = _parseBody(response);
    _validateResponse(response, body);
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const AuthFailure.network();
    }

    final viewer = data['viewer'];
    if (viewer is! Map<String, dynamic>) {
      throw const AuthFailure.network();
    }

    final zones = viewer['zones'];
    if (zones is! List || zones.isEmpty) {
      return const [];
    }

    final zone = zones.first;
    if (zone is! Map<String, dynamic>) {
      throw const AuthFailure.network();
    }

    final groups = zone['emailRouting'];
    if (groups is! List) {
      throw const AuthFailure.network();
    }

    final entries = <ActivityLogEntry>[];
    for (final item in groups) {
      final parsedEntry = _tryParseEntry(item);
      if (parsedEntry != null) {
        entries.add(parsedEntry);
      }
    }

    return List<ActivityLogEntry>.unmodifiable(entries);
  }

  Future<http.Response> _performActivityRequest({
    required String zoneId,
    required int limit,
  }) async {
    try {
      return await apiClient.post(
        _graphqlUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': _activityQuery,
          'variables': {'zoneTag': zoneId, 'limit': limit},
        }),
      );
    } catch (_) {
      throw const AuthFailure.network();
    }
  }

  void _validateResponse(http.Response response, Map<String, dynamic> body) {
    if (response.statusCode == 401) {
      throw const AuthFailure.invalidToken();
    }

    if (response.statusCode == 403) {
      throw const AuthFailure.insufficientPermissions();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const AuthFailure.network();
    }

    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      final authFailure = _extractAuthFailure(errors);
      if (authFailure != null) {
        throw authFailure;
      }

      throw ApiException(
        _extractErrorMessage(errors) ?? 'Activity request failed.',
      );
    }
  }

  ActivityLogEntry? _tryParseEntry(Object? item) {
    if (item is! Map<String, dynamic>) {
      return null;
    }

    final dimensions = item['dimensions'];
    if (dimensions is! Map<String, dynamic>) {
      return null;
    }

    final timestampValue = dimensions['datetime'];
    final address = dimensions['emailTo'];
    final status = dimensions['action'];
    final spf = dimensions['spf'];
    final dkim = dimensions['dkim'];
    final dmarc = dimensions['dmarc'];

    if (timestampValue is! String ||
        address is! String ||
        status is! String ||
        spf is! String ||
        dkim is! String ||
        dmarc is! String ||
        address.isEmpty) {
      return null;
    }

    final timestamp = DateTime.tryParse(timestampValue);
    if (timestamp == null) {
      return null;
    }

    return ActivityLogEntry(
      address: address.toLowerCase(),
      status: status,
      spf: spf,
      dkim: dkim,
      dmarc: dmarc,
      timestamp: timestamp,
    );
  }

  AuthFailure? _extractAuthFailure(List<dynamic> errors) {
    for (final error in errors) {
      if (error is! Map<String, dynamic>) {
        continue;
      }

      final extensions = error['extensions'];
      final code = extensions is Map<String, dynamic>
          ? extensions['code']
          : null;
      final message = error['message'];
      final normalizedCode = code is String ? code.toLowerCase() : '';
      final normalizedMessage = message is String ? message.toLowerCase() : '';

      if (normalizedCode.contains('permission') ||
          normalizedCode.contains('forbidden') ||
          normalizedMessage.contains('insufficient permission') ||
          normalizedMessage.contains('permission denied') ||
          normalizedMessage.contains('forbidden') ||
          normalizedMessage.contains('not authorized')) {
        return const AuthFailure.insufficientPermissions();
      }

      if (normalizedCode.contains('unauth') ||
          normalizedCode.contains('authn') ||
          normalizedCode.contains('invalid_token') ||
          normalizedMessage.contains('invalid token') ||
          normalizedMessage.contains('authentication') ||
          normalizedMessage.contains('unauthorized') ||
          normalizedMessage.contains('token expired')) {
        return const AuthFailure.invalidToken();
      }
    }

    return null;
  }

  String? _extractErrorMessage(List<dynamic> errors) {
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

abstract class AnalyticsRepositoryContract {
  Future<List<ActivityLogEntry>> listActivityLogs({
    required String zoneId,
    int limit,
  });
}
