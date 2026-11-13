import 'package:flutter_test/flutter_test.dart';
import 'package:uni_swap/model/enums.dart';

/// ตรวจพฤติกรรมพื้นฐานที่ enum ทุกตัวต้องมีเหมือนกัน
void _checkEnum<T extends Enum>({
  required String name,
  required List<T> values,
  required String Function(T) wire,
  required T? Function(Object?) parse,
}) {
  group(name, () {
    test('tryParse แปลง apiValue กลับเป็น enum เดิมได้ครบทุกค่า', () {
      for (final value in values) {
        expect(parse(wire(value)), value, reason: value.name);
      }
    });

    test('tryParse ค่าที่ไม่รู้จักหรือ null → null', () {
      expect(parse('__unknown__'), isNull);
      expect(parse(null), isNull);
    });

    test('apiValue ไม่ซ้ำกัน', () {
      expect(values.map(wire).toSet().length, values.length);
    });
  });
}

void main() {
  _checkEnum<ResidenceZone>(
    name: 'ResidenceZone',
    values: ResidenceZone.values,
    wire: (e) => e.apiValue,
    parse: ResidenceZone.tryParse,
  );
  _checkEnum<UserRole>(
    name: 'UserRole',
    values: UserRole.values,
    wire: (e) => e.apiValue,
    parse: UserRole.tryParse,
  );
  _checkEnum<UserStatus>(
    name: 'UserStatus',
    values: UserStatus.values,
    wire: (e) => e.apiValue,
    parse: UserStatus.tryParse,
  );
  _checkEnum<LocationRequestStatus>(
    name: 'LocationRequestStatus',
    values: LocationRequestStatus.values,
    wire: (e) => e.apiValue,
    parse: LocationRequestStatus.tryParse,
  );
  _checkEnum<ItemCondition>(
    name: 'ItemCondition',
    values: ItemCondition.values,
    wire: (e) => e.apiValue,
    parse: ItemCondition.tryParse,
  );
  _checkEnum<UrgencyLevel>(
    name: 'UrgencyLevel',
    values: UrgencyLevel.values,
    wire: (e) => e.apiValue,
    parse: UrgencyLevel.tryParse,
  );
  _checkEnum<RejectReason>(
    name: 'RejectReason',
    values: RejectReason.values,
    wire: (e) => e.apiValue,
    parse: RejectReason.tryParse,
  );
  _checkEnum<OrderPerspective>(
    name: 'OrderPerspective',
    values: OrderPerspective.values,
    wire: (e) => e.apiValue,
    parse: OrderPerspective.tryParse,
  );
  _checkEnum<PaymentMethod>(
    name: 'PaymentMethod',
    values: PaymentMethod.values,
    wire: (e) => e.apiValue,
    parse: PaymentMethod.tryParse,
  );
  _checkEnum<PaymentStatus>(
    name: 'PaymentStatus',
    values: PaymentStatus.values,
    wire: (e) => e.apiValue,
    parse: PaymentStatus.tryParse,
  );
  _checkEnum<SellerTransferStatus>(
    name: 'SellerTransferStatus',
    values: SellerTransferStatus.values,
    wire: (e) => e.apiValue,
    parse: SellerTransferStatus.tryParse,
  );
  group('ค่า apiValue ที่ต้องตรงกับ backend', () {
    test('ItemCondition.brandNew ส่งเป็น "new"', () {
      expect(ItemCondition.brandNew.apiValue, 'new');
      expect(ItemCondition.likeNew.apiValue, 'like_new');
    });

    test('PaymentMethod ตรงกับที่ app.js รับ', () {
      expect(
        PaymentMethod.values.map((m) => m.apiValue),
        containsAll(['gateway', 'bank_transfer', 'cash', 'free']),
      );
    });

    test('RejectReason ตรงกับที่ app.js รับ', () {
      expect(RejectReason.values.map((r) => r.apiValue).toSet(), {
        'prohibited_item',
        'misleading',
        'poor_photos',
        'duplicate',
        'other',
      });
    });
  });

  group('fromApi: ค่าตั้งต้นเมื่อไม่รู้จักค่า', () {
    test('enum ที่มีค่า fallback', () {
      expect(ResidenceZone.fromApi('x'), ResidenceZone.onCampus);
      expect(UserRole.fromApi(null), UserRole.member);
      expect(UserStatus.fromApi('x'), UserStatus.pending);
      expect(LocationRequestStatus.fromApi('x'), LocationRequestStatus.pending);
      expect(UrgencyLevel.fromApi('x'), UrgencyLevel.normal);
      expect(PaymentMethod.fromApi('x'), PaymentMethod.gateway);
      expect(PaymentStatus.fromApi('x'), PaymentStatus.pending);
      expect(SellerTransferStatus.fromApi('x'), SellerTransferStatus.notReady);
    });

    test('enum ที่ fromApi คืน null เมื่อไม่รู้จักค่า', () {
      expect(ItemCondition.fromApi('x'), isNull);
      expect(RejectReason.fromApi('x'), isNull);
      expect(OrderPerspective.fromApi('x'), isNull);
    });

    test('fromApi รับค่าที่ถูกต้องตามปกติ', () {
      expect(UserRole.fromApi('admin'), UserRole.admin);
      expect(ResidenceZone.fromApi('off_campus'), ResidenceZone.offCampus);
      expect(ItemCondition.fromApi('like_new'), ItemCondition.likeNew);
    });
  });
}
