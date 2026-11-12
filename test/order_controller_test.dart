// Unit tests for OrderController.
//
// OrderController and ApiClient are the REAL classes under test. Only the
// http.Client is replaced with a MockClient, so no server is used. Dates use
// DateTime.utc so the expected strings do not depend on the machine timezone.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/order_controller.dart';

void main() {
  group('OrderController', () {
    late List<http.Request> requests;
    late ApiClient api;
    late OrderController controller;
    var nextResponse = <String, dynamic>{'success': true};
    var nextStatus = 200;

    String sent() => '${requests.single.method} ${requests.single.url.path}';
    Map<String, dynamic> sentBody() =>
        jsonDecode(requests.single.body) as Map<String, dynamic>;

    setUp(() {
      requests = [];
      nextResponse = {'success': true};
      nextStatus = 200;
      api = ApiClient(
        baseUrl: 'http://mock-api.local/api',
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode(nextResponse),
            nextStatus,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      controller = OrderController(api);
    });

    tearDown(() => api.close());

    // ------------------------------------------------------------------
    // list
    // ------------------------------------------------------------------

    test('list uses default paging', () async {
      await controller.list();

      expect(sent(), 'GET /api/orders');
      expect(requests.single.url.queryParameters, {'page': '1', 'limit': '20'});
    });

    test('list sends custom paging', () async {
      await controller.list(page: 2, limit: 5);

      expect(requests.single.url.queryParameters, {'page': '2', 'limit': '5'});
    });

    // ------------------------------------------------------------------
    // create
    // ------------------------------------------------------------------

    test('create sends the product, location and a UTC ISO-8601 datetime',
        () async {
      nextResponse = {'success': true, 'order_id': 8};

      final result = await controller.create(
        productId: 5,
        meetupLocation: 'Library entrance',
        meetupDateTime: DateTime.utc(2026, 11, 20, 10, 30),
      );

      expect(sent(), 'POST /api/orders');
      expect(sentBody(), {
        'product_id': 5,
        'meetup_location': 'Library entrance',
        'meetup_datetime': '2026-11-20T10:30:00.000Z',
      });
      expect(result['order_id'], 8);
    });

    test('create sends meetup_datetime as null when no date is given',
        () async {
      await controller.create(productId: 5, meetupLocation: 'Library entrance');

      final body = sentBody();
      expect(body.containsKey('meetup_datetime'), isTrue);
      expect(body['meetup_datetime'], isNull);
    });

    test('create throws ApiException with the server message on an error',
        () async {
      nextStatus = 400;
      nextResponse = {'message': 'Product is not available'};

      await expectLater(
        controller.create(productId: 5, meetupLocation: 'Library entrance'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Product is not available')
              .having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
    });

    // ------------------------------------------------------------------
    // cancel / updateMeetup
    // ------------------------------------------------------------------

    test('cancel posts to the order cancel path with an empty body', () async {
      await controller.cancel(12);

      expect(sent(), 'POST /api/orders/12/cancel');
      expect(sentBody(), isEmpty);
    });

    test('updateMeetup puts the new location and a UTC datetime', () async {
      await controller.updateMeetup(
        orderId: 12,
        location: 'Cafeteria',
        dateTime: DateTime.utc(2026, 12, 1, 8),
      );

      expect(sent(), 'PUT /api/orders/12/meetup');
      expect(sentBody(), {
        'meetup_location': 'Cafeteria',
        'meetup_datetime': '2026-12-01T08:00:00.000Z',
      });
    });

    test('updateMeetup sends meetup_datetime as null when no date is given',
        () async {
      await controller.updateMeetup(orderId: 12, location: 'Cafeteria');

      expect(sentBody()['meetup_datetime'], isNull);
    });

    // ------------------------------------------------------------------
    // pay
    // ------------------------------------------------------------------

    test('pay defaults to the gateway method with empty references', () async {
      await controller.pay(12);

      expect(sent(), 'POST /api/orders/12/pay');
      expect(sentBody(), {
        'payment_method': 'gateway',
        'transaction_ref': null,
        'payment_slip_url': null,
      });
    });

    test('pay sends the given method, reference and slip', () async {
      await controller.pay(
        12,
        method: 'bank_transfer',
        transactionRef: 'REF-001',
        slipUrl: 'https://example.com/slip.jpg',
      );

      expect(sentBody(), {
        'payment_method': 'bank_transfer',
        'transaction_ref': 'REF-001',
        'payment_slip_url': 'https://example.com/slip.jpg',
      });
    });

    // ------------------------------------------------------------------
    // requestRefund / report
    // ------------------------------------------------------------------

    test('requestRefund posts the reason to the order refunds path', () async {
      await controller.requestRefund(12, 'Item not as described');

      expect(sent(), 'POST /api/orders/12/refunds');
      expect(sentBody(), {'reason': 'Item not as described'});
    });

    test('report posts to /reports with the order, type and reason', () async {
      await controller.report(
        orderId: 12,
        type: 'product_problem',
        reason: 'Broken leg',
      );

      expect(sent(), 'POST /api/reports');
      expect(sentBody(), {
        'order_id': 12,
        'report_type': 'product_problem',
        'reason': 'Broken leg',
        'evidence_url': null,
      });
    });

    test('report includes the evidence url when given', () async {
      await controller.report(
        orderId: 12,
        type: 'product_problem',
        reason: 'Broken leg',
        evidenceUrl: 'https://example.com/evidence.jpg',
      );

      expect(sentBody()['evidence_url'], 'https://example.com/evidence.jpg');
    });
  });
}
