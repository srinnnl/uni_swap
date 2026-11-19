import 'package:flutter/foundation.dart';

/// API server address. For a physical phone, pass the computer's LAN URL with
/// --dart-define=API_BASE_URL=http://<computer-ip>:3000/api.
String defaultApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000/api';
  }
  return 'http://localhost:3000/api';
}

/// Resolves relative uploads and rewrites old local-host URLs to the configured
/// API server so saved images work on web, emulator, and physical devices.
String? resolveMediaUrl(String? value, {String? apiBaseUrl}) {
  if (value == null || value.trim().isEmpty) return value;

  final mediaUri = Uri.tryParse(value.trim());
  if (mediaUri == null) return value;

  final apiUri = Uri.parse(apiBaseUrl ?? defaultApiBaseUrl());
  final serverPath = apiUri.path.replaceFirst(RegExp(r'/api/?$'), '');
  final serverUri = apiUri.replace(
    path: serverPath,
    query: '',
    fragment: '',
  );

  if (!mediaUri.hasScheme || mediaUri.host.isEmpty) {
    return serverUri.resolveUri(mediaUri).toString();
  }

  final host = mediaUri.host.toLowerCase().replaceAll('[', '').replaceAll(']', '');
  final isLocalHost =
      host == 'localhost' ||
      host == '10.0.2.2' ||
      host == '0.0.0.0' ||
      host == '::1' ||
      host.startsWith('127.');
  if (!isLocalHost) return value;

  return serverUri
      .replace(
        path: mediaUri.path,
        query: mediaUri.hasQuery ? mediaUri.query : '',
        fragment: mediaUri.hasFragment ? mediaUri.fragment : '',
      )
      .toString();
}
