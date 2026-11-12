// Unit tests for AdminController.
//
// AdminController and ApiClient are the REAL classes under test. Only the
// http.Client is replaced with a MockClient, so no server is used. Values such
// as action/status strings are passed through unchanged by the controller, so
// these tests only check that they reach the API in the right place.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:uni_swap/controller/admin_controller.dart';
import 'package:uni_swap/controller/api_client.dart';

void main() {
  group('AdminController', () {
    late List<http.Request> requests;
    late ApiClient api;
    late AdminController controller;

    String sent() => '${requests.single.method} ${requests.single.url.path}';
    Map<String, String> sentQuery() => requests.single.url.queryParameters;
    Map<String, dynamic> sentBody() =>
        jsonDecode(requests.single.body) as Map<String, dynamic>;

    setUp(() {
      requests = [];
      api = ApiClient(
        baseUrl: 'http://mock-api.local/api',
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({'success': true}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      controller = AdminController(api);
    });

    tearDown(() => api.close());

    // ------------------------------------------------------------------
    // dashboard
    // ------------------------------------------------------------------

    test('dashboard requests the admin dashboard', () async {
      await controller.dashboard();

      expect(sent(), 'GET /api/admin/dashboard');
    });

    // ------------------------------------------------------------------
    // users
    // ------------------------------------------------------------------

    test('users uses default paging and no status filter', () async {
      await controller.users();

      expect(sent(), 'GET /api/admin/users');
      expect(sentQuery(), {'page': '1', 'limit': '20'});
    });

    test('users sends the status filter and custom paging', () async {
      await controller.users(status: 'pending', page: 2, limit: 10);

      expect(sentQuery(), {'status': 'pending', 'page': '2', 'limit': '10'});
    });

    test('setUserStatus puts the new status to the user status path',
        () async {
      await controller.setUserStatus(4, 'active');

      expect(sent(), 'PUT /api/admin/users/4/status');
      expect(sentBody(), {'status': 'active'});
    });

    // ------------------------------------------------------------------
    // listings
    // ------------------------------------------------------------------

    test('listings defaults to the pending_review status', () async {
      await controller.listings();

      expect(sent(), 'GET /api/admin/listings');
      expect(sentQuery(), {
        'status': 'pending_review',
        'page': '1',
        'limit': '20',
      });
    });

    test('listings sends a custom status and paging', () async {
      await controller.listings(status: 'available', page: 2, limit: 5);

      expect(sentQuery(), {'status': 'available', 'page': '2', 'limit': '5'});
    });

    test('reviewListing sends only the action when no note is given',
        () async {
      await controller.reviewListing(10, action: 'approve');

      expect(sent(), 'PUT /api/admin/listings/10/review');
      expect(sentBody(), {
        'action': 'approve',
        'review_note': null,
        'reject_reason': null,
      });
    });

    test('reviewListing sends the note and reject reason', () async {
      await controller.reviewListing(
        10,
        action: 'reject',
        note: 'Photos are blurry',
        rejectReason: 'poor_photos',
      );

      expect(sentBody(), {
        'action': 'reject',
        'review_note': 'Photos are blurry',
        'reject_reason': 'poor_photos',
      });
    });

    // ------------------------------------------------------------------
    // reports
    // ------------------------------------------------------------------

    test('reports uses default and custom paging', () async {
      await controller.reports();
      expect(sent(), 'GET /api/admin/reports');
      expect(sentQuery(), {'page': '1', 'limit': '20'});

      requests.clear();
      await controller.reports(page: 3, limit: 50);
      expect(sentQuery(), {'page': '3', 'limit': '50'});
    });

    test('resolveReport defaults hide_product to false', () async {
      await controller.resolveReport(9, status: 'resolved');

      expect(sent(), 'PUT /api/admin/reports/9');
      expect(sentBody(), {
        'status': 'resolved',
        'admin_note': null,
        'hide_product': false,
      });
    });

    test('resolveReport sends the note and hide_product flag', () async {
      await controller.resolveReport(
        9,
        status: 'resolved',
        note: 'Seller warned',
        hideProduct: true,
      );

      expect(sentBody(), {
        'status': 'resolved',
        'admin_note': 'Seller warned',
        'hide_product': true,
      });
    });

    // ------------------------------------------------------------------
    // categories
    // ------------------------------------------------------------------

    test('categories requests the admin category list', () async {
      await controller.categories();

      expect(sent(), 'GET /api/admin/categories');
    });

    test('createCategory sends name, emoji and is_active', () async {
      await controller.createCategory(
        name: 'Books',
        emoji: 'book',
        active: false,
      );

      expect(sent(), 'POST /api/admin/categories');
      expect(sentBody(), {'name': 'Books', 'emoji': 'book', 'is_active': false});
    });

    test('createCategory is active and has a default emoji by default',
        () async {
      await controller.createCategory(name: 'Books');

      final body = sentBody();
      expect(body['name'], 'Books');
      expect(body['is_active'], isTrue);
      expect(body['emoji'], isNotEmpty);
    });

    test('updateCategory puts all fields to the category id', () async {
      await controller.updateCategory(
        3,
        name: 'Books & Notes',
        emoji: 'book',
        active: false,
      );

      expect(sent(), 'PUT /api/admin/categories/3');
      expect(sentBody(), {
        'name': 'Books & Notes',
        'emoji': 'book',
        'is_active': false,
      });
    });

    // ------------------------------------------------------------------
    // locations
    // ------------------------------------------------------------------

    test('locations sends the zone filter only when given', () async {
      await controller.locations(zone: 'off_campus');
      expect(sent(), 'GET /api/admin/locations');
      expect(sentQuery(), {'zone': 'off_campus'});

      requests.clear();
      await controller.locations();
      expect(sentQuery(), isEmpty);
    });

    test('createLocation sends name and zone', () async {
      await controller.createLocation(name: 'Sunrise Apartment', zone: 'off_campus');

      expect(sent(), 'POST /api/admin/locations');
      expect(sentBody(), {'name': 'Sunrise Apartment', 'zone': 'off_campus'});
    });

    test('updateLocation puts name and is_active to the location id',
        () async {
      await controller.updateLocation(2, name: 'Sunrise Apt', active: false);

      expect(sent(), 'PUT /api/admin/locations/2');
      expect(sentBody(), {'name': 'Sunrise Apt', 'is_active': false});
    });

    // ------------------------------------------------------------------
    // location requests
    // ------------------------------------------------------------------

    test('locationRequests uses default paging and no status filter',
        () async {
      await controller.locationRequests();

      expect(sent(), 'GET /api/admin/location-requests');
      expect(sentQuery(), {'page': '1', 'limit': '20'});
    });

    test('locationRequests sends the status filter', () async {
      await controller.locationRequests(status: 'pending');

      expect(sentQuery()['status'], 'pending');
    });

    test('reviewLocationRequest sends a null merge target when not merging',
        () async {
      await controller.reviewLocationRequest(4, action: 'approve');

      expect(sent(), 'PUT /api/admin/location-requests/4/review');
      expect(sentBody(), {'action': 'approve', 'merge_into_location_id': null});
    });

    test('reviewLocationRequest sends the merge target location id', () async {
      await controller.reviewLocationRequest(
        4,
        action: 'merge',
        mergeIntoLocationId: 2,
      );

      expect(sentBody(), {'action': 'merge', 'merge_into_location_id': 2});
    });
  });
}
