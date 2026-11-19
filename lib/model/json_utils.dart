/// ตัวช่วยอ่านค่าจาก JSON ของ API
///
/// MySQL ส่ง DECIMAL มาเป็น string (เช่น `"12.50"`) และส่งวันที่มาเป็น
/// ISO-8601 string ดังนั้น model ไม่ควร cast ตรง ๆ แต่ควรใช้ helper เหล่านี้
/// เพื่อให้รับได้ทั้งค่าปกติและค่าแบบ string
library;

int? jsonInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim());
}

double? jsonDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim());
}

String? jsonString(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

bool? jsonBool(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;

  return switch (value.toString().trim().toLowerCase()) {
    'true' || '1' => true,
    'false' || '0' => false,
    _ => null,
  };
}

/// อ่านวันที่และแปลงเป็นเวลาท้องถิ่น (API ส่ง UTC มาเป็น ISO-8601)
DateTime? jsonDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();

  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text)?.toLocal();
}

Map<String, dynamic> jsonObject(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> jsonObjectList(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];

  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

List<T> jsonParseList<T>(
  Object? value,
  T Function(Map<String, dynamic> json) parser,
) {
  return jsonObjectList(value).map(parser).toList(growable: false);
}
