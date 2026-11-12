import 'package:flutter_test/flutter_test.dart';
import 'package:uni_swap/model/format.dart';
import 'package:uni_swap/model/json_utils.dart';

void main() {
  group('format.dart', () {
    group('formatPrice', () {
      test('ราคาไม่มีเศษแสดงเป็นจำนวนเต็ม', () {
        expect(formatPrice(45), '45');
        expect(formatPrice(450.0), '450');
        expect(formatPrice(0), '0');
      });

      test('ราคามีเศษแสดงสองตำแหน่ง (ไม่ปัดเป็น 13)', () {
        expect(formatPrice(12.5), '12.50');
        expect(formatPrice(0.99), '0.99');
      });

      test('เศษมากกว่าสองตำแหน่งถูกปัดเป็นสองตำแหน่ง', () {
        expect(formatPrice(1234.567), '1234.57');
      });
    });

    group('formatPriceTHB', () {
      test('ราคา 0 แสดงเป็น Free', () {
        expect(formatPriceTHB(0), 'Free');
      });

      test('ราคาปกติต่อท้ายด้วย THB', () {
        expect(formatPriceTHB(45), '45 THB');
        expect(formatPriceTHB(12.5), '12.50 THB');
      });
    });

    test('orderLabel สร้างรหัสออเดอร์ที่แสดงให้ผู้ใช้', () {
      expect(orderLabel(8), '#US-8');
      expect(orderLabel(1024), '#US-1024');
    });
  });

  group('json_utils.dart', () {
    group('jsonInt', () {
      test('null → null', () => expect(jsonInt(null), isNull));
      test('int คืนค่าเดิม', () => expect(jsonInt(5), 5));
      test('double ถูกตัดทศนิยม', () => expect(jsonInt(5.9), 5));
      test('string ตัวเลข (MySQL) แปลงได้', () => expect(jsonInt('7'), 7));
      test('ตัดช่องว่างหัวท้าย', () => expect(jsonInt(' 8 '), 8));
      test('string ที่ไม่ใช่ตัวเลข → null', () {
        expect(jsonInt('abc'), isNull);
        expect(jsonInt('12.5'), isNull);
        expect(jsonInt(''), isNull);
      });
    });

    group('jsonDouble', () {
      test('null → null', () => expect(jsonDouble(null), isNull));
      test('double คืนค่าเดิม', () => expect(jsonDouble(1.5), 1.5));
      test('int แปลงเป็น double', () {
        expect(jsonDouble(3), isA<double>());
        expect(jsonDouble(3), 3.0);
      });
      test('DECIMAL ที่เป็น string แปลงได้', () {
        expect(jsonDouble('12.50'), 12.5);
        expect(jsonDouble(' 2.5 '), 2.5);
      });
      test('string ที่ไม่ใช่ตัวเลข → null', () {
        expect(jsonDouble('x'), isNull);
      });
    });

    group('jsonString', () {
      test('null → null', () => expect(jsonString(null), isNull));
      test('string คืนค่าเดิม', () => expect(jsonString('abc'), 'abc'));
      test('ค่าอื่นแปลงด้วย toString', () {
        expect(jsonString(42), '42');
        expect(jsonString(true), 'true');
      });
    });

    group('jsonBool', () {
      test('null → null', () => expect(jsonBool(null), isNull));
      test('bool คืนค่าเดิม', () {
        expect(jsonBool(true), true);
        expect(jsonBool(false), false);
      });
      test('ตัวเลข: 0 = false, อื่น ๆ = true', () {
        expect(jsonBool(0), false);
        expect(jsonBool(1), true);
        expect(jsonBool(2), true);
      });
      test('string ไม่สนตัวพิมพ์เล็กใหญ่และช่องว่าง', () {
        expect(jsonBool('TRUE'), true);
        expect(jsonBool(' 0 '), false);
        expect(jsonBool('false'), false);
        expect(jsonBool('1'), true);
      });
      test('string อื่น → null', () => expect(jsonBool('yes'), isNull));
    });

    group('jsonDateTime', () {
      test('null / ว่าง / ไม่ใช่วันที่ → null', () {
        expect(jsonDateTime(null), isNull);
        expect(jsonDateTime(''), isNull);
        expect(jsonDateTime('   '), isNull);
        expect(jsonDateTime('not a date'), isNull);
      });

      test('ISO-8601 แบบ UTC แปลงเป็นเวลาเดิม (เทียบใน UTC)', () {
        final parsed = jsonDateTime('2026-11-01T09:00:00.000Z');
        expect(parsed, isNotNull);
        expect(parsed!.toUtc(), DateTime.utc(2026, 11, 1, 9));
      });

      test('ไม่มี timezone ถือเป็นเวลาท้องถิ่น', () {
        expect(jsonDateTime('2026-11-01T09:00:00'), DateTime(2026, 11, 1, 9));
      });

      test('รับ DateTime ได้โดยตรง', () {
        final source = DateTime.utc(2026, 1, 2, 3);
        expect(jsonDateTime(source)!.toUtc(), source);
      });
    });

    group('jsonObject', () {
      test('Map ถูกคัดลอกเป็น Map<String, dynamic>', () {
        final result = jsonObject(<dynamic, dynamic>{'a': 1});
        expect(result, {'a': 1});
      });

      test('ไม่ใช่ Map → map ว่าง', () {
        expect(jsonObject(null), isEmpty);
        expect(jsonObject('text'), isEmpty);
        expect(jsonObject([1, 2]), isEmpty);
      });
    });

    group('jsonObjectList', () {
      test('ไม่ใช่ List → list ว่าง', () {
        expect(jsonObjectList(null), isEmpty);
        expect(jsonObjectList({'a': 1}), isEmpty);
      });

      test('กรองเอาเฉพาะสมาชิกที่เป็น Map', () {
        final result = jsonObjectList([
          {'a': 1},
          'text',
          3,
          {'b': 2},
        ]);
        expect(result, [
          {'a': 1},
          {'b': 2},
        ]);
      });
    });

    test('jsonParseList แปลงแต่ละ object ด้วย parser ที่ให้มา', () {
      final ids = jsonParseList<int>([
        {'id': 1},
        {'id': 2},
      ], (json) => json['id'] as int);
      expect(ids, [1, 2]);
    });

    test('jsonParseList ของค่าที่ไม่ใช่ list ได้ list ว่าง', () {
      expect(jsonParseList<int>(null, (json) => 0), isEmpty);
    });
  });
}
