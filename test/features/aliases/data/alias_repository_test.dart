import 'dart:convert';

import 'package:bariskode_cf_email/core/network/api_client.dart';
import 'package:bariskode_cf_email/core/network/auth_header_provider.dart';
import 'package:bariskode_cf_email/features/aliases/data/alias_repository.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/auth/domain/services/session_store.dart';
import 'package:bariskode_cf_email/shared/models/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('listAliases requests rules endpoint for selected zone', () async {
    final client = RecordingHttpClient(
      response: http.Response(
        jsonEncode({
          'success': true,
          'result': [
            {
              'id': 'rule-1',
              'enabled': true,
              'matchers': [
                {
                  'type': 'literal',
                  'field': 'to',
                  'value': 'hello@example.com',
                },
              ],
              'actions': [
                {
                  'type': 'forward',
                  'value': ['dest@example.net'],
                },
              ],
            },
          ],
        }),
        200,
      ),
    );
    final repository = AliasRepository(
      apiClient: ApiClient(
        client: client,
        headers: AuthHeaderProvider(FakeSessionStore()),
      ),
    );

    final aliases = await repository.listAliases(zoneId: 'zone-123');

    expect(
      client.lastRequest?.url.path,
      '/client/v4/zones/zone-123/email/routing/rules',
    );
    expect(client.lastRequest?.headers['Authorization'], 'Bearer token-123');
    expect(aliases.single.address, 'hello@example.com');
  });

  test('listAliases maps 401 to invalid token', () async {
    final repository = AliasRepository(
      apiClient: ApiClient(
        client: RecordingHttpClient(response: http.Response('{}', 401)),
        headers: AuthHeaderProvider(FakeSessionStore()),
      ),
    );

    expect(
      repository.listAliases(zoneId: 'zone-123'),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.type,
          'type',
          AuthFailureType.invalidToken,
        ),
      ),
    );
  });

  test('listAliases maps malformed payload to network failure', () async {
    final repository = AliasRepository(
      apiClient: ApiClient(
        client: RecordingHttpClient(response: http.Response('not-json', 200)),
        headers: AuthHeaderProvider(FakeSessionStore()),
      ),
    );

    expect(
      repository.listAliases(zoneId: 'zone-123'),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.type,
          'type',
          AuthFailureType.network,
        ),
      ),
    );
  });

  test('listAliases maps 403 to insufficient permissions', () async {
    final repository = AliasRepository(
      apiClient: ApiClient(
        client: RecordingHttpClient(response: http.Response('{}', 403)),
        headers: AuthHeaderProvider(FakeSessionStore()),
      ),
    );

    expect(
      repository.listAliases(zoneId: 'zone-123'),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.type,
          'type',
          AuthFailureType.insufficientPermissions,
        ),
      ),
    );
  });

  test(
    'listAliases does not map non-auth API failure to invalid token',
    () async {
      final repository = AliasRepository(
        apiClient: ApiClient(
          client: RecordingHttpClient(
            response: http.Response(
              jsonEncode({
                'success': false,
                'errors': [
                  {'message': 'rule engine temporarily unavailable'},
                ],
              }),
              200,
            ),
          ),
          headers: AuthHeaderProvider(FakeSessionStore()),
        ),
      );

      expect(
        repository.listAliases(zoneId: 'zone-123'),
        throwsA(isNot(isA<AuthFailure>())),
      );
    },
  );

  test('createAlias posts matcher and destination payload', () async {
    final client = RecordingHttpClient(
      response: http.Response(
        jsonEncode({
          'success': true,
          'result': {
            'id': 'rule-2',
            'enabled': true,
            'matchers': [
              {'type': 'literal', 'field': 'to', 'value': 'sales@example.com'},
            ],
            'actions': [
              {
                'type': 'forward',
                'value': ['dest@example.net'],
              },
            ],
          },
        }),
        200,
      ),
    );
    final repository = AliasRepository(
      apiClient: ApiClient(
        client: client,
        headers: AuthHeaderProvider(FakeSessionStore()),
      ),
    );

    final createdAlias = await repository.createAlias(
      zoneId: 'zone-123',
      aliasAddress: 'sales@example.com',
      destination: 'dest@example.net',
    );

    expect(client.lastRequest?.method, 'POST');
    expect(
      client.lastRequest?.url.path,
      '/client/v4/zones/zone-123/email/routing/rules',
    );
    expect(client.lastRequest?.headers['Authorization'], 'Bearer token-123');

    final request = client.lastRequest! as http.Request;
    final payload = jsonDecode(request.body) as Map<String, dynamic>;
    expect(payload['enabled'], isTrue);
    expect(payload['matchers'][0]['value'], 'sales@example.com');
    expect(payload['actions'][0]['value'][0], 'dest@example.net');
    expect(createdAlias.address, 'sales@example.com');
  });

  test('createAlias maps 403 to insufficient permissions', () async {
    final repository = AliasRepository(
      apiClient: ApiClient(
        client: RecordingHttpClient(response: http.Response('{}', 403)),
        headers: AuthHeaderProvider(FakeSessionStore()),
      ),
    );

    expect(
      repository.createAlias(
        zoneId: 'zone-123',
        aliasAddress: 'sales@example.com',
        destination: 'dest@example.net',
      ),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.type,
          'type',
          AuthFailureType.insufficientPermissions,
        ),
      ),
    );
  });

  test('createAlias surfaces non-auth API failure message', () async {
    final repository = AliasRepository(
      apiClient: ApiClient(
        client: RecordingHttpClient(
          response: http.Response(
            jsonEncode({
              'success': false,
              'errors': [
                {'message': 'Alias already exists.'},
              ],
            }),
            200,
          ),
        ),
        headers: AuthHeaderProvider(FakeSessionStore()),
      ),
    );

    expect(
      repository.createAlias(
        zoneId: 'zone-123',
        aliasAddress: 'sales@example.com',
        destination: 'dest@example.net',
      ),
      throwsA(
        isA<ApiException>().having(
          (exception) => exception.message,
          'message',
          'Alias already exists.',
        ),
      ),
    );
  });

  test(
    'updateAlias puts destination payload and preserves enabled state',
    () async {
      final client = RecordingHttpClient(
        response: http.Response(
          jsonEncode({
            'success': true,
            'result': {
              'id': 'rule-2',
              'enabled': false,
              'matchers': [
                {
                  'type': 'literal',
                  'field': 'to',
                  'value': 'sales@example.com',
                },
              ],
              'actions': [
                {
                  'type': 'forward',
                  'value': ['edited@example.net'],
                },
              ],
            },
          }),
          200,
        ),
      );
      final repository = AliasRepository(
        apiClient: ApiClient(
          client: client,
          headers: AuthHeaderProvider(FakeSessionStore()),
        ),
      );

      final updatedAlias = await repository.updateAlias(
        zoneId: 'zone-123',
        ruleId: 'rule-2',
        aliasAddress: 'sales@example.com',
        destination: 'edited@example.net',
        isEnabled: false,
      );

      expect(client.lastRequest?.method, 'PUT');
      expect(
        client.lastRequest?.url.path,
        '/client/v4/zones/zone-123/email/routing/rules/rule-2',
      );

      final request = client.lastRequest! as http.Request;
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      expect(payload['enabled'], isFalse);
      expect(payload['matchers'][0]['value'], 'sales@example.com');
      expect(payload['actions'][0]['value'][0], 'edited@example.net');
      expect(updatedAlias.destination, 'edited@example.net');
      expect(updatedAlias.isEnabled, isFalse);
    },
  );

  test('updateAlias maps 401 to invalid token', () async {
    final repository = AliasRepository(
      apiClient: ApiClient(
        client: RecordingHttpClient(response: http.Response('{}', 401)),
        headers: AuthHeaderProvider(FakeSessionStore()),
      ),
    );

    expect(
      repository.updateAlias(
        zoneId: 'zone-123',
        ruleId: 'rule-2',
        aliasAddress: 'sales@example.com',
        destination: 'edited@example.net',
        isEnabled: true,
      ),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.type,
          'type',
          AuthFailureType.invalidToken,
        ),
      ),
    );
  });

  test('updateAlias maps 403 to insufficient permissions', () async {
    final repository = AliasRepository(
      apiClient: ApiClient(
        client: RecordingHttpClient(response: http.Response('{}', 403)),
        headers: AuthHeaderProvider(FakeSessionStore()),
      ),
    );

    expect(
      repository.updateAlias(
        zoneId: 'zone-123',
        ruleId: 'rule-2',
        aliasAddress: 'sales@example.com',
        destination: 'edited@example.net',
        isEnabled: true,
      ),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.type,
          'type',
          AuthFailureType.insufficientPermissions,
        ),
      ),
    );
  });

  test('updateAlias surfaces non-auth API failure message', () async {
    final repository = AliasRepository(
      apiClient: ApiClient(
        client: RecordingHttpClient(
          response: http.Response(
            jsonEncode({
              'success': false,
              'errors': [
                {'message': 'Destination already used.'},
              ],
            }),
            200,
          ),
        ),
        headers: AuthHeaderProvider(FakeSessionStore()),
      ),
    );

    expect(
      repository.updateAlias(
        zoneId: 'zone-123',
        ruleId: 'rule-2',
        aliasAddress: 'sales@example.com',
        destination: 'edited@example.net',
        isEnabled: true,
      ),
      throwsA(
        isA<ApiException>().having(
          (exception) => exception.message,
          'message',
          'Destination already used.',
        ),
      ),
    );
  });

  test('deleteAlias calls delete endpoint for selected rule', () async {
    final client = RecordingHttpClient(
      response: http.Response(
        jsonEncode({
          'success': true,
          'result': {'id': 'rule-2'},
        }),
        200,
      ),
    );
    final repository = AliasRepository(
      apiClient: ApiClient(
        client: client,
        headers: AuthHeaderProvider(FakeSessionStore()),
      ),
    );

    await repository.deleteAlias(zoneId: 'zone-123', ruleId: 'rule-2');

    expect(client.lastRequest?.method, 'DELETE');
    expect(
      client.lastRequest?.url.path,
      '/client/v4/zones/zone-123/email/routing/rules/rule-2',
    );
    expect(client.lastRequest?.headers['Authorization'], 'Bearer token-123');
  });

  test('deleteAlias maps 401 to invalid token', () async {
    final repository = AliasRepository(
      apiClient: ApiClient(
        client: RecordingHttpClient(response: http.Response('{}', 401)),
        headers: AuthHeaderProvider(FakeSessionStore()),
      ),
    );

    expect(
      repository.deleteAlias(zoneId: 'zone-123', ruleId: 'rule-2'),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.type,
          'type',
          AuthFailureType.invalidToken,
        ),
      ),
    );
  });

  test('deleteAlias maps 403 to insufficient permissions', () async {
    final repository = AliasRepository(
      apiClient: ApiClient(
        client: RecordingHttpClient(response: http.Response('{}', 403)),
        headers: AuthHeaderProvider(FakeSessionStore()),
      ),
    );

    expect(
      repository.deleteAlias(zoneId: 'zone-123', ruleId: 'rule-2'),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.type,
          'type',
          AuthFailureType.insufficientPermissions,
        ),
      ),
    );
  });

  test('deleteAlias surfaces non-auth API failure message', () async {
    final repository = AliasRepository(
      apiClient: ApiClient(
        client: RecordingHttpClient(
          response: http.Response(
            jsonEncode({
              'success': false,
              'errors': [
                {'message': 'Alias could not be deleted.'},
              ],
            }),
            200,
          ),
        ),
        headers: AuthHeaderProvider(FakeSessionStore()),
      ),
    );

    expect(
      repository.deleteAlias(zoneId: 'zone-123', ruleId: 'rule-2'),
      throwsA(
        isA<ApiException>().having(
          (exception) => exception.message,
          'message',
          'Alias could not be deleted.',
        ),
      ),
    );
  });
}

class RecordingHttpClient extends http.BaseClient {
  RecordingHttpClient({required this.response});

  final http.Response response;
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
