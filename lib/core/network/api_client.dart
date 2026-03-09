import 'package:bariskode_cf_email/core/network/auth_header_provider.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static const _requestTimeout = Duration(seconds: 15);

  ApiClient({required http.Client client, required AuthHeaderProvider headers})
    : _client = client,
      _headers = headers;

  final http.Client _client;
  final AuthHeaderProvider _headers;

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final mergedHeaders = await _headers.buildHeaders(baseHeaders: headers);
    return _client.get(url, headers: mergedHeaders).timeout(_requestTimeout);
  }

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final mergedHeaders = await _headers.buildHeaders(baseHeaders: headers);
    return _client
        .post(url, headers: mergedHeaders, body: body)
        .timeout(_requestTimeout);
  }

  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final mergedHeaders = await _headers.buildHeaders(baseHeaders: headers);
    return _client
        .put(url, headers: mergedHeaders, body: body)
        .timeout(_requestTimeout);
  }

  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final mergedHeaders = await _headers.buildHeaders(baseHeaders: headers);
    return _client
        .delete(url, headers: mergedHeaders, body: body)
        .timeout(_requestTimeout);
  }
}
