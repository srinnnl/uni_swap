//ทดสอบค่าคงที่ Enum ทั้ง 15 ตัว (เช่น UserRole, PaymentMethod, ItemCondition)
//ว่าตรงกับฝั่ง Backend และมีค่าสำรอง (Fallback) ถูกต้อง

// นำเข้าแพ็กเกจหลักสำหรับการเขียน Unit Test ใน Flutter
import 'package:flutter_test/flutter_test.dart';
// นำเข้าไฟล์รวมค่าคงที่แบบ Enum ทั้งหมดของแอปพลิเคชัน
import 'package:uni_swap/model/enums.dart';

/// ตรวจพฤติกรรมพื้นฐานที่ enum ทุกตัวต้องมีเหมือนกัน
// ฟังก์ชันตัวช่วย (Generic Helper) สำหรับรันชุดทดสอบมาตรฐานให้กับ Enum ทุกชนิดในระบบ
void _checkEnum<T extends Enum>({
  required String name, // ชื่อของ Enum สำหรับแสดงในหัวข้อการทดสอบ
  required List<T> values, // รายการค่าทั้งหมดที่มีอยู่ใน Enum นั้นๆ
  required String Function(T)
  wire, // ฟังก์ชันแปลงจาก Enum เป็น String สำหรับส่ง API (apiValue)
  required T? Function(Object?)
  parse, // ฟังก์ชันแปลงจาก String กลับเป็น Enum (tryParse)
}) {
  group(name, () {
    test('tryParse แปลง apiValue กลับเป็น enum เดิมได้ครบทุกค่า', () {
      // วนลูปตรวจสอบว่าทุกค่าใน Enum เมื่อแปลงเป็น String แล้วแปลงกลับ จะต้องได้ตัวเดิมเป๊ะ
      for (final value in values) {
        expect(parse(wire(value)), value, reason: value.name);
      }
    });

    test('tryParse ค่าที่ไม่รู้จักหรือ null → null', () {
      // ตรวจสอบกรณีได้รับค่าแปลกปลอมหรือค่าว่าง (null) ต้องคืนค่า null โดยไม่โยน Error
      expect(parse('__unknown__'), isNull);
      expect(parse(null), isNull);
    });

    test('apiValue ไม่ซ้ำกัน', () {
      // แปลงรายการทั้งหมดเป็น Set (ซึ่งตัดตัวซ้ำออก) แล้วเทียบจำนวน เพื่อยืนยันว่าไม่มีค่า apiValue ชนกัน
      expect(values.map(wire).toSet().length, values.length);
    });
  });
}

