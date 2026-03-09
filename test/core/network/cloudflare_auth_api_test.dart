import 'dart:convert';

import 'package:bariskode_cf_email/core/network/api_client.dart';
import 'package:bariskode_cf_email/core/network/auth_header_provider.dart';
import 'package:bariskode_cf_email/core/network/cloudflare_auth_api.dart';
import 'package:bariskode_cf_email/features/auth/domain/entities/auth_failure.dart';
import 'package:bariskode_cf_email/features/auth/domain/services/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('validateToken passes on successful response', () async {
    final api = CloudflareAuthApi(
      client: RecordingHttpClient(
        response: http.Response(
          jsonEncode({'success': true, 'result': []}),
          200,
        ),
      ),
    );

    await api.validateToken('token-123');
  });

  test('validateToken maps 401 to invalid token', () async {
    final api = CloudflareAuthApi(
      client: RecordingHttpClient(response: http.Response('{}', 401)),
    );

    expect(api.validateToken('token-123'), throwsA(isA<AuthFailure>()));
  });

  test('validateToken maps 403 to insufficient permissions', () async {
    final api = CloudflareAuthApi(
      client: RecordingHttpClient(response: http.Response('{}', 403)),
    );

    expect(
      api.validateToken('token-123'),
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
    'validateToken maps malformed response body to network failure',
    () async {
      final api = CloudflareAuthApi(
        client: RecordingHttpClient(response: http.Response('not-json', 200)),
      );

      expect(
        api.validateToken('token-123'),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.type,
            'type',
            AuthFailureType.network,
          ),
        ),
      );
    },
  );

  test('fetchZones returns parsed domains', () async {
    final rawClient = RecordingHttpClient();
    final api = CloudflareAuthApi(client: rawClient);
    final apiClient = ApiClient(
      client: rawClient
        ..response = http.Response(
          jsonEncode({
            'success': true,
            'result': [
              {'id': '1', 'name': 'example.com'},
              {'id': '2', 'name': 'startup.io'},
            ],
          }),
          200,
        ),
      headers: AuthHeaderProvider(FakeSessionStore()),
    );

    final zones = await api.fetchZones(apiClient);

    expect(zones.length, 2);
    expect(zones.first.name, 'example.com');
    expect(zones.last.id, '2');
    expect(rawClient.lastRequest?.url.path, '/client/v4/zones');
    expect(rawClient.lastRequest?.url.queryParameters['per_page'], isNull);
    expect(rawClient.lastRequest?.headers['Authorization'], 'Bearer token-123');
  });

  test('fetchZones maps 401 to invalid token', () async {
    final api = CloudflareAuthApi(client: RecordingHttpClient());
    final apiClient = ApiClient(
      client: RecordingHttpClient()..response = http.Response('{}', 401),
      headers: AuthHeaderProvider(FakeSessionStore()),
    );

    expect(
      api.fetchZones(apiClient),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.type,
          'type',
          AuthFailureType.invalidToken,
        ),
      ),
    );
  });

  test('fetchZones maps 403 to insufficient permissions', () async {
    final api = CloudflareAuthApi(client: RecordingHttpClient());
    final apiClient = ApiClient(
      client: RecordingHttpClient()..response = http.Response('{}', 403),
      headers: AuthHeaderProvider(FakeSessionStore()),
    );

    expect(
      api.fetchZones(apiClient),
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
    'fetchZones maps malformed success response to network failure',
    () async {
      final api = CloudflareAuthApi(client: RecordingHttpClient());
      final apiClient = ApiClient(
        client: RecordingHttpClient()
          ..response = http.Response('not-json', 200),
        headers: AuthHeaderProvider(FakeSessionStore()),
      );

      expect(
        api.fetchZones(apiClient),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.type,
            'type',
            AuthFailureType.network,
          ),
        ),
      );
    },
  );

  test('fetchZones maps invalid payload to network failure', () async {
    final api = CloudflareAuthApi(client: RecordingHttpClient());
    final apiClient = ApiClient(
      client: RecordingHttpClient(
        response: http.Response(
          jsonEncode({
            'success': true,
            'result': [
              {'id': '1'},
            ],
          }),
          200,
        ),
      ),
      headers: AuthHeaderProvider(FakeSessionStore()),
    );

    expect(
      api.fetchZones(apiClient),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.type,
          'type',
          AuthFailureType.network,
        ),
      ),
    );
  });

  test('fetchZones maps transport errors to network failure', () async {
    final api = CloudflareAuthApi(client: RecordingHttpClient());
    final apiClient = ApiClient(
      client: ThrowingHttpClient(),
      headers: AuthHeaderProvider(FakeSessionStore()),
    );

    expect(
      api.fetchZones(apiClient),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.type,
          'type',
          AuthFailureType.network,
        ),
      ),
    );
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

class ThrowingHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw Exception('network down');
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
