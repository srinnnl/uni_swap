// Unit tests for ProductController.
//
// ProductController and ApiClient are the REAL classes under test. Only the
// http.Client is replaced with a MockClient, so no server is used. Each test
// checks what the controller sends (method, path, query, body) and how it
// handles the response.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/product_controller.dart';

void main() {
  group('ProductController', () {
    late List<http.Request> requests;
    late ApiClient api;
    late ProductController controller;
    var nextResponse = <String, dynamic>{'success': true};

    String sent() => '${requests.single.method} ${requests.single.url.path}';
    Map<String, String> sentQuery() => requests.single.url.queryParameters;
    Map<String, dynamic> sentBody() =>
        jsonDecode(requests.single.body) as Map<String, dynamic>;

    setUp(() {
      requests = [];
      nextResponse = {'success': true};
      api = ApiClient(
        baseUrl: 'http://mock-api.local/api',
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode(nextResponse),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      controller = ProductController(api);
    });

    tearDown(() => api.close());

    // ------------------------------------------------------------------
    // browse
    // ------------------------------------------------------------------

    test('browse uses default sort and paging when no filters are given',
        () async {
      await controller.browse();

      expect(sent(), 'GET /api/products');
      expect(sentQuery(), {'sort': 'newest', 'page': '1', 'limit': '20'});
    });

    test('browse maps every filter to its API query key', () async {
      await controller.browse(
        keyword: 'desk',
        categoryId: 2,
        zone: 'on_campus',
        locationId: 5,
        sort: 'price_asc', // passed through unchanged
        page: 3,
        limit: 10,
      );

      expect(sent(), 'GET /api/products');
      expect(sentQuery(), {
        'keyword': 'desk',
        'category_id': '2',
        'zone': 'on_campus',
        'location_id': '5',
        'sort': 'price_asc',
        'page': '3',
        'limit': '10',
      });
    });

    test('browse returns the decoded response body', () async {
      nextResponse = {
        'success': true,
        'data': [
          {'product_id': 1},
        ],
        'has_more': false,
      };

      final result = await controller.browse();

      expect(result['has_more'], false);
      expect((result['data'] as List).single, {'product_id': 1});
    });

    // ------------------------------------------------------------------
    // categories / locations (the _rows helper)
    // ------------------------------------------------------------------

    test('categories returns the rows from "data" as maps', () async {
      nextResponse = {
        'data': [
          {'category_id': 1, 'name': 'Furniture'},
          {'category_id': 2, 'name': 'Books'},
        ],
      };

      final result = await controller.categories();

      expect(sent(), 'GET /api/categories');
      expect(result, [
        {'category_id': 1, 'name': 'Furniture'},
        {'category_id': 2, 'name': 'Books'},
      ]);
    });

    test('categories skips entries that are not maps', () async {
      nextResponse = {
        'data': [
          {'category_id': 1},
          'junk',
          5,
          {'category_id': 2},
        ],
      };

      final result = await controller.categories();

      expect(result.map((row) => row['category_id']), [1, 2]);
    });

    test('categories returns an empty list when "data" is missing', () async {
      nextResponse = {'success': true};

      expect(await controller.categories(), isEmpty);
    });

    test('categories returns a fixed-length (unmodifiable) list', () async {
      nextResponse = {
        'data': [
          {'category_id': 1},
        ],
      };

      final result = await controller.categories();

      expect(() => result.add({'category_id': 2}), throwsUnsupportedError);
    });

    test('locations sends the zone filter only when given', () async {
      await controller.locations(zone: 'off_campus');
      expect(sent(), 'GET /api/locations');
      expect(sentQuery(), {'zone': 'off_campus'});

      requests.clear();
      await controller.locations();
      expect(sent(), 'GET /api/locations');
      expect(sentQuery(), isEmpty);
    });

    test('locations returns the rows from "data" as maps', () async {
      nextResponse = {
        'data': [
          {'location_id': 3, 'name': 'Lamduan 1'},
        ],
      };

      expect(await controller.locations(), [
        {'location_id': 3, 'name': 'Lamduan 1'},
      ]);
    });

    // ------------------------------------------------------------------
    // detail / myListings
    // ------------------------------------------------------------------

    test('detail requests the product by id', () async {
      await controller.detail(7);

      expect(sent(), 'GET /api/products/7');
    });

    test('myListings uses default paging', () async {
      await controller.myListings();

      expect(sent(), 'GET /api/my/listings');
      expect(sentQuery(), {'page': '1', 'limit': '20'});
    });

    test('myListings sends custom paging', () async {
      await controller.myListings(page: 2, limit: 5);

      expect(sentQuery(), {'page': '2', 'limit': '5'});
    });

    // ------------------------------------------------------------------
    // create / update / addImage
    // ------------------------------------------------------------------

    test('create posts the listing as the request body', () async {
      await controller.create({'title': 'Oak desk', 'price': 450});

      expect(sent(), 'POST /api/products');
      expect(sentBody(), {'title': 'Oak desk', 'price': 450});
    });

    test('update puts the listing to the product id', () async {
      await controller.update(9, {'title': 'Oak desk (used)'});

      expect(sent(), 'PUT /api/products/9');
      expect(sentBody(), {'title': 'Oak desk (used)'});
    });

    test('addImage defaults display_order to 1', () async {
      await controller.addImage(9, 'https://example.com/a.jpg');

      expect(sent(), 'POST /api/products/9/images');
      expect(sentBody(), {
        'image_url': 'https://example.com/a.jpg',
        'display_order': 1,
      });
    });

    test('addImage sends a custom display_order', () async {
      await controller.addImage(9, 'https://example.com/b.jpg', displayOrder: 3);

      expect(sentBody()['display_order'], 3);
    });
  });
}
