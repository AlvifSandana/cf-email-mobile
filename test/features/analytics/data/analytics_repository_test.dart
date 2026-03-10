import 'dart:convert';

import 'package:bariskode_cf_email/core/network/api_client.dart';
import 'package:bariskode_cf_email/core/network/auth_header_provider.dart';
import 'package:bariskode_cf_email/features/analytics/data/analytics_repository.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/auth/domain/services/session_store.dart';
import 'package:bariskode_cf_email/shared/models/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('AnalyticsRepository', () {
    test('returns mapped activity logs from GraphQL response', () async {
      final rawClient = RecordingHttpClient(
        response: http.Response(
          jsonEncode({
            'data': {
              'viewer': {
                'zones': [
                  {
                    'emailRouting': [
                      {
                        'dimensions': {
                          'datetime': '2026-03-09T10:15:00Z',
                          'emailTo': 'Sales@Example.com',
                          'action': 'forwarded',
                          'spf': 'pass',
                          'dkim': 'pass',
                          'dmarc': 'none',
                        },
                      },
                    ],
                  },
                ],
              },
            },
          }),
          200,
        ),
      );
      final repository = AnalyticsRepository(
        apiClient: ApiClient(
          client: rawClient,
          headers: AuthHeaderProvider(FakeSessionStore()),
        ),
      );

      final result = await repository.listActivityLogs(zoneId: 'zone-1');

      expect(result.entries, hasLength(1));
      expect(result.entries.single.address, 'sales@example.com');
      expect(result.entries.single.status, 'forwarded');
      expect(result.entries.single.spf, 'pass');
      expect(result.entries.single.dkim, 'pass');
      expect(result.entries.single.dmarc, 'none');
      expect(
        result.entries.single.timestamp,
        DateTime.parse('2026-03-09T10:15:00Z'),
      );
      expect(result.hasMore, isFalse);
      expect(result.nextBefore, isNull);
      expect(
        rawClient.lastRequest?.url.toString(),
        'https://api.cloudflare.com/client/v4/graphql',
      );
      expect(
        rawClient.lastRequest?.headers['Authorization'],
        'Bearer token-123',
      );
    });

    test('returns empty list when zone has no analytics rows', () async {
      final repository = AnalyticsRepository(
        apiClient: ApiClient(
          client: RecordingHttpClient(
            response: http.Response(
              jsonEncode({
                'data': {
                  'viewer': {
                    'zones': [
                      {'emailRouting': []},
                    ],
                  },
                },
              }),
              200,
            ),
          ),
          headers: AuthHeaderProvider(FakeSessionStore()),
        ),
      );

      final result = await repository.listActivityLogs(zoneId: 'zone-1');
      expect(result.entries, isEmpty);
      expect(result.hasMore, isFalse);
    });

    test('maps 401 to invalid token', () async {
      final repository = AnalyticsRepository(
        apiClient: ApiClient(
          client: RecordingHttpClient(response: http.Response('{}', 401)),
          headers: AuthHeaderProvider(FakeSessionStore()),
        ),
      );

      await expectLater(
        repository.listActivityLogs(zoneId: 'zone-1'),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.type,
            'type',
            AuthFailureType.invalidToken,
          ),
        ),
      );
    });

    test('maps 403 to insufficient permissions', () async {
      final repository = AnalyticsRepository(
        apiClient: ApiClient(
          client: RecordingHttpClient(response: http.Response('{}', 403)),
          headers: AuthHeaderProvider(FakeSessionStore()),
        ),
      );

      await expectLater(
        repository.listActivityLogs(zoneId: 'zone-1'),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.type,
            'type',
            AuthFailureType.insufficientPermissions,
          ),
        ),
      );
    });

    test('maps malformed payload to network failure', () async {
      final repository = AnalyticsRepository(
        apiClient: ApiClient(
          client: RecordingHttpClient(response: http.Response('not-json', 200)),
          headers: AuthHeaderProvider(FakeSessionStore()),
        ),
      );

      await expectLater(
        repository.listActivityLogs(zoneId: 'zone-1'),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.type,
            'type',
            AuthFailureType.network,
          ),
        ),
      );
    });

    test('maps GraphQL errors to ApiException', () async {
      final repository = AnalyticsRepository(
        apiClient: ApiClient(
          client: RecordingHttpClient(
            response: http.Response(
              jsonEncode({
                'data': {
                  'viewer': {'zones': []},
                },
                'errors': [
                  {'message': 'GraphQL request failed.'},
                ],
              }),
              200,
            ),
          ),
          headers: AuthHeaderProvider(FakeSessionStore()),
        ),
      );

      await expectLater(
        repository.listActivityLogs(zoneId: 'zone-1'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'GraphQL request failed.',
          ),
        ),
      );
    });

    test('maps GraphQL unauthorized errors to invalid token', () async {
      final repository = AnalyticsRepository(
        apiClient: ApiClient(
          client: RecordingHttpClient(
            response: http.Response(
              jsonEncode({
                'data': {
                  'viewer': {'zones': []},
                },
                'errors': [
                  {
                    'message': 'Unauthorized: token expired.',
                    'extensions': {'code': 'UNAUTHENTICATED'},
                  },
                ],
              }),
              200,
            ),
          ),
          headers: AuthHeaderProvider(FakeSessionStore()),
        ),
      );

      await expectLater(
        repository.listActivityLogs(zoneId: 'zone-1'),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.type,
            'type',
            AuthFailureType.invalidToken,
          ),
        ),
      );
    });

    test('skips malformed rows when other rows are valid', () async {
      final repository = AnalyticsRepository(
        apiClient: ApiClient(
          client: RecordingHttpClient(
            response: http.Response(
              jsonEncode({
                'data': {
                  'viewer': {
                    'zones': [
                      {
                        'emailRouting': [
                          {
                            'dimensions': {
                              'datetime': '2026-03-09T10:15:00Z',
                              'emailTo': 'sales@example.com',
                              'action': 'forwarded',
                              'spf': 'pass',
                              'dkim': 'pass',
                              'dmarc': 'none',
                            },
                          },
                          {
                            'dimensions': {
                              'datetime': 'invalid',
                              'emailTo': '',
                              'action': 'forwarded',
                              'spf': 'pass',
                              'dkim': 'pass',
                              'dmarc': 'none',
                            },
                          },
                        ],
                      },
                    ],
                  },
                },
              }),
              200,
            ),
          ),
          headers: AuthHeaderProvider(FakeSessionStore()),
        ),
      );

      final result = await repository.listActivityLogs(zoneId: 'zone-1');

      expect(result.entries, hasLength(1));
      expect(result.entries.single.address, 'sales@example.com');
    });
  });
}

class RecordingHttpClient extends http.BaseClient {
  RecordingHttpClient({http.Response? response})
    : response = response ?? http.Response('{}', 200);

  http.Response response;
  http.BaseRequest? lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }
}

class FakeSessionStore implements SessionStore {
  @override
  Future<void> clearToken() async {}

  @override
  Future<String?> readToken() async => 'token-123';

  @override
  Future<void> saveToken(String token) async {}
}
