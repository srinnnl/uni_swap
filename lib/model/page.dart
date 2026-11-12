import 'json_utils.dart';

/// Response แบบแบ่งหน้าของ API:
/// `{ success, data, page, limit, has_more }`
class ApiPage<T> {
  const ApiPage({
    required this.data,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory ApiPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) itemFromJson,
  ) {
    final data = jsonParseList(json['data'], itemFromJson);
    return ApiPage<T>(
      data: data,
      page: jsonInt(json['page']) ?? 1,
      limit: jsonInt(json['limit']) ?? data.length,
      hasMore: jsonBool(json['has_more']) ?? false,
    );
  }

  final List<T> data;
  final int page;
  final int limit;
  final bool hasMore;

  bool get isEmpty => data.isEmpty;
  bool get isNotEmpty => data.isNotEmpty;

  Map<String, dynamic> toJson(
    Map<String, dynamic> Function(T item) itemToJson,
  ) {
    return {
      'data': data.map(itemToJson).toList(growable: false),
      'page': page,
      'limit': limit,
      'has_more': hasMore,
    };
  }
}
