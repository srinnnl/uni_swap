import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/product_controller.dart';

import 'test_helpers.dart';

void main() {
  late List<RecordedCall> calls;
  late ProductController products;

  setUp(() {
    calls = [];
    products = ProductController(fakeApi(calls));
  });

  // /User/Home and /User/Search — GET /api/products.
  group('User / Browse products', () {
    test('ค่าตั้งต้น: sort=newest page=1 limit=20 และไม่มีตัวกรอง', () async {
      await products.browse();

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

  // /User/Register, /User/Sell, /User/Search — public catalogue options.
  group('User / Categories and locations', () {
    test('categories คืนรายการ map และข้ามสมาชิกที่ไม่ใช่ map', () async {
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

      expect(calls.single.label, 'GET /api/categories');
      expect(result, hasLength(2));
      expect(result.first['name'], 'Books');
      expect(result.last['category_id'], 2);
    });

    test('categories ที่ไม่มี data → list ว่าง', () async {
      expect(await products.categories(), isEmpty);
    });

    test('locations ไม่ส่ง zone ถ้าไม่ระบุ', () async {
      await products.locations();
      expect(calls.single.label, 'GET /api/locations');
      expect(calls.single.query, isEmpty);
    });

    test('locations กรองด้วย zone', () async {
      await products.locations(zone: 'off_campus');
      expect(calls.single.query, {'zone': 'off_campus'});
    });
  });

  // /User/ProductDetail, /User/SellerProfile, /User/MyItems.
  group('User / Product details and listings', () {
    test('detail เรียก GET /api/products/:id', () async {
      await products.detail(10);
      expect(calls.single.label, 'GET /api/products/10');
    });

    test('myListings ใช้ paging ตั้งต้น', () async {
      await products.myListings();
      expect(calls.single.label, 'GET /api/my/listings');
      expect(calls.single.query, {'page': '1', 'limit': '20'});
    });

    test('myListings ส่ง paging ที่กำหนด', () async {
      await products.myListings(page: 2, limit: 50);
      expect(calls.single.query, {'page': '2', 'limit': '50'});
    });
  });

  // /User/RequestLocation — POST /api/location-requests.
  group('User / Request location', () {
    test('sends name, zone, and optional address/reason', () async {
      await products.requestLocation(
        name: 'Sunrise Apartment',
        zone: 'off_campus',
        address: '123 Campus Road',
        reason: 'Not in the list',
      );

      expect(calls.single.label, 'POST /api/location-requests');
      expect(calls.single.body, {
        'name': 'Sunrise Apartment',
        'zone': 'off_campus',
        'address': '123 Campus Road',
        'reason': 'Not in the list',
      });
    });

    test('omits empty optional fields', () async {
      await products.requestLocation(
        name: 'Sunrise Apartment',
        zone: 'off_campus',
        address: '',
        reason: '',
      );

      expect(calls.single.body, {
        'name': 'Sunrise Apartment',
        'zone': 'off_campus',
      });
    });
  });

  // /User/SellerProfile — GET /api/sellers/:user_id.
  group('User / Seller profile', () {
    test('uses default and custom pagination', () async {
      await products.seller(8);
      expect(calls.single.label, 'GET /api/sellers/8');
      expect(calls.single.query, {'page': '1', 'limit': '20'});

      calls.clear();
      await products.seller(8, page: 2, limit: 5);
      expect(calls.single.query, {'page': '2', 'limit': '5'});
    });
  });

  // /User/Profile — GET /api/dashboard for member listing/order counts.
  test('myDashboard calls GET /api/dashboard', () async {
    await products.myDashboard();
    expect(calls.single.label, 'GET /api/dashboard');
  });

  // /User/Sell and /User/MyItems — create, update, delete, and hide listings.
  group('User / Manage listings', () {
    test('create ส่ง listing เป็น body ของ POST /api/products', () async {
      await products.create({'title': 'Oak desk', 'price': 450});

      expect(calls.single.label, 'POST /api/products');
      expect(calls.single.body, {'title': 'Oak desk', 'price': 450});
    });

    test('update ส่ง PUT ไปที่สินค้าที่ระบุ', () async {
      await products.update(10, {'title': 'Oak desk v2'});

      expect(calls.single.label, 'PUT /api/products/10');
      expect(calls.single.body, {'title': 'Oak desk v2'});
    });

    test('deleteUnreviewed ลบประกาศที่ยังไม่ผ่านการพิจารณา', () async {
      await products.deleteUnreviewed(10);

      expect(calls.single.label, 'DELETE /api/products/10');
    });

    test('hideAvailable ซ่อนประกาศที่เปิดขายอยู่', () async {
      await products.hideAvailable(10);

      expect(calls.single.label, 'PUT /api/products/10/hide');
      expect(calls.single.body, isEmpty);
    });

    test('addImage ใช้ display_order=1 เป็นค่าตั้งต้น', () async {
      await products.addImage(10, 'https://example.com/a.jpg');

      expect(calls.single.label, 'POST /api/products/10/images');
      expect(calls.single.body, {
        'image_url': 'https://example.com/a.jpg',
        'display_order': 1,
      });
    });

    test('addImage กำหนดลำดับรูปได้', () async {
      await products.addImage(10, 'https://example.com/b.jpg', displayOrder: 3);
      expect(calls.single.body!['display_order'], 3);
    });

    test('uploadImage sends in-memory bytes and display order', () async {
      http.Request? captured;
      final api = ApiClient(
        tokenProvider: () => 'seller-token',
        client: MockClient((request) async {
          captured = request;
          return http.Response('{"success":true}', 201);
        }),
      );
      final multipartApi = ProductController(api);

      await multipartApi.uploadImage(
        10,
        bytes: [65, 66, 67],
        fileName: 'photo.png',
        mimeType: 'image/png',
        displayOrder: 3,
      );

      expect(captured!.method, 'POST');
      expect(captured!.url.path, '/api/products/10/images');
      expect(captured!.headers['authorization'], 'Bearer seller-token');
      expect(captured!.body, contains('name="display_order"'));
      expect(captured!.body, contains('3'));
      expect(captured!.body, contains('filename="photo.png"'));
      expect(captured!.body, contains('content-type: image/png'));
      expect(captured!.body, contains('ABC'));
      api.close();
    });
  });
}
