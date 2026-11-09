import 'json_utils.dart';
import 'user.dart';

/// Response ของ `POST /api/login`
class AuthSession {
  const AuthSession({required this.token, required this.user});

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: jsonString(json['token']) ?? '',
      user: User.fromJson(jsonObject(json['user'])),
    );
  }

  final String token; // JWT (ใช้ใน header Authorization: Bearer <token>)
  final User user;

  bool get isValid => token.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {'token': token, 'user': user.toJson()};
  }
}
