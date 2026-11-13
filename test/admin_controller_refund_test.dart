// test/controller/admin_controller_refund_test.dart
//
// Unit tests ของ AdminController.refunds() และ decideRefund()
// ใช้ MockClient จึงไม่ต้องมี backend จริง
//
// รัน: flutter test test/controller/admin_controller_refund_test.dart
// ต้องมี `http` ใน pubspec.yaml อยู่แล้ว (ApiClient ใช้อยู่)

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uni_swap/controller/admin_controller.dart';
import 'package:uni_swap/controller/api_client.dart';

void main() {
  late http.Request? captured;

  /// สร้าง controller ที่ตอบกลับด้วย [status]/[body] และเก็บ request ล่าสุดไว้ตรวจ
  AdminController build({
    int status = 200,
    Object body = const {'success': true},
    String? token,
    bool rawBody = false,
  }) {
    captured = null;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        rawBody ? body as String : jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = ApiClient(
      client: client,
      baseUrl: 'http://test.local/api/',
      tokenProvider: () => token,
    );
    return AdminController(api);
  }

  group('refunds()', () {
    // ทดสอบที่ 1: ตรวจสอบว่าการเรียก refunds() โดยไม่ส่งพารามิเตอร์ จะส่งคำขอ GET
    // พร้อมค่าเริ่มต้น (status=pending, page=1, limit=20) และแปลงข้อมูลผลลัพธ์ได้ถูกต้อง
    test(
      'GET admin/refunds พร้อมค่าเริ่มต้น status=pending page=1 limit=20',
      () async {
        final controller = build(
          body: {
            'data': [
              {'refund_id': 1},
            ],
            'page': 1,
            'limit': 20,
            'has_more': false,
          },
        );

        final result = await controller.refunds();

        expect(captured!.method, 'GET');
        expect(captured!.url.path, '/api/admin/refunds');
        expect(captured!.url.queryParameters, {
          'status': 'pending',
          'page': '1',
          'limit': '20',
        });
        expect(captured!.body, isEmpty);
        expect(captured!.headers['accept'], 'application/json');
        expect(result['data'], hasLength(1));
        expect(result['has_more'], false);
      },
    );

    // ทดสอบที่ 2: ตรวจสอบว่าการส่งค่า status, page และ limit แบบกำหนดเอง
    // จะถูกส่งไปเป็น query parameters ใน URL อย่างถูกต้อง
    test('ส่ง status, page, limit ตามที่กำหนด', () async {
      final controller = build();

      await controller.refunds(status: 'completed', page: 3, limit: 50);

      expect(captured!.url.queryParameters, {
        'status': 'completed',
        'page': '3',
        'limit': '50',
      });
    });

    // ทดสอบที่ 3: ตรวจสอบว่าจะมีการแนบ Header 'Authorization: Bearer' ไปกับคำขอเมื่อมี token
    test('แนบ Authorization: Bearer เมื่อมี token', () async {
      final controller = build(token: 'abc123');

      await controller.refunds();

      expect(captured!.headers['authorization'], 'Bearer abc123');
    });

    // ทดสอบที่ 4: ตรวจสอบว่าจะไม่มีการส่ง Header 'Authorization' เมื่อไม่มี token (เป็น null)
    test('ไม่ส่ง Authorization เมื่อไม่มี token', () async {
      final controller = build(token: null);

      await controller.refunds();

      expect(captured!.headers.containsKey('authorization'), isFalse);
    });

    // ทดสอบที่ 5: ตรวจสอบว่าเมื่อเซิร์ฟเวอร์ตอบกลับด้วยสถานะ 403 Forbidden
    // จะโยน ApiException พร้อมข้อความแจ้งเตือนจากเซิร์ฟเวอร์และรหัสสถานะ 403
    test('โยน ApiException พร้อมข้อความจาก server เมื่อ 403', () async {
      final controller = build(
        status: 403,
        body: {'success': false, 'message': 'Admin access required'},
      );

      expect(
        controller.refunds(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Admin access required')
              .having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });
  });

  group('decideRefund()', () {
    // ทดสอบที่ 6: ตรวจสอบว่าการอนุมัติคำขอคืนเงิน (approve) จะส่งคำขอ PUT ไปที่ /api/admin/refunds/:id
    // พร้อม JSON body {"action": "approve"} และคืนค่าผลลัพธ์สำเร็จ
    test(
      'approve: PUT admin/refunds/:id พร้อม body {action: approve}',
      () async {
        final controller = build();

        final result = await controller.decideRefund(7, action: 'approve');

        expect(captured!.method, 'PUT');
        expect(captured!.url.path, '/api/admin/refunds/7');
        expect(captured!.url.queryParameters, isEmpty);
        expect(captured!.headers['content-type'], contains('application/json'));
        expect(jsonDecode(captured!.body), {'action': 'approve'});
        expect(result['success'], true);
      },
    );

    // ทดสอบที่ 7: ตรวจสอบว่าการปฏิเสธคำขอคืนเงิน (reject) จะส่งคำขอ PUT ไปยัง ID เป้าหมาย
    // พร้อม JSON body {"action": "reject"}
    test('reject: ส่ง action เป็น reject', () async {
      final controller = build();

      await controller.decideRefund(12, action: 'reject');

      expect(captured!.url.path, '/api/admin/refunds/12');
      expect(jsonDecode(captured!.body), {'action': 'reject'});
    });

    // ทดสอบที่ 8: ตรวจสอบว่า decideRefund() จะแนบ Header 'Authorization: Bearer' เมื่อมี token
    test('แนบ Authorization: Bearer เมื่อมี token', () async {
      final controller = build(token: 'tok');

      await controller.decideRefund(1, action: 'approve');

      expect(captured!.headers['authorization'], 'Bearer tok');
    });

    // ทดสอบที่ 9: ตรวจสอบว่าเมื่อเซิร์ฟเวอร์ตอบกลับด้วยสถานะ 409 Conflict (รายการคืนเงินถูกตัดสินไปแล้ว)
    // จะโยน ApiException พร้อมข้อความแจ้งเตือนและรหัสสถานะ 409
    test('โยน ApiException เมื่อ refund ถูกตัดสินไปแล้ว (409)', () async {
      final controller = build(
        status: 409,
        body: {'success': false, 'message': 'Refund already handled'},
      );

      expect(
        controller.decideRefund(7, action: 'approve'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Refund already handled')
              .having((e) => e.statusCode, 'statusCode', 409),
        ),
      );
    });

    // ทดสอบที่ 10: ตรวจสอบว่าเมื่อการตอบกลับผิดพลาดไม่มีฟิลด์ 'message' (เช่น Error 500)
    // ApiClient จะใช้ข้อความสำรอง 'Request failed (500).' ในการโยน ApiException
    test('ใช้ข้อความสำรองเมื่อ error ไม่มี message', () async {
      final controller = build(status: 500, body: {'success': false});

      expect(
        controller.decideRefund(7, action: 'reject'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Request failed (500).',
          ),
        ),
      );
    });

    // ทดสอบที่ 11: ตรวจสอบว่าเมื่อได้รับข้อมูลตอบกลับที่ไม่ใช่รูปแบบ JSON (เช่น โค้ด HTML)
    // จะโยน ApiException แจ้งว่าเซิร์ฟเวอร์ส่งข้อมูลกลับมาไม่ถูกต้อง
    test('โยน ApiException เมื่อ response ไม่ใช่ JSON', () async {
      final controller = build(
        status: 200,
        body: '<html>oops</html>',
        rawBody: true,
      );

      expect(
        controller.decideRefund(7, action: 'approve'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'The server returned an invalid response.',
          ),
        ),
      );
    });

    // ทดสอบที่ 12: ตรวจสอบว่าเมื่อเกิดข้อผิดพลาดในการเชื่อมต่อเครือข่าย (ClientException)
    // ระบบจะจับข้อผิดพลาดและโยน ApiException แจ้งว่าไม่สามารถติดต่อเซิร์ฟเวอร์ได้
    test('โยน ApiException เมื่อเชื่อมต่อ server ไม่ได้', () async {
      final api = ApiClient(
        client: MockClient((_) async => throw http.ClientException('refused')),
        baseUrl: 'http://test.local/api',
      );
      final controller = AdminController(api);

      expect(
        controller.refunds(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Could not reach the server'),
          ),
        ),
      );
    });
  });
}
