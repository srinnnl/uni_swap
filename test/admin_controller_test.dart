// นำเข้าแพ็กเกจหลักสำหรับการเขียน Unit Test ใน Flutter
import 'package:flutter_test/flutter_test.dart';
// นำเข้า Controller และ API Client ที่ต้องการนำมาทดสอบ
import 'package:uni_swap/controller/admin_controller.dart';
import 'package:uni_swap/controller/api_client.dart';

// นำเข้าไฟล์ตัวช่วยจำลองการเรียก API (Mock/Fake API)
import 'test_helpers.dart';

void main() {
  // ประกาศตัวแปรสำหรับเก็บประวัติการเรียก API และตัวแปร AdminController
  late List<RecordedCall> calls;
  late AdminController admin;

  // ฟังก์ชัน setUp จะทำงานก่อนเริ่มการทดสอบ (test) ย่อยทุกครั้ง เพื่อรีเซ็ตค่าให้สะอาด
  setUp(() {
    calls = []; // ล้างรายการบันทึกการเรียก API ให้ว่างเปล่า
    admin = AdminController(
      fakeApi(calls),
    ); // สร้าง AdminController โดยใช้ API จำลอง
  });

  // =========================================================================
  // กลุ่มทดสอบที่ 1: การดึงข้อมูลหน้า Dashboard และการจัดการผู้ใช้งาน (Users)
  // =========================================================================
  group('dashboard และ users', () {
    test('dashboard เรียก GET /api/admin/dashboard', () async {
      await admin.dashboard();
      // ตรวจสอบว่ามีการยิง HTTP Method และ Endpoint ตรงตามที่กำหนดหรือไม่
      expect(calls.single.label, 'GET /api/admin/dashboard');
    });

    test('users ใช้ page=1 limit=20 และไม่ส่ง status ถ้าไม่ระบุ', () async {
      await admin.users();
      expect(calls.single.label, 'GET /api/admin/users');
      // ตรวจสอบค่า Query Parameters เริ่มต้น (Pagination)
      expect(calls.single.query, {'page': '1', 'limit': '20'});
    });

    test('users ส่ง status และ paging ที่กำหนด', () async {
      await admin.users(status: 'pending', page: 3, limit: 50);
      // ตรวจสอบว่าค่าพารามิเตอร์ที่ส่งเข้าไปถูกแปลงเป็น Query String อย่างถูกต้อง
      expect(calls.single.query, {
        'status': 'pending',
        'page': '3',
        'limit': '50',
      });
    });

    test('setUserStatus ส่ง PUT พร้อม status ใน body', () async {
      await admin.setUserStatus(5, 'suspended');
      // ตรวจสอบว่ามีการส่ง userId (5) ไปใน URL และส่งสถานะใหม่ไปใน Request Body
      expect(calls.single.label, 'PUT /api/admin/users/5/status');
      expect(calls.single.body, {'status': 'suspended'});
    });
  });

  // =========================================================================
  // กลุ่มทดสอบที่ 2: การจัดการรายการสินค้า/โพสต์ (Listings)
  // =========================================================================
  group('listings', () {
    test('listings ค่าตั้งต้นคือ pending_review', () async {
      await admin.listings();
      expect(calls.single.label, 'GET /api/admin/listings');
      // ตรวจสอบว่าถ้าไม่ระบุสถานะ ระบบจะดึงรายการที่รอตรวจสอบ (pending_review) เป็นค่าเริ่มต้น
      expect(calls.single.query['status'], 'pending_review');
    });

    test('listings เปลี่ยน status ได้', () async {
      await admin.listings(status: 'all', page: 2);
      // ตรวจสอบการส่งพารามิเตอร์เพื่อกรองสถานะและเปลี่ยนหน้า
      expect(calls.single.query['status'], 'all');
      expect(calls.single.query['page'], '2');
    });

    test('reviewListing แบบ approve ไม่มี note และ reject_reason', () async {
      await admin.reviewListing(7, action: 'approve');
      expect(calls.single.label, 'PUT /api/admin/listings/7/review');
      // ตรวจสอบว่าการอนุมัติ (approve) จะไม่ส่งหมายเหตุหรือเหตุผลการปฏิเสธ (เป็น null)
      expect(calls.single.body!['action'], 'approve');
      expect(calls.single.body!['review_note'], isNull);
      expect(calls.single.body!['reject_reason'], isNull);
    });

    test('reviewListing แบบ reject ส่ง note และ reject_reason', () async {
      await admin.reviewListing(
        7,
        action: 'reject',
        note: 'Photos are blurry',
        rejectReason: 'poor_photos',
      );
      // ตรวจสอบว่าการปฏิเสธ (reject) ส่งเหตุผลและหมายเหตุครบถ้วนใน Body
      expect(calls.single.body, {
        'action': 'reject',
        'review_note': 'Photos are blurry',
        'reject_reason': 'poor_photos',
      });
    });
  });

  // =========================================================================
  // กลุ่มทดสอบที่ 3: การจัดการรายงานความไม่เหมาะสม (Reports)
  // =========================================================================
  group('reports', () {
    test('reports ใช้ paging ตั้งต้น', () async {
      await admin.reports();
      expect(calls.single.label, 'GET /api/admin/reports');
      expect(calls.single.query, {'page': '1', 'limit': '20'});
    });

    test('resolveReport ไม่ซ่อนสินค้าเป็นค่าตั้งต้น', () async {
      await admin.resolveReport(9, status: 'resolved');
      expect(calls.single.label, 'PUT /api/admin/reports/9');
      // ตรวจสอบค่าตั้งต้นเมื่อปิดเคสรายงาน ต้องไม่ซ่อนสินค้า (hide_product = false)
      expect(calls.single.body!['status'], 'resolved');
      expect(calls.single.body!['hide_product'], false);
      expect(calls.single.body!['admin_note'], isNull);
    });

    test('resolveReport ส่ง hide_product และ admin_note ได้', () async {
      await admin.resolveReport(
        9,
        status: 'resolved',
        note: 'Item removed',
        hideProduct: true,
      );
      // ตรวจสอบการส่งคำสั่งซ่อนสินค้าและบันทึกหมายเหตุของแอดมิน
      expect(calls.single.body!['hide_product'], true);
      expect(calls.single.body!['admin_note'], 'Item removed');
    });
  });

  // =========================================================================
  // กลุ่มทดสอบที่ 4: การจัดการหมวดหมู่สินค้า (Categories)
  // =========================================================================
  group('categories', () {
    test('categories เรียก GET /api/admin/categories', () async {
      await admin.categories();
      expect(calls.single.label, 'GET /api/admin/categories');
    });

    test('createCategory ใช้ is_active=true และมี emoji ตั้งต้น', () async {
      await admin.createCategory(name: 'Books');
      expect(calls.single.label, 'POST /api/admin/categories');
      // ตรวจสอบว่าเมื่อสร้างหมวดหมู่ใหม่โดยไม่ระบุค่าเสริม จะได้ emoji เริ่มต้นและเปิดใช้งานทันที
      expect(calls.single.body!['name'], 'Books');
      expect(calls.single.body!['emoji'], isNotEmpty);
      expect(calls.single.body!['is_active'], true);
    });

    test('createCategory กำหนด emoji และ active เองได้', () async {
      await admin.createCategory(name: 'Books', emoji: 'B', active: false);
      // ตรวจสอบการส่งค่าที่กำหนดเองทั้งหมดเข้าไปใน Request Body
      expect(calls.single.body, {
        'name': 'Books',
        'emoji': 'B',
        'is_active': false,
      });
    });

    test('updateCategory ส่ง PUT ไปที่ id ที่ถูกต้อง', () async {
      await admin.updateCategory(4, name: 'Food', emoji: 'F', active: true);
      // ตรวจสอบการอัปเดตข้อมูลตาม ID หมวดหมู่ที่ระบุ
      expect(calls.single.label, 'PUT /api/admin/categories/4');
      expect(calls.single.body, {
        'name': 'Food',
        'emoji': 'F',
        'is_active': true,
      });
    });
  });

  // =========================================================================
  // กลุ่มทดสอบที่ 5: การจัดการสถานที่นัดรับสินค้า (Locations)
  // =========================================================================
  group('locations', () {
    test('locations ไม่ส่ง zone ถ้าไม่ระบุ', () async {
      await admin.locations();
      expect(calls.single.label, 'GET /api/admin/locations');
      // ตรวจสอบว่าถ้าไม่กรองโซน Query จะต้องว่างเปล่า
      expect(calls.single.query, isEmpty);
    });

    test('locations กรองด้วย zone', () async {
      await admin.locations(zone: 'on_campus');
      // ตรวจสอบการส่งพารามิเตอร์กรองตามโซน
      expect(calls.single.query, {'zone': 'on_campus'});
    });

    test('createLocation ส่ง name และ zone', () async {
      await admin.createLocation(name: 'Library', zone: 'on_campus');
      expect(calls.single.label, 'POST /api/admin/locations');
      expect(calls.single.body, {'name': 'Library', 'zone': 'on_campus'});
    });

    test('updateLocation ส่ง PUT พร้อม is_active', () async {
      await admin.updateLocation(2, name: 'Canteen', active: false);
      expect(calls.single.label, 'PUT /api/admin/locations/2');
      expect(calls.single.body, {'name': 'Canteen', 'is_active': false});
    });
  });

  // =========================================================================
  // กลุ่มทดสอบที่ 6: การจัดการคำขอเพิ่มสถานที่ใหม่จากผู้ใช้ (Location Requests)
  // =========================================================================
  group('location requests', () {
    test('locationRequests ใช้ paging ตั้งต้นและไม่ส่ง status', () async {
      await admin.locationRequests();
      expect(calls.single.label, 'GET /api/admin/location-requests');
      expect(calls.single.query, {'page': '1', 'limit': '20'});
    });

    test('locationRequests กรองด้วย status', () async {
      await admin.locationRequests(status: 'pending');
      expect(calls.single.query['status'], 'pending');
    });

    test('reviewLocationRequest แบบ approve ไม่มี merge id', () async {
      await admin.reviewLocationRequest(11, action: 'approve');
      expect(calls.single.label, 'PUT /api/admin/location-requests/11/review');
      // ตรวจสอบว่าการอนุมัติปกติ จะไม่มี ID สถานที่ปลายทางสำหรับรวมข้อมูล (merge)
      expect(calls.single.body!['action'], 'approve');
      expect(calls.single.body!['merge_into_location_id'], isNull);
    });

    test('reviewLocationRequest แบบ merge ส่ง location ปลายทาง', () async {
      await admin.reviewLocationRequest(
        11,
        action: 'merge',
        mergeIntoLocationId: 3,
      );
      // ตรวจสอบว่าการรวมสถานที่ (merge) มีการส่ง ID สถานที่ปลายทางที่ต้องการรวมไปด้วย
      expect(calls.single.body, {
        'action': 'merge',
        'merge_into_location_id': 3,
      });
    });
  });

  // =========================================================================
  // กลุ่มทดสอบที่ 7: การจัดการข้อผิดพลาดและการยืนยันตัวตน (Error & Auth)
  // =========================================================================
  group('การจัดการ error', () {
    test('403 Admin only ถูกโยนเป็น ApiException', () async {
      // จำลองสถานการณ์ที่ API ตอบกลับสถานะ 403 (ไม่มีสิทธิ์เข้าถึง)
      final denied = AdminController(
        fakeApi(
          calls,
          status: 403,
          response: {'success': false, 'message': 'Admin only'},
        ),
      );

      // ตรวจสอบว่า Controller โยน Exception ชนิด ApiException พร้อมรหัสและข้อความที่ถูกต้อง
      expect(
        denied.dashboard(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', 'Admin only'),
        ),
      );
    });

    test('ส่ง token ไปกับ request ทุกครั้งเมื่อมี tokenProvider', () async {
      // จำลองการตั้งค่า Controller ที่มีตัวดึง Token
      final withToken = AdminController(
        fakeApi(calls, tokenProvider: () => 'admin-token'),
      );
      await withToken.dashboard();
      // ตรวจสอบว่ามีการแนบ Authorization Header แบบ Bearer Token ไปกับคำขอด้วย
      expect(calls.single.headers['authorization'], 'Bearer admin-token');
    });
  });
}
