/// Enum ที่ตรงกับ MySQL ENUM ของตารางใน `project_mobile_app`
///
/// `apiValue` คือค่าที่ backend ส่งมา/รับไป จึงใช้ได้ทั้ง `fromJson` และ `toJson`
library;

T? _tryParse<T>(List<T> values, Object? raw, String Function(T) wireValue) {
  if (raw == null) return null;
  final value = raw is String ? raw : raw.toString();
  for (final item in values) {
    if (wireValue(item) == value) return item;
  }
  return null;
}

/// users.residence_zone, locations.zone, products.zone
enum ResidenceZone {
  onCampus('on_campus'),
  offCampus('off_campus');

  const ResidenceZone(this.apiValue);
  final String apiValue;

  static ResidenceZone? tryParse(Object? value) =>
      _tryParse(values, value, (zone) => zone.apiValue);

  static ResidenceZone fromApi(Object? value) => tryParse(value) ?? onCampus;
}

/// users.role
enum UserRole {
  member('member'),
  admin('admin');

  const UserRole(this.apiValue);
  final String apiValue;

  static UserRole? tryParse(Object? value) =>
      _tryParse(values, value, (role) => role.apiValue);

  static UserRole fromApi(Object? value) => tryParse(value) ?? member;
}

/// users.status
enum UserStatus {
  pending('pending'),
  active('active'),
  suspended('suspended'),
  rejected('rejected');

  const UserStatus(this.apiValue);
  final String apiValue;

  static UserStatus? tryParse(Object? value) =>
      _tryParse(values, value, (status) => status.apiValue);

  static UserStatus fromApi(Object? value) => tryParse(value) ?? pending;
}

/// location_requests.status
enum LocationRequestStatus {
  pending('pending'),
  reviewing('reviewing'),
  approved('approved'),
  merged('merged'),
  rejected('rejected');

  const LocationRequestStatus(this.apiValue);
  final String apiValue;

  static LocationRequestStatus? tryParse(Object? value) =>
      _tryParse(values, value, (status) => status.apiValue);

  static LocationRequestStatus fromApi(Object? value) =>
      tryParse(value) ?? pending;
}

/// products.item_condition
enum ItemCondition {
  brandNew('new'),
  likeNew('like_new'),
  good('good'),
  fair('fair');

  const ItemCondition(this.apiValue);
  final String apiValue;

  static ItemCondition? tryParse(Object? value) =>
      _tryParse(values, value, (condition) => condition.apiValue);

  static ItemCondition? fromApi(Object? value) => tryParse(value);
}

/// products.urgency_level
enum UrgencyLevel {
  normal('normal'),
  urgent('urgent'),
  veryUrgent('very_urgent');

  const UrgencyLevel(this.apiValue);
  final String apiValue;

  static UrgencyLevel? tryParse(Object? value) =>
      _tryParse(values, value, (level) => level.apiValue);

  static UrgencyLevel fromApi(Object? value) => tryParse(value) ?? normal;
}

/// products.reject_reason
enum RejectReason {
  prohibitedItem('prohibited_item'),
  misleading('misleading'),
  poorPhotos('poor_photos'),
  duplicate('duplicate'),
  other('other');

  const RejectReason(this.apiValue);
  final String apiValue;

  static RejectReason? tryParse(Object? value) =>
      _tryParse(values, value, (reason) => reason.apiValue);

  static RejectReason? fromApi(Object? value) => tryParse(value);
}

/// มุมมองของออเดอร์จาก `/api/orders`
enum OrderPerspective {
  buying('buying'),
  selling('selling');

  const OrderPerspective(this.apiValue);
  final String apiValue;

  static OrderPerspective? tryParse(Object? value) =>
      _tryParse(values, value, (perspective) => perspective.apiValue);

  static OrderPerspective? fromApi(Object? value) => tryParse(value);
}

/// payments.payment_method
enum PaymentMethod {
  gateway('gateway'),
  bankTransfer('bank_transfer'),
  cash('cash'),
  free('free');

  const PaymentMethod(this.apiValue);
  final String apiValue;

  static PaymentMethod? tryParse(Object? value) =>
      _tryParse(values, value, (method) => method.apiValue);

  static PaymentMethod fromApi(Object? value) => tryParse(value) ?? gateway;
}

/// payments.payment_status
enum PaymentStatus {
  pending('pending'),
  processing('processing'),
  paid('paid'),
  failed('failed');

  const PaymentStatus(this.apiValue);
  final String apiValue;

  static PaymentStatus? tryParse(Object? value) =>
      _tryParse(values, value, (status) => status.apiValue);

  static PaymentStatus fromApi(Object? value) => tryParse(value) ?? pending;
}

/// payments.seller_transfer_status
enum SellerTransferStatus {
  notReady('not_ready'),
  pending('pending'),
  processing('processing'),
  paid('paid'),
  failed('failed'),
  held('held');

  const SellerTransferStatus(this.apiValue);
  final String apiValue;

  static SellerTransferStatus? tryParse(Object? value) =>
      _tryParse(values, value, (status) => status.apiValue);

  static SellerTransferStatus fromApi(Object? value) =>
      tryParse(value) ?? notReady;
}
