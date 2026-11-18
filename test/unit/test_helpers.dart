import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uni_swap/controller/api_client.dart';

/// request ที่ controller ส่งออกไป (บันทึกไว้ให้เทสต์ตรวจ)
class RecordedCall {
  RecordedCall({
    required this.method,
    required this.path,
    required this.query,
    required this.body,
    required this.headers,
  });

  final String method;
  final String path;
  final Map<String, String> query;
  final Map<String, dynamic>? body;
  final Map<String, String> headers;

  /// เช่น `PUT /api/admin/users/5/status`
  String get label => '$method $path';
}

/// สร้าง [ApiClient] ที่ไม่ต่อ server จริง
///
/// - ทุก request ถูกเก็บลง [calls]
/// - server ปลอมตอบ [response] (ถูกแปลงเป็น JSON) พร้อม status [status]
ApiClient fakeApi(
  List<RecordedCall> calls, {
  int status = 200,
  Object? response = const {'success': true},
  String? Function()? tokenProvider,
}) {
  return ApiClient(
    tokenProvider: tokenProvider,
    client: MockClient((request) async {
      calls.add(
        RecordedCall(
          method: request.method,
          path: request.url.path,
          query: request.url.queryParameters,
          body: request.body.isEmpty
              ? null
              : jsonDecode(request.body) as Map<String, dynamic>,
          headers: request.headers,
        ),
      );
      return http.Response(jsonEncode(response), status);
    }),
  );
}
