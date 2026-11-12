import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uni_swap/controller/api_client.dart';

import 'test_helpers.dart';

void main() {
  late List<RecordedCall> calls;

  setUp(() => calls = []);

  group('การสร้าง URL', () {
    test('ตัด / ท้าย baseUrl ออก', () {
      final api = ApiClient(baseUrl: 'http://example.test/api///');
      expect(api.baseUrl, 'http://example.test/api');
      api.close();
    });

    test('baseUrl ตั้งต้นชี้ไปที่ localhost:3000', () {
      final api = ApiClient();
      expect(api.baseUrl, 'http://localhost:3000/api');
      api.close();
    });

    test('path ที่ขึ้นต้นด้วย / ยังต่อ URL ถูกต้อง', () async {
      final api = fakeApi(calls);
      await api.get('/products');
      expect(calls.single.path, '/api/products');
      api.close();
    });

    test('query ที่เป็น null หรือสตริงว่างถูกตัดทิ้ง แต่เลข 0 ยังอยู่', () async {
      final api = fakeApi(calls);
      await api.get('products', query: {'a': null, 'b': '', 'c': 0, 'd': 'x'});
      expect(calls.single.query, {'c': '0', 'd': 'x'});
      api.close();
    });
  });

  group('header และ method', () {
    test('แนบ Bearer token เมื่อมี token', () async {
      final api = fakeApi(calls, tokenProvider: () => 'abc');
      await api.get('profile');
      expect(calls.single.headers['authorization'], 'Bearer abc');
      api.close();
    });

    test('ไม่แนบ Authorization เมื่อ token เป็น null หรือว่าง', () async {
      final nullToken = fakeApi(calls, tokenProvider: () => null);
      await nullToken.get('profile');
      final emptyToken = fakeApi(calls, tokenProvider: () => '');
      await emptyToken.get('profile');

      expect(calls, hasLength(2));
      for (final call in calls) {
        expect(call.headers.containsKey('authorization'), false);
      }
      nullToken.close();
      emptyToken.close();
    });

    test('GET ไม่ส่ง content-type แต่ POST ส่งเป็น JSON', () async {
      final api = fakeApi(calls);
      await api.get('products');
      await api.post('orders', body: {'product_id': 1});

      expect(calls[0].headers.containsKey('content-type'), false);
      expect(calls[1].headers['content-type'], contains('application/json'));
      expect(calls[1].body, {'product_id': 1});
      api.close();
    });

    test('put และ delete ใช้ HTTP method ที่ถูกต้อง', () async {
      final api = fakeApi(calls);
      await api.put('profile', body: {'display_name': 'A'});
      await api.delete('products/1');

      expect(calls[0].label, 'PUT /api/profile');
      expect(calls[1].label, 'DELETE /api/products/1');
      api.close();
    });
  });

  group('การอ่าน response', () {
    test('ถอดรหัส JSON object ของ response สำเร็จ', () async {
      final api = fakeApi(calls, response: {'success': true, 'id': 3});
      final result = await api.get('x');
      expect(result, {'success': true, 'id': 3});
      api.close();
    });

    test('JSON ที่เป็น list ถูกห่อไว้ใต้ key data', () async {
      final api = fakeApi(calls, response: [1, 2, 3]);
      final result = await api.get('x');
      expect(result['data'], [1, 2, 3]);
      api.close();
    });

    test('response ที่ไม่ใช่ JSON → ApiException (status เดิม)', () async {
      final api = ApiClient(
        client: MockClient((_) async => http.Response('<html>oops</html>', 200)),
      );

      await expectLater(
        api.get('x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', contains('invalid response'))
              .having((e) => e.statusCode, 'statusCode', 200),
        ),
      );
      api.close();
    });

    test('body ว่าง (เช่น 204) ถูกมองว่าเป็น invalid response', () async {
      // บันทึกพฤติกรรมปัจจุบัน: backend (app.js) ตอบเป็น JSON เสมอ
      // จึงยังไม่มี endpoint ไหนได้รับผลกระทบ
      final api = ApiClient(
        client: MockClient((_) async => http.Response('', 204)),
      );

      await expectLater(api.get('x'), throwsA(isA<ApiException>()));
      api.close();
    });
  });

  group('error จาก server และเครือข่าย', () {
    test('ใช้ message จาก server พร้อม status และ details', () async {
      final api = fakeApi(
        calls,
        status: 409,
        response: {'success': false, 'message': 'Order cannot be cancelled'},
      );

      await expectLater(
        api.post('orders/1/cancel'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 409)
              .having((e) => e.message, 'message', 'Order cannot be cancelled')
              .having((e) => e.details?['success'], 'details', false),
        ),
      );
      api.close();
    });

    test('ไม่มี message ใน response ใช้ข้อความ Request failed', () async {
      final api = fakeApi(calls, status: 500, response: {'success': false});

      await expectLater(
        api.get('x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', 'Request failed (500).'),
        ),
      );
      api.close();
    });

    test('ต่อ server ไม่ได้ → ApiException Could not reach the server', () async {
      final api = ApiClient(
        client: MockClient((_) async => throw http.ClientException('boom')),
      );

      await expectLater(
        api.get('x'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Could not reach the server: boom',
          ),
        ),
      );
      api.close();
    });

    test('timeout → ApiException The server took too long', () async {
      final api = ApiClient(
        client: MockClient((_) async => throw TimeoutException('slow')),
      );

      await expectLater(
        api.get('x'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('too long'),
          ),
        ),
      );
      api.close();
    });
  });

  group('ApiException', () {
    test('toString คืนค่า message', () {
      const error = ApiException('Something failed', 400);
      expect(error.toString(), 'Something failed');
      expect(error.statusCode, 400);
      expect(error.details, isNull);
    });
  });
}
