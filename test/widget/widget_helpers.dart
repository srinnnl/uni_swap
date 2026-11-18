// ไฟล์เสริมสำหรับ widget test ทั้ง 6 ไฟล์ใน test/widget/
// (ไม่ใช่ไฟล์เทสต์ ชื่อไม่ลงท้ายด้วย _test.dart จึงไม่ถูกรันเอง)
//
// มี 4 ส่วน
//  1. setupApp(...)   : สร้าง "เซิร์ฟเวอร์ปลอม" (MockClient) แล้วฉีดเข้า controller
//  2. sample...()     : ข้อมูลปลอมที่หน้าต่าง ๆ ต้องใช้ (โครงสร้าง JSON ตรงกับ model)
//  3. helper สำหรับ UI : ล็อกอิน, ขยายหน้าจอ, กดปุ่มที่อยู่นอกจอ ฯลฯ
//  4. PushHost        : หน้าตัวช่วยสำหรับทดสอบหน้าที่ต้อง pop พร้อมค่าส่งกลับ
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uni_swap/controller/app_controllers.dart';

// ---------------------------------------------------------------------------
// 1. เซิร์ฟเวอร์ปลอม
// ---------------------------------------------------------------------------

/// สร้าง response JSON (ใส่ charset=utf-8 เพื่อให้ emoji/ภาษาอื่นไม่พัง)
http.Response json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// ตัวแทนที่เทสต์ใช้ "แก้คำตอบของ API เฉพาะ request ที่สนใจ"
/// - คืน http.Response  = ใช้คำตอบนี้แทนค่าเริ่มต้น
/// - คืน null            = ใช้คำตอบเริ่มต้นของ widget_helpers
/// - throw ClientException = จำลองเครือข่ายล่ม
typedef ApiOverride = FutureOr<http.Response?> Function(http.Request request);

/// บันทึก request ทั้งหมดที่หน้าแอปส่งออกไป ใช้เช็กว่า "มีการเรียก API ที่ถูกต้อง"
class ApiLog {
  final List<http.Request> requests = [];

  /// request ที่ตรงกับ method และ path (path ไม่ต้องใส่ /api นำหน้า)
  Iterable<http.Request> to(String method, String path) => requests.where(
    (r) => r.method == method && r.url.path == '/api$path',
  );

  bool called(String method, String path) => to(method, path).isNotEmpty;

  /// body (JSON) ของ request ล่าสุดที่ตรงกับ method และ path
  Map<String, dynamic> bodyOf(String method, String path) =>
      jsonDecode(to(method, path).last.body) as Map<String, dynamic>;
}

/// ตั้งค่า controller ทั้งแอปให้คุยกับเซิร์ฟเวอร์ปลอม (state ล้างใหม่ทุกครั้ง)
///
/// [role] = บทบาทของผู้ใช้ที่ /api/login จะตอบกลับ ('member' หรือ 'admin')
ApiLog setupApp({String role = 'member', ApiOverride? override}) {
  final log = ApiLog();
  setupControllers(
    baseUrl: 'http://test.local/api',
    client: MockClient((request) async {
      log.requests.add(request);
      final custom = await override?.call(request);
      return custom ?? _defaultRoute(request, role);
    }),
  );
  return log;
}

