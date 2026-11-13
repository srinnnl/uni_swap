import 'package:flutter_test/flutter_test.dart';
import 'package:uni_swap/controller/admin_controller.dart';
import 'package:uni_swap/controller/api_client.dart';

import 'test_helpers.dart';

void main() {
  late List<RecordedCall> calls;
  late AdminController admin;

  setUp(() {
    calls = [];
    admin = AdminController(fakeApi(calls));
  });

  group('dashboard และ users', () {
    test('dashboard เรียก GET /api/admin/dashboard', () async {
      await admin.dashboard();
      expect(calls.single.label, 'GET /api/admin/dashboard');
    });

    test('users ใช้ page=1 limit=20 และไม่ส่ง status ถ้าไม่ระบุ', () async {
      await admin.users();
      expect(calls.single.label, 'GET /api/admin/users');
      expect(calls.single.query, {'page': '1', 'limit': '20'});
    });

    test('users ส่ง status และ paging ที่กำหนด', () async {
      await admin.users(status: 'pending', page: 3, limit: 50);
      expect(calls.single.query, {
        'status': 'pending',
        'page': '3',
        'limit': '50',
      });
    });

    test('setUserStatus ส่ง PUT พร้อม status ใน body', () async {
      await admin.setUserStatus(5, 'suspended');
      expect(calls.single.label, 'PUT /api/admin/users/5/status');
      expect(calls.single.body, {'status': 'suspended'});
    });
  });

  group('listings', () {
    test('listings ค่าตั้งต้นคือ pending_review', () async {
      await admin.listings();
      expect(calls.single.label, 'GET /api/admin/listings');
      expect(calls.single.query['status'], 'pending_review');
    });

    test('listings เปลี่ยน status ได้', () async {
      await admin.listings(status: 'all', page: 2);
      expect(calls.single.query['status'], 'all');
      expect(calls.single.query['page'], '2');
    });

    test('reviewListing แบบ approve ไม่มี note และ reject_reason', () async {
      await admin.reviewListing(7, action: 'approve');
      expect(calls.single.label, 'PUT /api/admin/listings/7/review');
      expect(calls.single.body!['action'], 'approve');
      expect(calls.single.body!['review_note'], isNull);
      expect(calls.single.body!['reject_reason'], isNull);
    });

    test('reviewListing แบบ reject ส่ง note และ reject_reason', () async {
      await admin.reviewListing(
        7,
        action: 'reject',
        note: 'Photos are blurry',
        rejectReason: 'poor_photos',
      );
      expect(calls.single.body, {
        'action': 'reject',
        'review_note': 'Photos are blurry',
        'reject_reason': 'poor_photos',
      });
    });
  });

  group('categories', () {
    test('categories เรียก GET /api/admin/categories', () async {
      await admin.categories();
      expect(calls.single.label, 'GET /api/admin/categories');
    });

    test('createCategory ใช้ is_active=true และมี emoji ตั้งต้น', () async {
      await admin.createCategory(name: 'Books');
      expect(calls.single.label, 'POST /api/admin/categories');
      expect(calls.single.body!['name'], 'Books');
      expect(calls.single.body!['emoji'], isNotEmpty);
      expect(calls.single.body!['is_active'], true);
    });

    test('createCategory กำหนด emoji และ active เองได้', () async {
      await admin.createCategory(name: 'Books', emoji: 'B', active: false);
      expect(calls.single.body, {
        'name': 'Books',
        'emoji': 'B',
        'is_active': false,
      });
    });

    test('updateCategory ส่ง PUT ไปที่ id ที่ถูกต้อง', () async {
      await admin.updateCategory(4, name: 'Food', emoji: 'F', active: true);
      expect(calls.single.label, 'PUT /api/admin/categories/4');
      expect(calls.single.body, {
        'name': 'Food',
        'emoji': 'F',
        'is_active': true,
      });
    });
  });

  group('locations', () {
    test('locations ไม่ส่ง zone ถ้าไม่ระบุ', () async {
      await admin.locations();
      expect(calls.single.label, 'GET /api/admin/locations');
      expect(calls.single.query, isEmpty);
    });

    test('locations กรองด้วย zone', () async {
      await admin.locations(zone: 'on_campus');
      expect(calls.single.query, {'zone': 'on_campus'});
    });

    test('createLocation ส่ง name และ zone', () async {
      await admin.createLocation(name: 'Library', zone: 'on_campus');
      expect(calls.single.label, 'POST /api/admin/locations');
      expect(calls.single.body, {'name': 'Library', 'zone': 'on_campus'});
    });

    test('updateLocation ส่ง PUT พร้อม is_active', () async {
      await admin.updateLocation(2, name: 'Canteen', active: false);
      expect(calls.single.label, 'PUT /api/admin/locations/2');
      expect(calls.single.body, {'name': 'Canteen', 'is_active': false});
    });
  });

  group('location requests', () {
    test('locationRequests ใช้ paging ตั้งต้นและไม่ส่ง status', () async {
      await admin.locationRequests();
      expect(calls.single.label, 'GET /api/admin/location-requests');
      expect(calls.single.query, {'page': '1', 'limit': '20'});
    });

    test('locationRequests กรองด้วย status', () async {
      await admin.locationRequests(status: 'pending');
      expect(calls.single.query['status'], 'pending');
    });

    test('reviewLocationRequest แบบ approve ไม่มี merge id', () async {
      await admin.reviewLocationRequest(11, action: 'approve');
      expect(calls.single.label, 'PUT /api/admin/location-requests/11/review');
      expect(calls.single.body!['action'], 'approve');
      expect(calls.single.body!['merge_into_location_id'], isNull);
    });

    test('reviewLocationRequest แบบ merge ส่ง location ปลายทาง', () async {
      await admin.reviewLocationRequest(
        11,
        action: 'merge',
        mergeIntoLocationId: 3,
      );
      expect(calls.single.body, {
        'action': 'merge',
        'merge_into_location_id': 3,
      });
    });
  });

  group('การจัดการ error', () {
    test('403 Admin only ถูกโยนเป็น ApiException', () async {
      final denied = AdminController(
        fakeApi(
          calls,
          status: 403,
          response: {'success': false, 'message': 'Admin only'},
        ),
      );

      expect(
        denied.dashboard(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', 'Admin only'),
        ),
      );
    });

    test('ส่ง token ไปกับ request ทุกครั้งเมื่อมี tokenProvider', () async {
      final withToken = AdminController(
        fakeApi(calls, tokenProvider: () => 'admin-token'),
      );
      await withToken.dashboard();
      expect(calls.single.headers['authorization'], 'Bearer admin-token');
    });
  });
}
