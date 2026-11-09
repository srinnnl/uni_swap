import 'enums.dart';
import 'json_utils.dart';

/// แถวในตาราง `locations` (ที่พัก/จุดรับของที่ admin อนุมัติแล้ว)
class Location {
  const Location({
    required this.id,
    required this.zone,
    required this.name,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: jsonInt(json['location_id'] ?? json['id']) ?? 0,
      zone: ResidenceZone.fromApi(json['zone']),
      name: jsonString(json['name']) ?? '',
      isActive: jsonBool(json['is_active']) ?? true,
      createdAt: jsonDateTime(json['created_at']),
      updatedAt: jsonDateTime(json['updated_at']),
    );
  }

  final int id; // locations.location_id
  final ResidenceZone zone; // locations.zone
  final String name; // locations.name
  final bool isActive; // locations.is_active
  final DateTime? createdAt; // locations.created_at
  final DateTime? updatedAt; // locations.updated_at

  Map<String, dynamic> toJson() {
    return {
      'location_id': id,
      'zone': zone.apiValue,
      'name': name,
      'is_active': isActive,
      'created_at': createdAt?.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }
}

/// แถวในตาราง `location_requests` (คำขอเพิ่มที่พักที่ยังไม่มีในระบบ)
class LocationRequest {
  const LocationRequest({
    required this.id,
    required this.userId,
    required this.name,
    required this.zone,
    this.address,
    this.reason,
    this.status = LocationRequestStatus.pending,
    this.approvedLocationId,
    this.mergedIntoLocationId,
    this.handledBy,
    this.requesterName,
    this.requesterUsername,
    this.createdAt,
    this.resolvedAt,
  });

  factory LocationRequest.fromJson(Map<String, dynamic> json) {
    return LocationRequest(
      id: jsonInt(json['request_id'] ?? json['id']) ?? 0,
      userId: jsonInt(json['user_id']) ?? 0,
      name: jsonString(json['name']) ?? '',
      zone: ResidenceZone.fromApi(json['zone']),
      address: jsonString(json['address']),
      reason: jsonString(json['reason']),
      status: LocationRequestStatus.fromApi(json['status']),
      approvedLocationId: jsonInt(json['approved_location_id']),
      mergedIntoLocationId: jsonInt(json['merged_into_location_id']),
      handledBy: jsonInt(json['handled_by']),
      requesterName: jsonString(json['requester_name']),
      requesterUsername: jsonString(json['username']),
      createdAt: jsonDateTime(json['created_at']),
      resolvedAt: jsonDateTime(json['resolved_at']),
    );
  }

  final int id; // location_requests.request_id
  final int userId; // location_requests.user_id
  final String name; // location_requests.name
  final ResidenceZone zone; // location_requests.zone
  final String? address; // location_requests.address
  final String? reason; // location_requests.reason
  final LocationRequestStatus status; // location_requests.status
  final int? approvedLocationId; // location_requests.approved_location_id
  final int? mergedIntoLocationId; // location_requests.merged_into_location_id
  final int? handledBy; // location_requests.handled_by
  final String? requesterName; // users.display_name (join)
  final String? requesterUsername; // users.username (join)
  final DateTime? createdAt; // location_requests.created_at
  final DateTime? resolvedAt; // location_requests.resolved_at

  bool get isOpen =>
      status == LocationRequestStatus.pending ||
      status == LocationRequestStatus.reviewing;

  Map<String, dynamic> toJson() {
    return {
      'request_id': id,
      'user_id': userId,
      'name': name,
      'zone': zone.apiValue,
      'address': address,
      'reason': reason,
      'status': status.apiValue,
      'approved_location_id': approvedLocationId,
      'merged_into_location_id': mergedIntoLocationId,
      'handled_by': handledBy,
      'requester_name': requesterName,
      'username': requesterUsername,
      'created_at': createdAt?.toUtc().toIso8601String(),
      'resolved_at': resolvedAt?.toUtc().toIso8601String(),
    };
  }
}