http.Response _defaultRoute(http.Request request, String role) {
  final path = request.url.path.replaceFirst('/api', '');
  final key = '${request.method} $path';
  Match? match(String pattern) => RegExp(pattern).firstMatch(key);

  switch (key) {
    // ---- บัญชีผู้ใช้ ----
    case 'POST /login':
      return json({
        'success': true,
        'token': 'test-session',
        'user': sampleLoginUser(role),
      });
    case 'POST /register':
      return json({'success': true, 'user_id': 99, 'status': 'pending'}, 201);
    case 'GET /profile':
      return json({'success': true, 'data': sampleProfile()});
    case 'PUT /profile':
      return json({'success': true});
    case 'GET /dashboard':
      return json({
        'success': true,
        'data': sampleDashboard(),
      });
    case 'POST /location-requests':
      return json({'success': true, 'request_id': 9, 'status': 'pending'}, 201);

    // ---- ข้อมูลอ้างอิง ----
    case 'GET /locations':
      return json({'success': true, 'data': sampleLocations()});
    case 'GET /categories':
      return json({'success': true, 'data': sampleCategories()});

    // ---- สินค้า ----
    case 'GET /products':
      return json({
        'success': true,
        'data': sampleBrowseProducts(),
        'page': 1,
        'limit': 100,
        'has_more': false,
      });
    case 'POST /products':
      return json({'success': true, 'product_id': 301}, 201);
    case 'GET /my/listings':
      return json({
        'success': true,
        'data': sampleMyListings(),
        'page': 1,
        'limit': 100,
        'has_more': false,
      });

    // ---- ออเดอร์ ----
    case 'GET /orders':
      return json({
        'success': true,
        'data': sampleOrders(),
        'page': 1,
        'limit': 100,
        'has_more': false,
      });
    case 'POST /orders':
      return json({'success': true, 'order_id': 501}, 201);

    // ---- แอดมิน ----
    case 'GET /admin/dashboard':
      return json({'success': true, 'data': sampleAdminDashboard()});
    case 'GET /admin/users':
      return json({
        'success': true,
        'data': sampleAdminUsers(),
        'page': 1,
        'limit': 100,
        'has_more': false,
      });
    case 'GET /admin/listings':
      final listingStatus = request.url.queryParameters['status'];
      return json({
        'success': true,
        'data': listingStatus == 'pending_review'
            ? [sampleReviewListing()]
            : listingStatus == 'changes_requested'
            ? [sampleChangesListing()]
            : <Map<String, dynamic>>[],
        'page': 1,
        'limit': 100,
        'has_more': false,
      });
    case 'GET /admin/categories':
      return json({'success': true, 'data': sampleAdminCategories()});
    case 'GET /admin/locations':
      return json({'success': true, 'data': sampleLocations()});
    case 'GET /admin/location-requests':
      final requestStatus = request.url.queryParameters['status'];
      return json({
        'success': true,
        'data': requestStatus == 'pending'
            ? [sampleLocationRequest()]
            : requestStatus == 'reviewing'
            ? [
                sampleLocationRequest(
                  id: 22,
                  name: 'North Hall',
                  zone: 'on_campus',
                  status: 'reviewing',
                  requester: 'Noah Lee',
                ),
              ]
            : <Map<String, dynamic>>[],
        'page': 1,
        'limit': 100,
        'has_more': false,
      });
  }

  // ---- เส้นทางที่มีตัวเลข id ----
  final productId = match(r'^GET /products/(\d+)$');
  if (productId != null) {
    final id = int.parse(productId.group(1)!);
    final found = sampleBrowseProducts().where((p) => p['product_id'] == id);
    return json({
      'success': true,
      'data': found.isNotEmpty ? found.first : sampleProduct(id: id),
    });
  }
  if (match(r'^GET /sellers/(\d+)$') != null) {
    return json({'success': true, 'data': sampleSeller(), 'has_more': false});
  }
  if (match(r'^DELETE /products/(\d+)$') != null) {
    return json({'success': true, 'status': 'deleted'});
  }
  if (match(r'^PUT /products/(\d+)(/hide)?$') != null) {
    return json({'success': true});
  }
  if (match(r'^POST /orders/(\d+)/pay$') != null) {
    return json({'success': true, 'status': 'ready_for_meetup'});
  }
  if (match(r'^POST /orders/(\d+)/received$') != null) {
    return json({'success': true, 'status': 'completed'});
  }
  if (match(r'^POST /orders/(\d+)/cancel$') != null) {
    return json({'success': true, 'status': 'cancelled'});
  }
  if (match(r'^PUT /orders/(\d+)/meetup$') != null) {
    return json({'success': true});
  }
  if (match(r'^(POST|PUT) /admin/') != null) {
    return json({'success': true});
  }

  return json({'success': true, 'data': []});
}

// ---------------------------------------------------------------------------
// 2. ข้อมูลปลอม (โครงสร้างตรงกับ model ใน lib/model)
// ---------------------------------------------------------------------------

/// เวลา ISO-8601 (UTC) ที่ห่างจากตอนนี้ [offset] (ติดลบ = อดีต)
String isoIn(Duration offset) =>
    DateTime.now().add(offset).toUtc().toIso8601String();

