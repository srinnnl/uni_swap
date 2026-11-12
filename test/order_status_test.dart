import 'package:flutter_test/flutter_test.dart';
import 'package:uni_swap/model/order_status.dart';

void main() {
  group('OrderStatus', () {
    test('apiValue ตรงกับ ENUM ใน DB', () {
      expect(OrderStatus.pendingPayment.apiValue, 'pending_payment');
      expect(OrderStatus.readyForMeetup.apiValue, 'ready_for_meetup');
      expect(OrderStatus.refundRequested.apiValue, 'refund_requested');
      expect(OrderStatus.partiallyRefunded.apiValue, 'partially_refunded');
    });

    test('tryParse แปลงกลับได้ครบทุกค่า', () {
      for (final status in OrderStatus.values) {
        expect(OrderStatus.tryParse(status.apiValue), status);
      }
    });

    test('tryParse ค่าที่ไม่รู้จักหรือ null → null', () {
      expect(OrderStatus.tryParse('bogus'), isNull);
      expect(OrderStatus.tryParse(null), isNull);
      expect(OrderStatus.tryParse(42), isNull);
    });

    test('fromApi ใช้ pendingPayment เมื่อไม่รู้จักค่า', () {
      expect(OrderStatus.fromApi('paid'), OrderStatus.paid);
      expect(OrderStatus.fromApi('bogus'), OrderStatus.pendingPayment);
    });

    test('isActive: ออเดอร์ที่ยังดำเนินอยู่', () {
      const expected = {
        OrderStatus.pendingPayment: true,
        OrderStatus.paid: true,
        OrderStatus.readyForMeetup: true,
        OrderStatus.refundRequested: true,
        OrderStatus.completed: false,
        OrderStatus.cancelled: false,
        OrderStatus.expired: false,
        OrderStatus.partiallyRefunded: false,
        OrderStatus.refunded: false,
      };
      expect(expected.length, OrderStatus.values.length);
      expected.forEach((status, isActive) {
        expect(status.isActive, isActive, reason: status.name);
      });
    });

    test('isPaid: จ่ายเงินเข้าระบบแล้ว', () {
      const expected = {
        OrderStatus.pendingPayment: false,
        OrderStatus.paid: true,
        OrderStatus.readyForMeetup: true,
        OrderStatus.completed: true,
        OrderStatus.cancelled: false,
        OrderStatus.expired: false,
        OrderStatus.refundRequested: true,
        OrderStatus.partiallyRefunded: true,
        OrderStatus.refunded: true,
      };
      expect(expected.length, OrderStatus.values.length);
      expected.forEach((status, isPaid) {
        expect(status.isPaid, isPaid, reason: status.name);
      });
    });

    test('canConfirmReceived ได้เฉพาะ paid และ readyForMeetup', () {
      for (final status in OrderStatus.values) {
        final expected =
            status == OrderStatus.paid || status == OrderStatus.readyForMeetup;
        expect(status.canConfirmReceived, expected, reason: status.name);
      }
    });

    test('label ของแต่ละสถานะ', () {
      expect(OrderStatus.pendingPayment.label, 'Awaiting payment');
      expect(OrderStatus.paid.label, 'Paid');
      expect(OrderStatus.readyForMeetup.label, 'Ready to meet');
      expect(OrderStatus.completed.label, 'Completed');
      expect(OrderStatus.cancelled.label, 'Cancelled');
      expect(OrderStatus.expired.label, 'Expired');
      expect(OrderStatus.refundRequested.label, 'Refund requested');
      expect(OrderStatus.partiallyRefunded.label, 'Partially refunded');
      expect(OrderStatus.refunded.label, 'Refunded');
    });

    test('tone ของป้ายสถานะ', () {
      const expected = {
        OrderStatus.pendingPayment: StatusTone.amber,
        OrderStatus.refundRequested: StatusTone.amber,
        OrderStatus.paid: StatusTone.blue,
        OrderStatus.readyForMeetup: StatusTone.blue,
        OrderStatus.partiallyRefunded: StatusTone.blue,
        OrderStatus.refunded: StatusTone.blue,
        OrderStatus.completed: StatusTone.green,
        OrderStatus.cancelled: StatusTone.red,
        OrderStatus.expired: StatusTone.red,
      };
      expect(expected.length, OrderStatus.values.length);
      expected.forEach((status, tone) {
        expect(status.tone, tone, reason: status.name);
      });
    });
  });

  group('ProductStatus', () {
    test('apiValue ตรงกับ ENUM ใน DB', () {
      expect(ProductStatus.pendingReview.apiValue, 'pending_review');
      expect(ProductStatus.changesRequested.apiValue, 'changes_requested');
      expect(ProductStatus.available.apiValue, 'available');
    });

    test('tryParse แปลงกลับได้ครบทุกค่า', () {
      for (final status in ProductStatus.values) {
        expect(ProductStatus.tryParse(status.apiValue), status);
      }
    });

    test('tryParse ค่าที่ไม่รู้จักหรือ null → null', () {
      expect(ProductStatus.tryParse('bogus'), isNull);
      expect(ProductStatus.tryParse(null), isNull);
    });

    test('fromApi ใช้ available เมื่อไม่รู้จักค่า', () {
      expect(ProductStatus.fromApi('sold'), ProductStatus.sold);
      expect(ProductStatus.fromApi('bogus'), ProductStatus.available);
    });
  });

  test('kPaymentWindow คือ 30 นาที', () {
    expect(kPaymentWindow, const Duration(minutes: 30));
  });
}
