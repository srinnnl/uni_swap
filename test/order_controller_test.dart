// นำเข้าแพ็กเกจหลักสำหรับการเขียน Unit Test ใน Flutter
import 'package:flutter_test/flutter_test.dart';
// นำเข้าคลาสจัดการ Error และ OrderController ที่ต้องการนำมาทดสอบ
import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/order_controller.dart';

// นำเข้าตัวช่วยจำลอง API (Fake API) สำหรับการทดสอบ
import 'test_helpers.dart';

void main() {
  // ประกาศตัวแปรเก็บประวัติการเรียก API และตัวแปร OrderController
  late List<RecordedCall> calls;
  late OrderController orders;

  // รีเซ็ตประวัติการเรียก API และสร้าง OrderController ใหม่ก่อนรันแต่ละเทสต์ย่อย
  setUp(() {
    calls = [];
    orders = OrderController(fakeApi(calls));
  });

  // =========================================================================
  // ส่วนที่ 1: ทดสอบการดึงรายการคำสั่งซื้อทั้งหมด (List Orders & Pagination)
  // =========================================================================
  test('list ใช้ page=1 limit=20 เป็นค่าตั้งต้น', () async {
    await orders.list();
    // ตรวจสอบว่าหากไม่ส่งพารามิเตอร์ ระบบจะดึงหน้าแรก (page=1) จำนวน 20 รายการเป็นค่าเริ่มต้น
    expect(calls.single.label, 'GET /api/orders');
    expect(calls.single.query, {'page': '1', 'limit': '20'});
  });

  test('list ส่ง paging ที่กำหนด', () async {
    await orders.list(page: 2, limit: 5);
    // ตรวจสอบการส่งพารามิเตอร์เปลี่ยนหน้าและจำกัดจำนวนรายการตามที่ระบุ
    expect(calls.single.query, {'page': '2', 'limit': '5'});
  });

  // =========================================================================
  // ส่วนที่ 2: ทดสอบการสร้างคำสั่งซื้อใหม่ (Create Order)
  // =========================================================================
  group('create', () {
    test('ไม่ระบุเวลานัด → meetup_datetime เป็น null', () async {
      await orders.create(productId: 5, meetupLocation: 'Library entrance');

      // ตรวจสอบการส่งข้อมูลสร้างออเดอร์เมื่อระบุแค่รหัสสินค้าและสถานที่นัดรับ โดยไม่ระบุเวลานัด
      expect(calls.single.label, 'POST /api/orders');
      expect(calls.single.body, {
        'product_id': 5,
        'meetup_location': 'Library entrance',
        'meetup_datetime': null,
      });
    });

    test('เวลานัดถูกแปลงเป็น UTC ISO-8601', () async {
      await orders.create(
        productId: 5,
        meetupLocation: 'Library entrance',
        meetupDateTime: DateTime.utc(2026, 11, 20, 8, 30),
      );

      // ตรวจสอบว่าออบเจกต์ DateTime ถูกแปลงเป็นสตริงเวลามาตรฐาน ISO-8601 (UTC) ก่อนส่งให้ Backend
      expect(calls.single.body!['meetup_datetime'], '2026-11-20T08:30:00.000Z');
    });

    test('server ตอบ 409 → โยน ApiException', () async {
      // จำลองกรณีสินค้าถูกคนอื่นตัดหน้าซื้อไปแล้วหรือสถานะไม่พร้อมขาย (HTTP 409 Conflict)
      final conflict = OrderController(
        fakeApi(
          calls,
          status: 409,
          response: {'success': false, 'message': 'Product is not available'},
        ),
      );

      // ตรวจสอบว่า Controller โยน ApiException พร้อมสถานะ 409 และข้อความแจ้งเตือนจาก Server
      await expectLater(
        conflict.create(productId: 5, meetupLocation: 'x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 409)
              .having((e) => e.message, 'message', 'Product is not available'),
        ),
      );
    });
  });

  // =========================================================================
  // ส่วนที่ 3: ทดสอบการยกเลิกออเดอร์และการแก้ไขข้อมูลนัดรับสินค้า
  // =========================================================================
  test('cancel ส่ง POST ไปที่ออเดอร์ที่ระบุ', () async {
    await orders.cancel(12);
    // ตรวจสอบการยิงคำสั่งยกเลิกออเดอร์ตาม ID ที่กำหนด (12)
    expect(calls.single.label, 'POST /api/orders/12/cancel');
  });

  test('updateMeetup ส่ง PUT พร้อมสถานที่และเวลา', () async {
    await orders.updateMeetup(
      orderId: 12,
      location: 'Canteen',
      dateTime: DateTime.utc(2026, 12, 1, 10),
    );

    // ตรวจสอบการอัปเดตสถานที่และเวลานัดรับสินค้า (แปลงเวลาเป็น UTC ISO-8601)
    expect(calls.single.label, 'PUT /api/orders/12/meetup');
    expect(calls.single.body, {
      'meetup_location': 'Canteen',
      'meetup_datetime': '2026-12-01T10:00:00.000Z',
    });
  });

  test('updateMeetup ไม่ระบุเวลา → meetup_datetime เป็น null', () async {
    await orders.updateMeetup(orderId: 12, location: 'Canteen');
    // ตรวจสอบกรณีอัปเดตเฉพาะสถานที่นัดรับโดยไม่กำหนดเวลา ค่า meetup_datetime ต้องเป็น null
    expect(calls.single.body!['meetup_datetime'], isNull);
  });

  // =========================================================================
  // ส่วนที่ 4: ทดสอบการชำระเงิน (Pay)
  // =========================================================================
  group('pay', () {
    test('ค่าตั้งต้นคือ gateway และไม่มี ref/slip', () async {
      await orders.pay(12);

      // ตรวจสอบค่าเริ่มต้นเมื่อเรียกชำระเงินโดยไม่ระบุช่องทาง (ต้องใช้ gateway และไม่มีสลิป)
      expect(calls.single.label, 'POST /api/orders/12/pay');
      expect(calls.single.body, {
        'payment_method': 'gateway',
        'transaction_ref': null,
        'payment_slip_url': null,
      });
    });

    test('ส่งวิธีจ่ายเงิน, ref และ slip ที่กำหนด', () async {
      await orders.pay(
        12,
        method: 'bank_transfer',
        transactionRef: 'REF-1',
        slipUrl: 'https://example.com/slip.jpg',
      );

      // ตรวจสอบการส่งข้อมูลการโอนเงินผ่านธนาคารพร้อมเลขอ้างอิงและ URL รูปสลิป
      expect(calls.single.body, {
        'payment_method': 'bank_transfer',
        'transaction_ref': 'REF-1',
        'payment_slip_url': 'https://example.com/slip.jpg',
      });
    });
  });

  // =========================================================================
  // ส่วนที่ 5: ทดสอบการขอคืนเงิน (Request Refund) และการรายงานปัญหา (Report)
  // =========================================================================
  test('requestRefund ส่งเหตุผลไปที่ /refunds', () async {
    await orders.requestRefund(12, 'Item not as described');

    // ตรวจสอบการส่งคำขอคืนเงินของออเดอร์ที่ 12 พร้อมเหตุผลประกอบ
    expect(calls.single.label, 'POST /api/orders/12/refunds');
    expect(calls.single.body, {'reason': 'Item not as described'});
  });

  group('report', () {
    test('ส่งฟิลด์ตามที่ app.js รับ', () async {
      await orders.report(
        orderId: 12,
        type: 'seller_problem',
        reason: 'Seller did not show up',
        evidenceUrl: 'https://example.com/proof.png',
      );

      // ตรวจสอบชื่อฟิลด์และข้อมูลที่ส่งไปยัง endpoint รายงานปัญหาให้ตรงกับฝั่ง Backend
      expect(calls.single.label, 'POST /api/reports');
      expect(calls.single.body, {
        'order_id': 12,
        'report_type': 'seller_problem',
        'reason': 'Seller did not show up',
        'evidence_url': 'https://example.com/proof.png',
      });
    });

    test('ไม่ระบุหลักฐาน → evidence_url เป็น null', () async {
      await orders.report(orderId: 12, type: 'other', reason: 'Other issue');
      // ตรวจสอบกรณีส่งรายงานโดยไม่ได้แนบหลักฐานรูปภาพ ค่า evidence_url ต้องเป็น null
      expect(calls.single.body!['evidence_url'], isNull);
    });

    test('ไม่ใช่เจ้าของออเดอร์ (403) → โยน ApiException', () async {
      // จำลองกรณีผู้ใช้พยายามรายงานออเดอร์ที่ตนเองไม่ได้มีส่วนเกี่ยวข้อง (HTTP 403 Forbidden)
      final denied = OrderController(
        fakeApi(
          calls,
          status: 403,
          response: {'success': false, 'message': 'Order access denied'},
        ),
      );

      // ตรวจสอบว่าต้องโยน ApiException รหัส 403
      await expectLater(
        denied.report(orderId: 99, type: 'other', reason: 'x'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });
  });
}
