// นำเข้าแพ็กเกจหลักสำหรับการเขียน Unit Test ใน Flutter
import 'package:flutter_test/flutter_test.dart';
// นำเข้าไฟล์ฟังก์ชันจัดรูปแบบการแสดงผล (Format) และตัวช่วยแปลงข้อมูล JSON (JSON Utils)
import 'package:uni_swap/model/format.dart';
import 'package:uni_swap/model/json_utils.dart';

void main() {
  // =========================================================================
  // ส่วนที่ 1: ทดสอบฟังก์ชันจัดรูปแบบข้อความและตัวเลข (format.dart)
  // =========================================================================
  group('format.dart', () {
    // กลุ่มทดสอบการแสดงผลตัวเลขราคาสินค้า
    group('formatPrice', () {
      test('ราคาไม่มีเศษแสดงเป็นจำนวนเต็ม', () {
        // ตรวจสอบว่าราคาที่เป็นเลขจำนวนเต็ม หรือลงท้ายด้วย .0 จะตัดทศนิยมทิ้งเพื่อให้ดูสะอาดตา
        expect(formatPrice(45), '45');
        expect(formatPrice(450.0), '450');
        expect(formatPrice(0), '0');
      });

      test('ราคามีเศษแสดงสองตำแหน่ง (ไม่ปัดเป็น 13)', () {
        // ตรวจสอบว่าราคาที่มีทศนิยมจะถูกเติมศูนย์ให้ครบ 2 ตำแหน่งเสมอ และไม่ปัดเศษทิ้ง
        expect(formatPrice(12.5), '12.50');
        expect(formatPrice(0.99), '0.99');
      });

      test('เศษมากกว่าสองตำแหน่งถูกปัดเป็นสองตำแหน่ง', () {
        // ตรวจสอบการปัดเศษทศนิยมตำแหน่งที่ 3 ให้เหลือ 2 ตำแหน่งตามหลักคณิตศาสตร์
        expect(formatPrice(1234.567), '1234.57');
      });
    });

    // กลุ่มทดสอบการแสดงผลราคาพร้อมหน่วยสกุลเงิน (THB) หรือคำว่า Free
    group('formatPriceTHB', () {
      test('ราคา 0 แสดงเป็น Free', () {
        // ตรวจสอบว่าถ้าสินค้าแจกฟรี (ราคา 0) ต้องแสดงคำว่า 'Free' แทน '0 THB'
        expect(formatPriceTHB(0), 'Free');
      });

      test('ราคาปกติต่อท้ายด้วย THB', () {
        // ตรวจสอบการต่อท้ายหน่วยเงินบาท (THB) ทั้งกรณีจำนวนเต็มและมีทศนิยม
        expect(formatPriceTHB(45), '45 THB');
        expect(formatPriceTHB(12.5), '12.50 THB');
      });
    });

    test('orderLabel สร้างรหัสออเดอร์ที่แสดงให้ผู้ใช้', () {
      // ตรวจสอบการประกอบเลข ID ออเดอร์ให้เป็นรหัสอ้างอิงรูปแบบ '#US-<เลขไอดี>'
      expect(orderLabel(8), '#US-8');
      expect(orderLabel(1024), '#US-1024');
    });
  });

  // =========================================================================
  // ส่วนที่ 2: ทดสอบตัวช่วยแปลงชนิดข้อมูลจาก JSON อย่างปลอดภัย (json_utils.dart)
  // ป้องกันแอปพังเวลาฐานข้อมูล (เช่น MySQL) ส่งตัวเลขหรือบูลีนมาในรูปแบบ String
  // =========================================================================
  group('json_utils.dart', () {
    // กลุ่มทดสอบการแปลงค่าให้เป็นจำนวนเต็ม (int?)
    group('jsonInt', () {
      test('null → null', () => expect(jsonInt(null), isNull));
      test('int คืนค่าเดิม', () => expect(jsonInt(5), 5));
      test(
        'double ถูกตัดทศนิยม',
        () => expect(jsonInt(5.9), 5),
      ); // ตัดเศษทศนิยมออก (truncate)
      test(
        'string ตัวเลข (MySQL) แปลงได้',
        () => expect(jsonInt('7'), 7),
      ); // รองรับตัวเลขที่ส่งมาเป็นข้อความ
      test('ตัดช่องว่างหัวท้าย', () => expect(jsonInt(' 8 '), 8));
      test('string ที่ไม่ใช่ตัวเลข → null', () {
        // ตรวจสอบว่าถ้าเป็นตัวอักษร ทศนิยมในรูปแบบข้อความ หรือค่าว่าง ต้องคืนค่า null
        expect(jsonInt('abc'), isNull);
        expect(jsonInt('12.5'), isNull);
        expect(jsonInt(''), isNull);
      });
    });

    // กลุ่มทดสอบการแปลงค่าให้เป็นเลขทศนิยม (double?)
    group('jsonDouble', () {
      test('null → null', () => expect(jsonDouble(null), isNull));
      test('double คืนค่าเดิม', () => expect(jsonDouble(1.5), 1.5));
      test('int แปลงเป็น double', () {
        // ตรวจสอบว่าถ้าได้จำนวนเต็มมา จะถูกแปลงชนิดข้อมูลเป็น double
        expect(jsonDouble(3), isA<double>());
        expect(jsonDouble(3), 3.0);
      });
      test('DECIMAL ที่เป็น string แปลงได้', () {
        // รองรับฟิลด์ DECIMAL จากฐานข้อมูลที่มักถูกส่งผ่าน JSON มาเป็น String
        expect(jsonDouble('12.50'), 12.5);
        expect(jsonDouble(' 2.5 '), 2.5);
      });
      test('string ที่ไม่ใช่ตัวเลข → null', () {
        expect(jsonDouble('x'), isNull);
      });
    });

    // กลุ่มทดสอบการแปลงค่าให้เป็นข้อความ (String?)
    group('jsonString', () {
      test('null → null', () => expect(jsonString(null), isNull));
      test('string คืนค่าเดิม', () => expect(jsonString('abc'), 'abc'));
      test('ค่าอื่นแปลงด้วย toString', () {
        // ตรวจสอบว่าหากได้ int หรือ bool มา จะถูกแปลงเป็น String อัตโนมัติ
        expect(jsonString(42), '42');
        expect(jsonString(true), 'true');
      });
    });

    // กลุ่มทดสอบการแปลงค่าให้เป็นค่าความจริง (bool?)
    group('jsonBool', () {
      test('null → null', () => expect(jsonBool(null), isNull));
      test('bool คืนค่าเดิม', () {
        expect(jsonBool(true), true);
        expect(jsonBool(false), false);
      });
      test('ตัวเลข: 0 = false, อื่น ๆ = true', () {
        // รองรับฐานข้อมูลที่เก็บค่า Boolean เป็น TINYINT (0 กับ 1)
        expect(jsonBool(0), false);
        expect(jsonBool(1), true);
        expect(jsonBool(2), true);
      });
      test('string ไม่สนตัวพิมพ์เล็กใหญ่และช่องว่าง', () {
        // รองรับข้อความ 'true', 'false', '1', '0' ไม่ว่าจะเป็นตัวพิมพ์เล็กหรือใหญ่
        expect(jsonBool('TRUE'), true);
        expect(jsonBool(' 0 '), false);
        expect(jsonBool('false'), false);
        expect(jsonBool('1'), true);
      });
      test('string อื่น → null', () => expect(jsonBool('yes'), isNull));
    });

    // กลุ่มทดสอบการแปลงข้อมูลวันและเวลา (DateTime?)
    group('jsonDateTime', () {
      test('null / ว่าง / ไม่ใช่วันที่ → null', () {
        // ตรวจสอบค่าที่แปลงไม่ได้ ต้องคืนค่า null โดยไม่โยน FormatException
        expect(jsonDateTime(null), isNull);
        expect(jsonDateTime(''), isNull);
        expect(jsonDateTime('   '), isNull);
        expect(jsonDateTime('not a date'), isNull);
      });

      test('ISO-8601 แบบ UTC แปลงเป็นเวลาเดิม (เทียบใน UTC)', () {
        // ตรวจสอบการแปลงสตริงเวลามาตรฐาน ISO-8601 ที่ลงท้ายด้วย Z (UTC)
        final parsed = jsonDateTime('2026-11-01T09:00:00.000Z');
        expect(parsed, isNotNull);
        expect(parsed!.toUtc(), DateTime.utc(2026, 11, 1, 9));
      });

      test('ไม่มี timezone ถือเป็นเวลาท้องถิ่น', () {
        // ตรวจสอบสตริงวันที่ที่ไม่ได้ระบุ Timezone ระบบต้องตีความเป็น Local Time
        expect(jsonDateTime('2026-11-01T09:00:00'), DateTime(2026, 11, 1, 9));
      });

      test('รับ DateTime ได้โดยตรง', () {
        // ตรวจสอบกรณีที่ข้อมูลถูกแปลงเป็นออบเจกต์ DateTime มาอยู่แล้ว
        final source = DateTime.utc(2026, 1, 2, 3);
        expect(jsonDateTime(source)!.toUtc(), source);
      });
    });

    // กลุ่มทดสอบการแปลงค่าให้เป็น JSON Object (Map<String, dynamic>)
    group('jsonObject', () {
      test('Map ถูกคัดลอกเป็น Map<String, dynamic>', () {
        final result = jsonObject(<dynamic, dynamic>{'a': 1});
        expect(result, {'a': 1});
      });

      test('ไม่ใช่ Map → map ว่าง', () {
        // ตรวจสอบว่าถ้าข้อมูลไม่ใช่ Map (เช่น null, String, List) ต้องคืนค่า Map ว่าง {} แทน
        expect(jsonObject(null), isEmpty);
        expect(jsonObject('text'), isEmpty);
        expect(jsonObject([1, 2]), isEmpty);
      });
    });

    // กลุ่มทดสอบการแปลงค่าให้เป็นรายการของ JSON Object (List>)
    group('jsonObjectList', () {
      test('ไม่ใช่ List → list ว่าง', () {
        expect(jsonObjectList(null), isEmpty);
        expect(jsonObjectList({'a': 1}), isEmpty);
      });

      test('กรองเอาเฉพาะสมาชิกที่เป็น Map', () {
        // ตรวจสอบว่าหากใน List มีข้อมูลขยะปนมา (เช่น String หรือ int) จะถูกคัดทิ้ง เหลือเฉพาะตัวที่เป็น Map
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

    // กลุ่มทดสอบฟังก์ชันช่วยแปลง List ของ JSON ให้เป็น List ของ Model ตามฟังก์ชันที่ส่งเข้าไป
    test('jsonParseList แปลงแต่ละ object ด้วย parser ที่ให้มา', () {
      final ids = jsonParseList<int>([
        {'id': 1},
        {'id': 2},
      ], (json) => json['id'] as int);
      expect(ids, [1, 2]);
    });

    test('jsonParseList ของค่าที่ไม่ใช่ list ได้ list ว่าง', () {
      // ตรวจสอบกรณีส่ง null หรือค่าที่ไม่ใช่ List เข้ามา ต้องได้ List ว่าง [] อย่างปลอดภัย
      expect(jsonParseList<int>(null, (json) => 0), isEmpty);
    });
  });
}
