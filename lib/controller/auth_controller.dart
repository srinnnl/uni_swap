import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Authentication/profile state. Token is kept in memory during this sprint.
class AuthController extends ChangeNotifier {
  AuthController(this._api);
  final ApiClient _api;
  String? _token;
  Map<String, dynamic>? _user;
  bool _busy = false;

  String? get token => _token;
  Map<String, dynamic>? get user =>
      _user == null ? null : Map.unmodifiable(_user!);
  bool get isAuthenticated => _token != null;
  bool get isBusy => _busy;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    _setBusy(true);
    try {
      final result = await _api.post(
        'login',
        body: {'email': email.trim(), 'password': password},
      );
      _token = result['token']?.toString();
      _user = _asMap(result['user']);
      if (_token == null) {
        throw const ApiException('The login response did not contain a token.');
      }
      notifyListeners();
      return result;
    } finally {
      _setBusy(false);
    }
  }

  Future<Map<String, dynamic>> register(Map<String, Object?> details) async {
    _setBusy(true);
    try {
      return await _api.post('register', body: details);
    } finally {
      _setBusy(false);
    }
  }

  Future<Map<String, dynamic>> loadProfile() async {
    final result = await _api.get('profile');
    _user = _asMap(result['data']);
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> updateProfile(
    Map<String, Object?> changes,
  ) async {
    final result = await _api.put('profile', body: changes);
    await loadProfile();
    return result;
  }

  void signOut() {
    _token = null;
    _user = null;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}

Map<String, dynamic>? _asMap(Object? value) =>
    value is Map<String, dynamic> ? value : null;
