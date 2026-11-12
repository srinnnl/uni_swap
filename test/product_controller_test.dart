// นำเข้าแพ็กเกจหลักสำหรับการเขียน Unit Test ใน Flutter
import 'package:flutter_test/flutter_test.dart';
// นำเข้า ProductController ที่ต้องการนำมาทดสอบ
import 'package:uni_swap/controller/product_controller.dart';

// นำเข้าตัวช่วยจำลอง API (Fake API) สำหรับการทดสอบ
import 'test_helpers.dart';

void main() {
  // ประกาศตัวแปรเก็บประวัติการเรียก API และตัวแปร ProductController
  late List<RecordedCall> calls;
  late ProductController products;

  // รีเซ็ตประวัติการเรียก API และสร้าง ProductController ใหม่ก่อนรันแต่ละเทสต์ย่อย
  setUp(() {
    calls = [];
    products = ProductController(fakeApi(calls));
  });

  // =========================================================================
  // กลุ่มทดสอบที่ 1: การค้นหาและเรียกดูรายการสินค้า (Browse & Filters)
  // =========================================================================
  group('browse', () {
    test('ค่าตั้งต้น: sort=newest page=1 limit=20 และไม่มีตัวกรอง', () async {
      await products.browse();

      // ตรวจสอบว่าหากไม่ระบุเงื่อนไขการค้นหา ระบบจะเรียงตามสินค้าใหม่ล่าสุด (newest) หน้าที่ 1 จำนวน 20 ชิ้น
      expect(calls.single.label, 'GET /api/products');
      expect(calls.single.query, {
        'sort': 'newest',
        'page': '1',
        'limit': '20',
      });
    });

    test('ส่งตัวกรองทุกชนิดไปพร้อมกัน', () async {
      await products.browse(
        keyword: 'desk',
        categoryId: 2,
        zone: 'on_campus',
        locationId: 7,
        sort: 'price_asc',
        page: 3,
        limit: 10,
      );

      // ตรวจสอบว่าพารามิเตอร์ตัวกรองทั้งหมดถูกแปลงชื่อคีย์ (snake_case) และค่าเป็น String ใน Query อย่างถูกต้อง
      expect(calls.single.query, {
        'keyword': 'desk',
        'category_id': '2',
        'zone': 'on_campus',
        'location_id': '7',
        'sort': 'price_asc',
        'page': '3',
        'limit': '10',
      });
    });
  });

  // =========================================================================
  // กลุ่มทดสอบที่ 2: การดึงข้อมูลหมวดหมู่สินค้า (Categories) และสถานที่นัดรับ (Locations)
  // =========================================================================
  group('categories และ locations', () {
    test('categories คืนรายการ map และข้ามสมาชิกที่ไม่ใช่ map', () async {
      // จำลองข้อมูลจาก Server ที่มีข้อมูลขยะ ('junk') ปะปนมากับข้อมูลหมวดหมู่ปกติ
      products = ProductController(
        fakeApi(
          calls,
          response: {
            'success': true,
            'data': [
              {'category_id': 1, 'name': 'Books'},
              'junk',
              {'category_id': 2, 'name': 'Furniture'},
            ],
          },
        ),
      );

      final result = await products.categories();

      // ตรวจสอบว่าข้อมูลที่ไม่ใช่ Map จะถูกคัดกรองออก เหลือเฉพาะหมวดหมู่ที่สมบูรณ์ 2 รายการ
      expect(calls.single.label, 'GET /api/categories');
      expect(result, hasLength(2));
      expect(result.first['name'], 'Books');
      expect(result.last['category_id'], 2);
    });

    test('categories ที่ไม่มี data → list ว่าง', () async {
      // ตรวจสอบกรณีที่ Response ไม่มีฟิลด์ data ต้องคืนค่า List ว่าง [] อย่างปลอดภัย
      expect(await products.categories(), isEmpty);
    });

    test('locations ไม่ส่ง zone ถ้าไม่ระบุ', () async {
      await products.locations();
      // ตรวจสอบว่าหากไม่ระบุโซน Query Parameters ต้องว่างเปล่า
      expect(calls.single.label, 'GET /api/locations');
      expect(calls.single.query, isEmpty);
    });

    test('locations กรองด้วย zone', () async {
      await products.locations(zone: 'off_campus');
      // ตรวจสอบการส่งพารามิเตอร์กรองสถานที่ตามโซนที่กำหนด
      expect(calls.single.query, {'zone': 'off_campus'});
    });
  });

  // =========================================================================
  // กลุ่มทดสอบที่ 3: การดูรายละเอียดสินค้าและรายการประกาศของผู้ใช้เอง (Detail & My Listings)
  // =========================================================================
  group('รายละเอียดและรายการของฉัน', () {
    test('detail เรียก GET /api/products/:id', () async {
      await products.detail(10);
      // ตรวจสอบการดึงข้อมูลสินค้ารายชิ้นตาม ID (10)
      expect(calls.single.label, 'GET /api/products/10');
    });

    test('myListings ใช้ paging ตั้งต้น', () async {
      await products.myListings();
      // ตรวจสอบการดึงรายการประกาศของฉันด้วยค่า Pagination เริ่มต้น (page=1, limit=20)
      expect(calls.single.label, 'GET /api/my/listings');
      expect(calls.single.query, {'page': '1', 'limit': '20'});
    });

    test('myListings ส่ง paging ที่กำหนด', () async {
      await products.myListings(page: 2, limit: 50);
      // ตรวจสอบการส่งค่า Pagination แบบกำหนดเองสำหรับรายการประกาศของฉัน
      expect(calls.single.query, {'page': '2', 'limit': '50'});
    });
  });

  // =========================================================================
  // กลุ่มทดสอบที่ 4: การสร้าง แก้ไขประกาศ และเพิ่มรูปภาพสินค้า (Create, Update, Add Image)
  // =========================================================================
  group('สร้างและแก้ไขประกาศ', () {
    test('create ส่ง listing เป็น body ของ POST /api/products', () async {
      await products.create({'title': 'Oak desk', 'price': 450});

      // ตรวจสอบการส่งข้อมูลสร้างโพสต์ขายสินค้าใหม่ไปยัง endpoint หลัก
      expect(calls.single.label, 'POST /api/products');
      expect(calls.single.body, {'title': 'Oak desk', 'price': 450});
    });

    test('update ส่ง PUT ไปที่สินค้าที่ระบุ', () async {
      await products.update(10, {'title': 'Oak desk v2'});

      // ตรวจสอบการส่งคำสั่งแก้ไขข้อมูลสินค้าตาม ID ที่กำหนด (10)
      expect(calls.single.label, 'PUT /api/products/10');
      expect(calls.single.body, {'title': 'Oak desk v2'});
    });

    test('addImage ใช้ display_order=1 เป็นค่าตั้งต้น', () async {
      await products.addImage(10, 'https://example.com/a.jpg');

      // ตรวจสอบการเพิ่มรูปภาพให้สินค้า ID 10 โดยหากไม่ระบุลำดับรูป ระบบจะตั้งเป็นรูปที่ 1 อัตโนมัติ
      expect(calls.single.label, 'POST /api/products/10/images');
      expect(calls.single.body, {
        'image_url': 'https://example.com/a.jpg',
        'display_order': 1,
      });
    });

    test('addImage กำหนดลำดับรูปได้', () async {
      await products.addImage(10, 'https://example.com/b.jpg', displayOrder: 3);
      // ตรวจสอบการระบุลำดับการแสดงผลของรูปภาพ (display_order = 3)
      expect(calls.single.body!['display_order'], 3);
    });
  });
}