Map<String, dynamic> sampleLoginUser(String role) => {
  'user_id': role == 'admin' ? 2 : 3,
  'role': role,
  'display_name': role == 'admin' ? 'Test Admin' : 'Test Member',
  'email': 'test@example.com',
  'status': 'active',
  'residence_zone': 'off_campus',
  'residence_location_id': 1,
};

Map<String, dynamic> sampleProfile() => {
  'user_id': 3,
  'student_id': '6501000003',
  'username': 'test_member',
  'email': 'test@example.com',
  'display_name': 'Test Member',
  'role': 'member',
  'status': 'active',
  'residence_zone': 'off_campus',
  'residence_location_id': 1,
  'residence_name': 'Test Residence',
  'created_at': '2025-09-15T12:00:00.000Z',
};

/// ผลของ GET /api/dashboard (data) ของผู้ใช้ทั่วไป
Map<String, dynamic> sampleDashboard({
  Map<String, int>? counts,
  List<Map<String, dynamic>> recentOrders = const [],
}) => {
  'user': {'user_id': 3, 'display_name': 'Test Member'},
  'counts': counts ??
      {
        'my_listings': 5,
        'sold_listings': 2,
        'listings_to_review': 0,
        'listings_to_fix': 0,
        'buying_active': 0,
        'selling_active': 0,
      },
  'recent_listings': <Map<String, dynamic>>[],
  'recent_orders': recentOrders,
  'pending_location_request': null,
};

List<Map<String, dynamic>> sampleLocations() => [
  {'location_id': 1, 'name': 'Test Residence', 'zone': 'off_campus', 'is_active': 1},
  {'location_id': 2, 'name': 'Dorm A', 'zone': 'on_campus', 'is_active': 1},
  {'location_id': 3, 'name': 'Dorm B', 'zone': 'on_campus', 'is_active': 1},
];

List<Map<String, dynamic>> sampleCategories() => [
  {'category_id': 1, 'name': 'Furniture', 'emoji': '🪑', 'is_active': 1},
  {'category_id': 2, 'name': 'Books', 'emoji': '📚', 'is_active': 1},
  {'category_id': 3, 'name': 'Appliances', 'emoji': '🔌', 'is_active': 1},
];

/// /api/admin/categories (มี product_count และมีหมวดที่ปิดใช้งานด้วย)
List<Map<String, dynamic>> sampleAdminCategories() => [
  {
    'category_id': 1,
    'name': 'Furniture',
    'emoji': '🪑',
    'is_active': 1,
    'product_count': 3,
  },
  {
    'category_id': 2,
    'name': 'Books',
    'emoji': '📚',
    'is_active': 0,
    'product_count': 0,
  },
];

/// สินค้า 1 ชิ้น (ใช้ทั้งหน้า browse, my listings, admin review)
Map<String, dynamic> sampleProduct({
  int id = 101,
  String title = 'Study Desk',
  num price = 450,
  String category = 'Furniture',
  int categoryId = 1,
  int locationId = 1,
  String locationName = 'Test Residence',
  String zone = 'off_campus',
  String status = 'available',
  String urgency = 'normal',
  String? deadline,
  int sellerId = 7,
  String sellerName = 'Sam Seller',
  int viewCount = 0,
  String? reviewNote,
  bool isOwn = false,
}) => {
  'product_id': id,
  'seller_id': sellerId,
  'seller_name': sellerName,
  'seller_username': 'sam',
  'sales': 18,
  'title': title,
  'description': 'Sturdy and ready for a new home.',
  'category': category,
  'category_id': categoryId,
  'category_name': category,
  'price': price,
  'item_condition': 'good',
  'urgency_level': urgency,
  'zone': zone,
  'location_name': locationName,
  'location_id': locationId,
  'location_detail': 'Near the lobby',
  'clearance_deadline': deadline,
  'status': status,
  'created_at': isoIn(const Duration(hours: -2)),
  'view_count': viewCount,
  'image_count': 0,
  'images': <Map<String, dynamic>>[],
  'is_own_item': isOwn,
  'review_note': reviewNote,
};

