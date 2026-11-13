import 'package:flutter_test/flutter_test.dart';
import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/order_controller.dart';

import 'test_helpers.dart';

void main() {
  late List<RecordedCall> calls;
  late OrderController orders;

  setUp(() {
    calls = [];
    orders = OrderController(fakeApi(calls));
  });

  test('list ใช้ page=1 limit=20 เป็นค่าตั้งต้น', () async {
    await orders.list();
    expect(calls.single.label, 'GET /api/orders');
    expect(calls.single.query, {'page': '1', 'limit': '20'});
  });

  test('list ส่ง paging ที่กำหนด', () async {
    await orders.list(page: 2, limit: 5);
    expect(calls.single.query, {'page': '2', 'limit': '5'});
  });

  group('create', () {
    test('ไม่ระบุเวลานัด → meetup_datetime เป็น null', () async {
      await orders.create(productId: 5, meetupLocation: 'Library entrance');

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

      expect(calls.single.body!['meetup_datetime'], '2026-11-20T08:30:00.000Z');
    });

    test('server ตอบ 409 → โยน ApiException', () async {
      final conflict = OrderController(
        fakeApi(
          calls,
          status: 409,
          response: {'success': false, 'message': 'Product is not available'},
        ),
      );

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

  test('cancel ส่ง POST ไปที่ออเดอร์ที่ระบุ', () async {
    await orders.cancel(12);
    expect(calls.single.label, 'POST /api/orders/12/cancel');
  });

  test('updateMeetup ส่ง PUT พร้อมสถานที่และเวลา', () async {
    await orders.updateMeetup(
      orderId: 12,
      location: 'Canteen',
      dateTime: DateTime.utc(2026, 12, 1, 10),
    );

    expect(calls.single.label, 'PUT /api/orders/12/meetup');
    expect(calls.single.body, {
      'meetup_location': 'Canteen',
      'meetup_datetime': '2026-12-01T10:00:00.000Z',
    });
  });

  test('updateMeetup ไม่ระบุเวลา → meetup_datetime เป็น null', () async {
    await orders.updateMeetup(orderId: 12, location: 'Canteen');
    expect(calls.single.body!['meetup_datetime'], isNull);
  });

  group('pay', () {
    test('ค่าตั้งต้นคือ gateway และไม่มี ref/slip', () async {
      await orders.pay(12);

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

      expect(calls.single.body, {
        'payment_method': 'bank_transfer',
        'transaction_ref': 'REF-1',
        'payment_slip_url': 'https://example.com/slip.jpg',
      });
    });
  });
}