void main() {
  // =========================================================================
  // ส่วนที่ 1: รันชุดทดสอบมาตรฐาน (_checkEnum) กับ Enum ทั้ง 15 ตัวในระบบ
  // =========================================================================
  _checkEnum<ResidenceZone>(
    name: 'ResidenceZone', // โซนที่พักอาศัย (ใน/นอกมหาวิทยาลัย)
    values: ResidenceZone.values,
    wire: (e) => e.apiValue,
    parse: ResidenceZone.tryParse,
  );
  _checkEnum<UserRole>(
    name: 'UserRole', // บทบาทผู้ใช้งาน (สมาชิกทั่วไป/แอดมิน)
    values: UserRole.values,
    wire: (e) => e.apiValue,
    parse: UserRole.tryParse,
  );
  _checkEnum<UserStatus>(
    name: 'UserStatus', // สถานะบัญชีผู้ใช้
    values: UserStatus.values,
    wire: (e) => e.apiValue,
    parse: UserStatus.tryParse,
  );
  _checkEnum<LocationRequestStatus>(
    name: 'LocationRequestStatus', // สถานะคำขอเพิ่มสถานที่นัดรับ
    values: LocationRequestStatus.values,
    wire: (e) => e.apiValue,
    parse: LocationRequestStatus.tryParse,
  );
  _checkEnum<ItemCondition>(
    name: 'ItemCondition', // สภาพสินค้า (ใหม่/เหมือนใหม่ ฯลฯ)
    values: ItemCondition.values,
    wire: (e) => e.apiValue,
    parse: ItemCondition.tryParse,
  );
  _checkEnum<UrgencyLevel>(
    name: 'UrgencyLevel', // ระดับความเร่งด่วน
    values: UrgencyLevel.values,
    wire: (e) => e.apiValue,
    parse: UrgencyLevel.tryParse,
  );
  _checkEnum<RejectReason>(
    name: 'RejectReason', // เหตุผลการปฏิเสธโพสต์สินค้า
    values: RejectReason.values,
    wire: (e) => e.apiValue,
    parse: RejectReason.tryParse,
  );
  _checkEnum<OrderPerspective>(
    name: 'OrderPerspective', // มุมมองคำสั่งซื้อ (ผู้ซื้อ/ผู้ขาย)
    values: OrderPerspective.values,
    wire: (e) => e.apiValue,
    parse: OrderPerspective.tryParse,
  );
  _checkEnum<PaymentMethod>(
    name: 'PaymentMethod', // ช่องทางการชำระเงิน
    values: PaymentMethod.values,
    wire: (e) => e.apiValue,
    parse: PaymentMethod.tryParse,
  );
  _checkEnum<PaymentStatus>(
    name: 'PaymentStatus', // สถานะการชำระเงิน
    values: PaymentStatus.values,
    wire: (e) => e.apiValue,
    parse: PaymentStatus.tryParse,
  );
  _checkEnum<SellerTransferStatus>(
    name: 'SellerTransferStatus', // สถานะการโอนเงินให้ผู้ขาย
    values: SellerTransferStatus.values,
    wire: (e) => e.apiValue,
    parse: SellerTransferStatus.tryParse,
  );
  _checkEnum<RefundStatus>(
    name: 'RefundStatus', // สถานะการคืนเงิน
    values: RefundStatus.values,
    wire: (e) => e.apiValue,
    parse: RefundStatus.tryParse,
  );
  _checkEnum<ReportType>(
    name: 'ReportType', // ประเภทของการรายงานปัญหา
    values: ReportType.values,
    wire: (e) => e.apiValue,
    parse: ReportType.tryParse,
  );
  _checkEnum<ReportStatus>(
    name: 'ReportStatus', // สถานะการจัดการรายงานปัญหา
    values: ReportStatus.values,
    wire: (e) => e.apiValue,
    parse: ReportStatus.tryParse,
  );
  _checkEnum<BankAccountStatus>(
    name: 'BankAccountStatus', // สถานะการยืนยันบัญชีธนาคาร
    values: BankAccountStatus.values,
    wire: (e) => e.apiValue,
    parse: BankAccountStatus.tryParse,
  );

  // =========================================================================
  // ส่วนที่ 2: ตรวจสอบความตรงกันของค่า String (apiValue) ระหว่างแอปกับฝั่ง Backend
  // =========================================================================
  group('ค่า apiValue ที่ต้องตรงกับ backend', () {
    test('ItemCondition.brandNew ส่งเป็น "new"', () {
      // เนื่องจากคำว่า new เป็นคำสงวนในภาษา Dart จึงตั้งชื่อในโค้ดว่า brandNew แต่ตอนส่ง API ต้องเป็น 'new'
      expect(ItemCondition.brandNew.apiValue, 'new');
      expect(ItemCondition.likeNew.apiValue, 'like_new');
    });

    test('PaymentMethod ตรงกับที่ app.js รับ', () {
      // ตรวจสอบว่าช่องทางชำระเงินมีครบตามที่ Backend (app.js) รองรับ
      expect(
        PaymentMethod.values.map((m) => m.apiValue),
        containsAll(['gateway', 'bank_transfer', 'cash', 'free']),
      );
    });

    test('RejectReason ตรงกับที่ app.js รับ', () {
      // ตรวจสอบว่าเหตุผลการปฏิเสธโพสต์ตรงกับฝั่ง Backend ทั้งหมดทุกตัว
      expect(RejectReason.values.map((r) => r.apiValue).toSet(), {
        'prohibited_item',
        'misleading',
        'poor_photos',
        'duplicate',
        'other',
      });
    });

    test('ReportType ตรงกับที่ app.js รับ', () {
      // ตรวจสอบว่าประเภทการแจ้งปัญหาตรงกับฝั่ง Backend ทั้งหมดทุกตัว
      expect(ReportType.values.map((r) => r.apiValue).toSet(), {
        'product_problem',
        'payment_problem',
        'refund_problem',
        'seller_problem',
        'other',
      });
    });
  });

  // =========================================================================
  // ส่วนที่ 3: ทดสอบพฤติกรรมของเมธอด fromApi (การกำหนดค่าสำรองเมื่อเจอค่าไม่รู้จัก)
  // =========================================================================
  group('fromApi: ค่าตั้งต้นเมื่อไม่รู้จักค่า', () {
    test('enum ที่มีค่า fallback', () {
      // ตรวจสอบว่าหาก API ส่งค่าแปลกปลอม ('x') หรือ null มา ระบบจะเลือกค่าตั้งต้น (Fallback) ที่ปลอดภัยให้แทน
      expect(ResidenceZone.fromApi('x'), ResidenceZone.onCampus);
      expect(UserRole.fromApi(null), UserRole.member);
      expect(UserStatus.fromApi('x'), UserStatus.pending);
      expect(LocationRequestStatus.fromApi('x'), LocationRequestStatus.pending);
      expect(UrgencyLevel.fromApi('x'), UrgencyLevel.normal);
      expect(PaymentMethod.fromApi('x'), PaymentMethod.gateway);
      expect(PaymentStatus.fromApi('x'), PaymentStatus.pending);
      expect(SellerTransferStatus.fromApi('x'), SellerTransferStatus.notReady);
      expect(RefundStatus.fromApi('x'), RefundStatus.pending);
      expect(ReportType.fromApi('x'), ReportType.other);
      expect(ReportStatus.fromApi('x'), ReportStatus.pending);
      expect(BankAccountStatus.fromApi('x'), BankAccountStatus.pending);
    });

    test('enum ที่ fromApi คืน null เมื่อไม่รู้จักค่า', () {
      // ตรวจสอบกลุ่ม Enum ที่ไม่มีค่าตั้งต้นสำรอง ซึ่งจะต้องคืนค่า null ออกมาตรงๆ เมื่อเจอค่าที่ไม่รู้จัก
      expect(ItemCondition.fromApi('x'), isNull);
      expect(RejectReason.fromApi('x'), isNull);
      expect(OrderPerspective.fromApi('x'), isNull);
    });

    test('fromApi รับค่าที่ถูกต้องตามปกติ', () {
      // ตรวจสอบกรณีปกติเมื่อ API ส่งค่าที่ถูกต้องมา ระบบต้องแปลงเป็น Enum ตัวนั้นได้ตรงตามต้องการ
      expect(UserRole.fromApi('admin'), UserRole.admin);
      expect(ResidenceZone.fromApi('off_campus'), ResidenceZone.offCampus);
      expect(ItemCondition.fromApi('like_new'), ItemCondition.likeNew);
    });
  });
}
