import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// HTTP client for the Express API in the repository root.
///
/// Override API_BASE_URL with `--dart-define=API_BASE_URL=...` when the device
/// cannot reach localhost (for Android emulator use http://10.0.2.2:3000/api).
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl, this.tokenProvider})
    : _client = client ?? http.Client(),
      baseUrl =
          (baseUrl ??
                  const String.fromEnvironment(
                    'API_BASE_URL',
                    defaultValue: 'http://localhost:3000/api',
                  ))
              .replaceFirst(RegExp(r'/+$'), '');

  final http.Client _client;
  final String baseUrl;
  final String? Function()? tokenProvider;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, Object?> query = const {},
  }) => _send('GET', path, query: query);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, Object?> body = const {},
  }) => _send('POST', path, body: body);

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, Object?> body = const {},
  }) => _send('PUT', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, Object?> query = const {},
    Map<String, Object?>? body,
  }) async {
    final uri = Uri.parse('$baseUrl/${path.replaceFirst(RegExp(r'^/+'), '')}')
        .replace(
          queryParameters: {
            ...query.map(
              (key, value) => MapEntry(key, value?.toString() ?? ''),
            ),
          }..removeWhere((_, value) => value.isEmpty),
        );
    final headers = <String, String>{'accept': 'application/json'};
    if (body != null) headers['content-type'] = 'application/json';
    final token = tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['authorization'] = 'Bearer $token';
    }

    late http.Response response;
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 20));
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException('The server took too long to respond.');
    } on http.ClientException catch (error) {
      throw ApiException('Could not reach the server: ${error.message}');
    }

    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(response.body);
      data = decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    } on FormatException {
      throw ApiException(
        'The server returned an invalid response.',
        response.statusCode,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['message']?.toString() ??
            'Request failed (${response.statusCode}).',
        response.statusCode,
        data,
      );
    }
    return data;
  }

  @visibleForTesting
  void close() => _client.close();
}

class ApiException implements Exception {
  const ApiException(this.message, [this.statusCode, this.details]);
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? details;
  @override
  String toString() => message;
}