/// GET /api/products: Study Desk(450) / Calculus Textbook(120) / Mini Fridge(1500)
List<Map<String, dynamic>> sampleBrowseProducts() => [
  sampleProduct(),
  sampleProduct(
    id: 102,
    title: 'Calculus Textbook',
    price: 120,
    category: 'Books',
    categoryId: 2,
    locationId: 2,
    locationName: 'Dorm A',
    zone: 'on_campus',
    urgency: 'urgent',
    deadline: isoIn(const Duration(days: 3)),
  ),
  sampleProduct(
    id: 103,
    title: 'Mini Fridge',
    price: 1500,
    category: 'Appliances',
    categoryId: 3,
  ),
];

/// GET /api/my/listings: available / pending_review / changes_requested / sold
List<Map<String, dynamic>> sampleMyListings() => [
  sampleProduct(id: 201, title: 'Wooden Chair', price: 250, viewCount: 12),
  sampleProduct(
    id: 202,
    title: 'Old Laptop',
    price: 3000,
    category: 'Technology',
    status: 'pending_review',
    viewCount: 3,
  ),
  sampleProduct(
    id: 203,
    title: 'Blue Bike',
    price: 900,
    status: 'changes_requested',
    reviewNote: 'Please add clearer photos',
  ),
  sampleProduct(
    id: 204,
    title: 'Sold Book',
    price: 80,
    category: 'Books',
    status: 'sold',
    viewCount: 40,
  ),
];

/// data ของ GET /api/sellers/:id
Map<String, dynamic> sampleSeller() => {
  'seller': {
    'user_id': 7,
    'display_name': 'Sam Seller',
    'username': 'sam',
    'member_since': '2025-09-15T12:00:00.000Z',
    'completed_sales': 4,
    'location_name': 'Test Residence',
  },
  'items': [sampleProduct(), sampleProduct(id: 103, title: 'Mini Fridge', price: 1500)],
};

/// ออเดอร์ 1 รายการ ([perspective] = 'buying' หรือ 'selling')
Map<String, dynamic> sampleOrder({
  int id = 401,
  String title = 'Study Desk',
  String status = 'pending_payment',
  String perspective = 'buying',
  num price = 450,
  String? deadline,
  String? meetupAt,
  String meetupPlace = 'Test Residence',
}) => {
  'order_id': id,
  'product_id': 101,
  'product_title': title,
  'product_location_name': 'Test Residence',
  'pickup_detail': 'Near the lobby',
  'buyer_id': 3,
  'buyer_name': 'Bea Buyer',
  'seller_id': 7,
  'seller_name': 'Sam Seller',
  'seller_price': price,
  'commission_rate': 5,
  'commission_amount': price * 0.05,
  'total_amount': price,
  'seller_payout': price * 0.95,
  'status': status,
  'meetup_location': meetupPlace,
  'meetup_datetime': meetupAt,
  'payment_deadline': deadline,
  'perspective': perspective,
  'created_at': isoIn(const Duration(minutes: -10)),
};

/// GET /api/orders: ซื้อรอจ่าย / ขายรอนัดรับ / ซื้อเสร็จแล้ว
List<Map<String, dynamic>> sampleOrders() => [
  sampleOrder(deadline: isoIn(const Duration(minutes: 20))),
  sampleOrder(
    id: 402,
    title: 'Calculus Textbook',
    status: 'ready_for_meetup',
    perspective: 'selling',
    price: 120,
    meetupAt: isoIn(const Duration(days: 1)),
    meetupPlace: 'Dorm A',
  ),
  sampleOrder(id: 403, title: 'Mini Fridge', status: 'completed', price: 1500),
];

// ---- แอดมิน ----

Map<String, dynamic> sampleAdminDashboard() => {
  'overview': {
    'users_total': 12,
    'users_pending': 3,
    'items_live': 8,
    'items_pending': 2,
    'locations_pending': 1,
    'categories_active': 5,
  },
  'pending_listings': [sampleReviewListing()],
  'pending_location_requests': [sampleLocationRequest()],
};

List<Map<String, dynamic>> sampleAdminUsers() => [
  _adminUser(11, 'Maya Kim', 'maya', 'pending'),
  _adminUser(12, 'Noah Lee', 'noah', 'active'),
  _adminUser(13, 'Olive Park', 'olive', 'suspended'),
  {
    ..._adminUser(14, 'Root Admin', 'root', 'active'),
    'role': 'admin',
  },
];

