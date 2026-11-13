import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

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

  /// Uploads an image from memory. Uses bytes (not a file path) so it also
  /// works on Flutter web, where MultipartFile.fromPath is unsupported.
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fileField,
    required List<int> bytes,
    required String fileName,
    String? mimeType,
    Map<String, String> fields = const {},
  }) async {
    final uri = Uri.parse('$baseUrl/${path.replaceFirst(RegExp(r'^/+'), '')}');
    final request = http.MultipartRequest('POST', uri)
      ..headers['accept'] = 'application/json'
      ..fields.addAll(fields)
      ..files.add(
        http.MultipartFile.fromBytes(
          fileField,
          bytes,
          filename: fileName,
          contentType: _imageType(fileName, mimeType),
        ),
      );
    final token = tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      request.headers['authorization'] = 'Bearer $token';
    }

    late http.Response response;
    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 20));
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException('The server took too long to respond.');
    } on http.ClientException catch (error) {
      throw ApiException('Could not reach the server: ${error.message}');
    }
    return _decodeResponse(response);
  }

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

    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
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

  // app.js only accepts image/jpeg, image/png and image/webp.
  MediaType _imageType(String fileName, String? mimeType) {
    const allowed = {'image/jpeg', 'image/png', 'image/webp'};
    if (mimeType != null && allowed.contains(mimeType.toLowerCase())) {
      final parts = mimeType.toLowerCase().split('/');
      return MediaType(parts[0], parts[1]);
    }
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
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
