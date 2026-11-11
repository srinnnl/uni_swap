import 'package:flutter/foundation.dart';
import '../model/enums.dart';
import '../controller/api_client.dart';

/// Authentication/profile state. Token is kept in memory during this sprint.
/// ใช้ร่วมกันทั้ง member และ admin (แยกด้วย role ที่ server ส่งมา)
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

  /// role ที่ไม่รู้จัก/ไม่มี จะถือเป็น member (สิทธิ์ต่ำสุด)
  UserRole get role => UserRole.fromApi(_user?['role']);
  bool get isAdmin => isAuthenticated && role == UserRole.admin;

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
      final token = result['token']?.toString();
      // เช็ก token ก่อนเซ็ต state ใดๆ จะได้ไม่มี user ค้างโดยไม่มี token
      if (token == null || token.isEmpty) {
        throw const ApiException('The login response did not contain a token.');
      }
      _token = token;
      _user = _asMap(result['user']);
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