Map<String, dynamic> _adminUser(int id, String name, String username, String status) => {
  'user_id': id,
  'student_id': '65010000$id',
  'username': username,
  'email': '$username@example.com',
  'display_name': name,
  'role': 'member',
  'status': status,
  'residence_zone': 'on_campus',
  'residence_location_id': 2,
  'created_at': '2025-09-15T12:00:00.000Z',
};

/// สินค้ารอตรวจ (admin/listings?status=pending_review)
Map<String, dynamic> sampleReviewListing() => sampleProduct(
  id: 301,
  title: 'Old Laptop',
  price: 3000,
  category: 'Technology',
  status: 'pending_review',
);

/// สินค้าที่แอดมินขอให้แก้ (admin/listings?status=changes_requested)
Map<String, dynamic> sampleChangesListing() => sampleProduct(
  id: 302,
  title: 'Blue Bike',
  price: 900,
  category: 'Transport',
  status: 'changes_requested',
  reviewNote: 'Add clearer photos',
);

Map<String, dynamic> sampleLocationRequest({
  int id = 21,
  String name = 'Sunrise Apartment',
  String zone = 'off_campus',
  String status = 'pending',
  String requester = 'Maya Kim',
}) => {
  'request_id': id,
  'requested_by': 11,
  'name': name,
  'zone': zone,
  'address': '12 Main Street',
  'reason': 'Many students live here',
  'status': status,
  'requester_name': requester,
  'username': 'maya',
  'created_at': isoIn(const Duration(hours: -3)),
};

// ---------------------------------------------------------------------------
// 3. helper สำหรับ UI
// ---------------------------------------------------------------------------

/// ล็อกอินผ่าน authController (ต้องเรียก setupApp ก่อน) เพื่อให้หน้าที่ต้องใช้
/// token/ข้อมูลผู้ใช้ (เช่น Profile, Home) ทำงานได้โดยไม่ต้องผ่านหน้า Login
Future<void> signIn(WidgetTester tester) async {
  await tester.runAsync(
    () => authController.login(email: 'user@example.com', password: 'secret123'),
  );
}

/// ขยายหน้าจอทดสอบให้สูงขึ้น เพื่อให้รายการ/ฟอร์มยาว ๆ ถูกสร้างครบ
/// (ListView สร้างเฉพาะส่วนที่อยู่ในจอ) แล้วคืนค่าเดิมให้เองเมื่อเทสต์จบ
void useTallScreen(WidgetTester tester, {double height = 1800}) {
  tester.view.physicalSize = Size(800, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// ให้การเรียก HapticFeedback ฯลฯ (platform channel) ไม่ error ตอนเทสต์
void allowPlatformChannel() {
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  addTearDown(() => messenger.setMockMethodCallHandler(SystemChannels.platform, null));
}

/// รอให้หน้าใหม่โหลดเสร็จหลัง navigate (เหมือนของเดิมใน widget_test.dart)
Future<void> pumpAfterNavigation(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

/// เลื่อนให้ [finder] อยู่ในจอ แล้วกด (finder ต้องเจอ widget เดียว)
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// จำกัดการค้นหาให้อยู่ใน AlertDialog (กันชนกับข้อความชื่อเดียวกันในหน้าด้านหลัง)
Finder inDialog(Finder matching) =>
    find.descendant(of: find.byType(AlertDialog), matching: matching);

// ---------------------------------------------------------------------------
// 4. PushHost
// ---------------------------------------------------------------------------

/// หน้าตัวช่วย: มีปุ่ม "Open page" เปิดหน้าที่ต้องการทดสอบ และแสดงค่าที่หน้านั้น
/// pop กลับมา (Result: ...) ใช้กับหน้าที่ปิดตัวเองด้วย Navigator.pop(ค่า)
/// เพราะถ้าเป็น root route ของ MaterialApp จะ pop ไม่ได้
class PushHost<T> extends StatefulWidget {
  const PushHost({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  State<PushHost<T>> createState() => _PushHostState<T>();
}

class _PushHostState<T> extends State<PushHost<T>> {
  bool _returned = false;
  T? _result;

  Future<void> _open() async {
    final result = await Navigator.push<T>(
      context,
      MaterialPageRoute(builder: widget.builder),
    );
    if (!mounted) return;
    setState(() {
      _returned = true;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(onPressed: _open, child: const Text('Open page')),
            Text(_returned ? 'Result: $_result' : 'No result yet'),
          ],
        ),
      ),
    );
  }
}
