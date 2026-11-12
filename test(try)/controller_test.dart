//ทดสอบการทำงานร่วมกันแบบภาพรวมของ ApiClient, AuthController,
//OrderController และ ProductController ในไฟล์เดียว

// นำเข้าไลบรารีสำหรับแปลงข้อมูล JSON (jsonEncode / jsonDecode)
import 'dart:convert';

// นำเข้าแพ็กเกจหลักสำหรับการเขียน Unit Test ใน Flutter
import 'package:flutter_test/flutter_test.dart';
// นำเข้าแพ็กเกจ http และ MockClient สำหรับจำลองการตอบกลับของ HTTP Request โดยตรง
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
// นำเข้าคลาส ApiClient และ Controller หลักทั้งหมดของแอปพลิเคชันที่ต้องการทดสอบการทำงานร่วมกัน
import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/auth_controller.dart';
import 'package:uni_swap/controller/order_controller.dart';
import 'package:uni_swap/controller/product_controller.dart';

void main() {
  // =========================================================================
  // เทสต์ที่ 1: ทดสอบการทำงานพื้นฐานของ ApiClient (การแนบ Token, Query และการแปลง JSON)
  // =========================================================================
  test('ApiClient sends auth header and decodes JSON', () async {
    var sawAuth =
        false; // ตัวแปรสำหรับเช็กว่า Request มีการแนบ Header Authorization มาจริงหรือไม่
    final api = ApiClient(
      baseUrl: 'http://localhost:3000/api',
      tokenProvider: () => 'test-token', // จำลองว่าผู้ใช้มี Token อยู่
      client: MockClient((request) async {
        // ตรวจสอบว่ามีการแนบ Bearer Token ถูกต้อง
        sawAuth = request.headers['authorization'] == 'Bearer test-token';
        // ตรวจสอบเส้นทาง Path และ Query Parameter ที่ถูกส่งออกไป
        expect(request.url.path, '/api/products');
        expect(request.url.queryParameters['category_id'], '2');
        // จำลองการส่งคำตอบกลับเป็น JSON สำเร็จ (HTTP 200)
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      }),
    );

    // สั่งเรียกเมธอด GET และตรวจสอบผลลัพธ์ที่ได้จากการแปลง JSON
    final result = await api.get('products', query: {'category_id': 2});
    expect(sawAuth, true);
    expect(result['success'], true);
    api.close(); // ปิดการเชื่อมต่อ HTTP Client เพื่อคืนทรัพยากร
  });

  // =========================================================================
  // เทสต์ที่ 2: ทดสอบการดักจับ Error จาก Server ของ ApiClient
  // =========================================================================
  test('ApiClient reports server errors as ApiException', () async {
    final api = ApiClient(
      client: MockClient(
        // จำลองกรณี Server ตอบกลับสถานะ 401 Unauthorized พร้อมข้อความแจ้งเตือน
        (_) async => http.Response(
          jsonEncode({'success': false, 'message': 'Invalid credentials'}),
          401,
        ),
      ),
    );

    try {
      await api.post('login', body: {'email': 'x', 'password': 'y'});
      fail(
        'Expected ApiException',
      ); // บังคับให้เทสต์ตกหากระบบไม่ยอมโยน Error ออกมา
    } on ApiException catch (error) {
      // ตรวจสอบว่า Error ที่ถูกโยนออกมามีรหัสสถานะและข้อความตรงตามที่ Server ส่งมา
      expect(error.statusCode, 401);
      expect(error.message, 'Invalid credentials');
    } finally {
      api.close(); // ปิด Client เสมอไม่ว่าเทสต์จะผ่านหรือเกิด Error
    }
  });

  // =========================================================================
  // เทสต์ที่ 3: ทดสอบวงจรการล็อกอินและออกจากระบบของ AuthController
  // =========================================================================
  test('AuthController stores token and user after login', () async {
    final api = ApiClient(
      client: MockClient((request) async {
        expect(request.url.path, '/api/login');
        // จำลองข้อมูลผู้ใช้และ Token ที่ได้กลับมาจาก API หลังล็อกอินสำเร็จ
        return http.Response(
          jsonEncode({
            'success': true,
            'token': 'session-token',
            'user': {'user_id': 3, 'role': 'member'},
          }),
          200,
        );
      }),
    );
    final controller = AuthController(api);

    // ทดสอบล็อกอิน -> ตรวจสอบว่าเก็บ Token และข้อมูล User ครบถ้วน
    await controller.login(email: 'member@example.com', password: 'secret123');
    expect(controller.isAuthenticated, true);
    expect(controller.token, 'session-token');
    expect(controller.user?['user_id'], 3);

    // ทดสอบออกจากระบบ (Sign Out) -> ตรวจสอบว่าสถานะการยืนยันตัวตนกลับเป็น false
    controller.signOut();
    expect(controller.isAuthenticated, false);
    api.close();
  });

  // =========================================================================
  // เทสต์ที่ 4: ทดสอบการส่งข้อมูลสร้างคำสั่งซื้อของ OrderController
  // =========================================================================
  test('OrderController submits order fields accepted by app.js', () async {
    final api = ApiClient(
      client: MockClient((request) async {
        // แปลง Request Body กลับมาตรวจสอบว่าชื่อฟิลด์ตรงกับที่ Backend (app.js) ต้องการ
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(request.url.path, '/api/orders');
        expect(body['product_id'], 5);
        expect(body['meetup_location'], 'Library entrance');
        // จำลองการสร้างออเดอร์สำเร็จ (HTTP 201 Created) พร้อมคืนรหัสออเดอร์ใหม่
        return http.Response(jsonEncode({'success': true, 'order_id': 8}), 201);
      }),
    );
    final orders = OrderController(api);

    final result = await orders.create(
      productId: 5,
      meetupLocation: 'Library entrance',
    );
    // ตรวจสอบว่าได้รับ order_id กลับมาถูกต้อง
    expect(result['order_id'], 8);
    api.close();
  });

  // =========================================================================
  // เทสต์ที่ 5: ทดสอบการสร้าง Query Filter สำหรับค้นหาสินค้าของ ProductController
  // =========================================================================
  test('ProductController builds supported browse filters', () async {
    final api = ApiClient(
      client: MockClient((request) async {
        // ตรวจสอบว่าคำค้นหาและโซนถูกแปลงเป็น Query String ต่อท้าย URL อย่างถูกต้อง
        expect(request.url.path, '/api/products');
        expect(request.url.queryParameters['keyword'], 'desk');
        expect(request.url.queryParameters['zone'], 'on_campus');
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      }),
    );

    await ProductController(api).browse(keyword: 'desk', zone: 'on_campus');
    api.close();
  });
}
