// นำเข้าแพ็กเกจหลักสำหรับการเขียน Unit Test ใน Flutter
import 'package:flutter_test/flutter_test.dart';
// นำเข้าไฟล์โมเดลที่จัดการสถานะของคำสั่งซื้อ (OrderStatus) และสถานะสินค้า (ProductStatus)
import 'package:uni_swap/model/order_status.dart';

void main() {
  // =========================================================================
  // กลุ่มทดสอบที่ 1: สถานะของคำสั่งซื้อ (OrderStatus) และ Logic ที่เกี่ยวข้อง
  // =========================================================================
  group('OrderStatus', () {
    test('apiValue ตรงกับ ENUM ใน DB', () {
      // ตรวจสอบว่าชื่อค่าที่แปลงเป็น String (snake_case) ตรงกับคอลัมน์ ENUM ในฐานข้อมูล
      expect(OrderStatus.pendingPayment.apiValue, 'pending_payment');
      expect(OrderStatus.readyForMeetup.apiValue, 'ready_for_meetup');
      expect(OrderStatus.refundRequested.apiValue, 'refund_requested');
      expect(OrderStatus.partiallyRefunded.apiValue, 'partially_refunded');
    });

    test('tryParse แปลงกลับได้ครบทุกค่า', () {
      // วนลูปตรวจสอบว่าทุกสถานะใน OrderStatus เมื่อแปลงเป็น apiValue แล้วแปลงกลับจะได้ตัวเดิม
      for (final status in OrderStatus.values) {
        expect(OrderStatus.tryParse(status.apiValue), status);
      }
    });

    test('tryParse ค่าที่ไม่รู้จักหรือ null → null', () {
      // ตรวจสอบกรณีส่งค่ามั่ว (bogus), null หรือตัวเลขเข้ามา ต้องคืนค่า null อย่างปลอดภัย
      expect(OrderStatus.tryParse('bogus'), isNull);
      expect(OrderStatus.tryParse(null), isNull);
      expect(OrderStatus.tryParse(42), isNull);
    });

    test('fromApi ใช้ pendingPayment เมื่อไม่รู้จักค่า', () {
      // ตรวจสอบเมธอด fromApi: หากรู้จักค่าให้คืนสถานะนั้น แต่ถ้าไม่รู้จักให้ใช้ค่าเริ่มต้นเป็น pendingPayment
      expect(OrderStatus.fromApi('paid'), OrderStatus.paid);
      expect(OrderStatus.fromApi('bogus'), OrderStatus.pendingPayment);
    });

    test('isActive: ออเดอร์ที่ยังดำเนินอยู่', () {
      // กำหนดตารางความจริงของสถานะที่ถือว่า "ออเดอร์ยังไม่จบกระบวนการ (Active)"
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
      // ตรวจสอบว่าทดสอบครบทุกค่าใน Enum และผลลัพธ์ของ getter .isActive ตรงตามตาราง
      expect(expected.length, OrderStatus.values.length);
      expected.forEach((status, isActive) {
        expect(status.isActive, isActive, reason: status.name);
      });
    });

    test('isPaid: จ่ายเงินเข้าระบบแล้ว', () {
      // กำหนดตารางความจริงของสถานะที่ถือว่า "มีการชำระเงินเข้าระบบแล้ว" (รวมถึงเคสที่กำลังขอคืนเงินหรือคืนเงินแล้ว)
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
      // ตรวจสอบว่าทดสอบครบทุกค่าใน Enum และผลลัพธ์ของ getter .isPaid ตรงตามตาราง
      expect(expected.length, OrderStatus.values.length);
      expected.forEach((status, isPaid) {
        expect(status.isPaid, isPaid, reason: status.name);
      });
    });

    test('canConfirmReceived ได้เฉพาะ paid และ readyForMeetup', () {
      // ตรวจสอบสิทธิ์การกดปุ่ม "ยืนยันรับสินค้า": ผู้ซื้อจะกดได้เฉพาะตอนที่จ่ายเงินแล้วหรือพร้อมนัดรับเท่านั้น
      for (final status in OrderStatus.values) {
        final expected =
            status == OrderStatus.paid || status == OrderStatus.readyForMeetup;
        expect(status.canConfirmReceived, expected, reason: status.name);
      }
    });

    test('label ของแต่ละสถานะ', () {
      // ตรวจสอบข้อความภาษาอังกฤษที่จะนำไปแสดงผลบนหน้าจอ UI สำหรับแต่ละสถานะ
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
      // ตรวจสอบโทนสี (StatusTone) ของป้ายสถานะ (Badge) เช่น สีเหลืองอำพัน=รอดำเนินการ, สีฟ้า=กำลังดำเนินการ, สีเขียว=สำเร็จ, สีแดง=ยกเลิก/หมดอายุ
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

  // =========================================================================
  // กลุ่มทดสอบที่ 2: สถานะของสินค้า (ProductStatus)
  // =========================================================================
  group('ProductStatus', () {
    test('apiValue ตรงกับ ENUM ใน DB', () {
      // ตรวจสอบความตรงกันของค่า String ระหว่างแอปกับ ENUM ในฐานข้อมูล
      expect(ProductStatus.pendingReview.apiValue, 'pending_review');
      expect(ProductStatus.changesRequested.apiValue, 'changes_requested');
      expect(ProductStatus.available.apiValue, 'available');
    });

    test('tryParse แปลงกลับได้ครบทุกค่า', () {
      // วนลูปตรวจสอบการแปลงไป-กลับของทุกสถานะสินค้า
      for (final status in ProductStatus.values) {
        expect(ProductStatus.tryParse(status.apiValue), status);
      }
    });

    test('tryParse ค่าที่ไม่รู้จักหรือ null → null', () {
      expect(ProductStatus.tryParse('bogus'), isNull);
      expect(ProductStatus.tryParse(null), isNull);
    });

    test('fromApi ใช้ available เมื่อไม่รู้จักค่า', () {
      // ตรวจสอบว่าถ้า API ส่งสถานะสินค้าที่ไม่รู้จักมา จะกำหนดค่าสำรองเป็น available
      expect(ProductStatus.fromApi('sold'), ProductStatus.sold);
      expect(ProductStatus.fromApi('bogus'), ProductStatus.available);
    });
  });

  // =========================================================================
  // ส่วนที่ 3: ทดสอบค่าคงที่ระยะเวลาการชำระเงิน
  // =========================================================================
  test('kPaymentWindow คือ 30 นาที', () {
    // ตรวจสอบว่ากรอบเวลาที่อนุญาตให้ชำระเงินหลังสร้างออเดอร์ถูกตั้งไว้ที่ 30 นาที
    expect(kPaymentWindow, const Duration(minutes: 30));
  });
}
