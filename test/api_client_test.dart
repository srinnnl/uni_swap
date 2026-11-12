// นำเข้าไลบรารีสำหรับจัดการการทำงานแบบ Asynchronous (เช่น TimeoutException)
import 'dart:async';

// นำเข้าแพ็กเกจหลักสำหรับการเขียน Unit Test ใน Flutter
import 'package:flutter_test/flutter_test.dart';
// นำเข้าแพ็กเกจ http และ MockClient สำหรับจำลองการตอบกลับของ HTTP Request ในระดับ Network
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
// นำเข้าคลาส ApiClient และ ApiException ที่ต้องการนำมาทดสอบ
import 'package:uni_swap/controller/api_client.dart';

// นำเข้าตัวช่วยจำลอง API (Fake API) สำหรับทดสอบ
import 'test_helpers.dart';

void main() {
  // ตัวแปรสำหรับเก็บรายการประวัติการเรียก API ที่เกิดขึ้นในแต่ละเทสต์
  late List<RecordedCall> calls;

  // รีเซ็ตประวัติการเรียก API ให้ว่างเปล่าก่อนเริ่มรันแต่ละเทสต์ย่อย
  setUp(() => calls = []);

  // =========================================================================
  // กลุ่มทดสอบที่ 1: การประกอบ URL และจัดการ Query Parameters
  // =========================================================================
  group('การสร้าง URL', () {
    test('ตัด / ท้าย baseUrl ออก', () {
      // ตรวจสอบว่าถ้าส่ง baseUrl ที่มีเครื่องหมาย / เกินมาด้านท้าย ระบบจะตัดออกให้สะอาด
      final api = ApiClient(baseUrl: 'http://example.test/api///');
      expect(api.baseUrl, 'http://example.test/api');
      api.close(); // ปิด HTTP Client เพื่อคืนทรัพยากร
    });

    test('baseUrl ตั้งต้นชี้ไปที่ localhost:3000', () {
      // ตรวจสอบค่า Default baseUrl เมื่อไม่ได้กำหนดค่าใดๆ ตอนสร้าง ApiClient
      final api = ApiClient();
      expect(api.baseUrl, 'http://localhost:3000/api');
      api.close();
    });

    test('path ที่ขึ้นต้นด้วย / ยังต่อ URL ถูกต้อง', () async {
      final api = fakeApi(calls);
      // ตรวจสอบว่าแม้ path จะขึ้นต้นด้วย / ก็จะไม่เกิดเครื่องหมาย // ซ้ำซ้อน
      await api.get('/products');
      expect(calls.single.path, '/api/products');
      api.close();
    });

    test('query ที่เป็น null หรือสตริงว่างถูกตัดทิ้ง แต่เลข 0 ยังอยู่', () async {
      final api = fakeApi(calls);
      // ตรวจสอบการกรอง Query Parameters: ค่าว่างหรือ null ต้องหายไป แต่เลข 0 ต้องถูกแปลงเป็น '0' และส่งไปตามปกติ
      await api.get('products', query: {'a': null, 'b': '', 'c': 0, 'd': 'x'});
      expect(calls.single.query, {'c': '0', 'd': 'x'});
      api.close();
    });
  });

  // =========================================================================
  // กลุ่มทดสอบที่ 2: การจัดการ HTTP Headers และ HTTP Methods
  // =========================================================================
  group('header และ method', () {
    test('แนบ Bearer token เมื่อมี token', () async {
      // ตรวจสอบว่าเมื่อ tokenProvider คืนค่า token ระบบจะแนบ Header Authorization ให้อัตโนมัติ
      final api = fakeApi(calls, tokenProvider: () => 'abc');
      await api.get('profile');
      expect(calls.single.headers['authorization'], 'Bearer abc');
      api.close();
    });

    test('ไม่แนบ Authorization เมื่อ token เป็น null หรือว่าง', () async {
      // ทดสอบกรณีไม่มี token (คืนค่า null) และกรณี token เป็นข้อความว่าง
      final nullToken = fakeApi(calls, tokenProvider: () => null);
      await nullToken.get('profile');
      final emptyToken = fakeApi(calls, tokenProvider: () => '');
      await emptyToken.get('profile');

      // ตรวจสอบว่าทั้ง 2 ครั้งไม่มีการแนบ Header Authorization ไปใน Request
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

      // ตรวจสอบว่า GET ไม่มี Header content-type ส่วน POST ต้องระบุเป็น application/json และส่ง body ได้ถูกต้อง
      expect(calls[0].headers.containsKey('content-type'), false);
      expect(calls[1].headers['content-type'], contains('application/json'));
      expect(calls[1].body, {'product_id': 1});
      api.close();
    });

    test('put และ delete ใช้ HTTP method ที่ถูกต้อง', () async {
      final api = fakeApi(calls);
      // ทดสอบการเรียกใช้เมธอด PUT และ DELETE
      await api.put('profile', body: {'display_name': 'A'});
      await api.delete('products/1');

      expect(calls[0].label, 'PUT /api/profile');
      expect(calls[1].label, 'DELETE /api/products/1');
      api.close();
    });
  });

  // =========================================================================
  // กลุ่มทดสอบที่ 3: การแปลงและอ่านข้อมูล Response จาก Server
  // =========================================================================
  group('การอ่าน response', () {
    test('ถอดรหัส JSON object ของ response สำเร็จ', () async {
      // ตรวจสอบการแปลง JSON Object ทั่วไปให้กลายเป็น Map ใน Dart
      final api = fakeApi(calls, response: {'success': true, 'id': 3});
      final result = await api.get('x');
      expect(result, {'success': true, 'id': 3});
      api.close();
    });

    test('JSON ที่เป็น list ถูกห่อไว้ใต้ key data', () async {
      // ตรวจสอบกรณีที่ Server ส่งข้อมูลกลับมาเป็น JSON Array ([...]) ระบบจะห่อไว้ใน Map ภายใต้คีย์ 'data'
      final api = fakeApi(calls, response: [1, 2, 3]);
      final result = await api.get('x');
      expect(result['data'], [1, 2, 3]);
      api.close();
    });

    test('response ที่ไม่ใช่ JSON → ApiException (status เดิม)', () async {
      // จำลองกรณี Server ตอบกลับมาเป็น HTML แทนที่จะเป็น JSON (เช่น หน้า Error ของ Web Server)
      final api = ApiClient(
        client: MockClient(
          (_) async => http.Response('<html>oops</html>', 200),
        ),
      );

      // ตรวจสอบว่าต้องโยน ApiException พร้อมแจ้งเตือน invalid response และคงเลข status code เดิมไว้
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

      // ตรวจสอบว่าหากได้ Response Body ว่างเปล่า ระบบจะโยน ApiException
      await expectLater(api.get('x'), throwsA(isA<ApiException>()));
      api.close();
    });
  });

  // =========================================================================
  // กลุ่มทดสอบที่ 4: การจัดการข้อผิดพลาดจาก Server และปัญหาเครือข่าย
  // =========================================================================
  group('error จาก server และเครือข่าย', () {
    test('ใช้ message จาก server พร้อม status และ details', () async {
      // จำลองกรณี Server ตอบกลับ Error 409 พร้อมข้อความอธิบายใน JSON
      final api = fakeApi(
        calls,
        status: 409,
        response: {'success': false, 'message': 'Order cannot be cancelled'},
      );

      // ตรวจสอบว่า ApiException ดึง statusCode, message และเก็บข้อมูล JSON ทั้งก้อนไว้ใน details
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
      // จำลองกรณี Server ตอบกลับ Error 500 โดยไม่มีฟิลด์ message แนบมาด้วย
      final api = fakeApi(calls, status: 500, response: {'success': false});

      // ตรวจสอบว่าระบบสร้างข้อความ Error มาตรฐาน 'Request failed (500).' ขึ้นมาแทน
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
      // จำลองปัญหาการเชื่อมต่อเครือข่าย (เช่น ไม่มีอินเทอร์เน็ต หรือ Server ปิดอยู่)
      final api = ApiClient(
        client: MockClient((_) async => throw http.ClientException('boom')),
      );

      // ตรวจสอบว่าแปลง ClientException ให้เป็น ApiException ที่อ่านเข้าใจง่าย
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
      // จำลองกรณีที่ Server ตอบสนองช้าเกินเวลาที่กำหนด (TimeoutException)
      final api = ApiClient(
        client: MockClient((_) async => throw TimeoutException('slow')),
      );

      // ตรวจสอบว่าแปลง TimeoutException ให้เป็น ApiException พร้อมข้อความแจ้งเตือนเรื่องความล่าช้า
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

  // =========================================================================
  // กลุ่มทดสอบที่ 5: การทำงานของคลาส ApiException
  // =========================================================================
  group('ApiException', () {
    test('toString คืนค่า message', () {
      // ตรวจสอบการสร้างออบเจกต์ ApiException และค่าที่คืนจากเมธอด toString()
      const error = ApiException('Something failed', 400);
      expect(error.toString(), 'Something failed');
      expect(error.statusCode, 400);
      expect(error.details, isNull);
    });
  });
}
