import 'enums.dart';
import 'json_utils.dart';

/// แถวในตาราง `users` (ไม่รวม `password_hash` เพราะไม่ควรเข้ามาฝั่งแอป)
///
/// ใช้ได้กับ response ของ `/api/login`, `/api/profile` และ
/// `/api/admin/users` โดย field ที่เป็น join (`residence_name`) จะเป็น null
/// ถ้า endpoint นั้นไม่ได้ส่งมา
class User {
  const User({
    required this.id,
    required this.studentId,
    required this.username,
    required this.email,
    required this.displayName,
    this.residenceZone,
    this.residenceLocationId,
    this.residenceName,
    this.role = UserRole.member,
    this.status = UserStatus.pending,
    this.verifiedBy,
    this.verifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: jsonInt(json['user_id'] ?? json['id']) ?? 0,
      studentId: jsonString(json['student_id']) ?? '',
      username: jsonString(json['username']) ?? '',
      email: jsonString(json['email']) ?? '',
      displayName: jsonString(json['display_name']) ?? '',
      residenceZone: ResidenceZone.tryParse(json['residence_zone']),
      residenceLocationId: jsonInt(json['residence_location_id']),
      residenceName: jsonString(json['residence_name']),
      role: UserRole.fromApi(json['role']),
      status: UserStatus.fromApi(json['status']),
      verifiedBy: jsonInt(json['verified_by']),
      verifiedAt: jsonDateTime(json['verified_at']),
      createdAt: jsonDateTime(json['created_at']),
      updatedAt: jsonDateTime(json['updated_at']),
    );
  }

  final int id; // users.user_id
  final String studentId; // users.student_id
  final String username; // users.username
  final String email; // users.email
  final String displayName; // users.display_name
  final ResidenceZone? residenceZone; // users.residence_zone
  final int? residenceLocationId; // users.residence_location_id
  final String? residenceName; // locations.name (join)
  final UserRole role; // users.role
  final UserStatus status; // users.status
  final int? verifiedBy; // users.verified_by
  final DateTime? verifiedAt; // users.verified_at
  final DateTime? createdAt; // users.created_at
  final DateTime? updatedAt; // users.updated_at

  bool get isAdmin => role == UserRole.admin;
  bool get isActive => status == UserStatus.active;

  /// ตัวอักษรย่อสำหรับ avatar เช่น "Maya Demo" -> "MD"
  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'student_id': studentId,
      'username': username,
      'email': email,
      'display_name': displayName,
      'residence_zone': residenceZone?.apiValue,
      'residence_location_id': residenceLocationId,
      'residence_name': residenceName,
      'role': role.apiValue,
      'status': status.apiValue,
      'verified_by': verifiedBy,
      'verified_at': verifiedAt?.toUtc().toIso8601String(),
      'created_at': createdAt?.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }
}
