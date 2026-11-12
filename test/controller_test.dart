import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/auth_controller.dart';
import 'package:uni_swap/controller/order_controller.dart';
import 'package:uni_swap/controller/product_controller.dart';

void main() {
  test('ApiClient sends auth header and decodes JSON', () async {
    var sawAuth = false;
    final api = ApiClient(
      baseUrl: 'http://localhost:3000/api',
      tokenProvider: () => 'test-token',
      client: MockClient((request) async {
        sawAuth = request.headers['authorization'] == 'Bearer test-token';
        expect(request.url.path, '/api/products');
        expect(request.url.queryParameters['category_id'], '2');
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      }),
    );

    final result = await api.get('products', query: {'category_id': 2});
    expect(sawAuth, true);
    expect(result['success'], true);
    api.close();
  });

  test('ApiClient reports server errors as ApiException', () async {
    final api = ApiClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'success': false, 'message': 'Invalid credentials'}),
          401,
        ),
      ),
    );

    try {
      await api.post('login', body: {'email': 'x', 'password': 'y'});
      fail('Expected ApiException');
    } on ApiException catch (error) {
      expect(error.statusCode, 401);
      expect(error.message, 'Invalid credentials');
    } finally {
      api.close();
    }
  });

  test('AuthController stores token and user after login', () async {
    final api = ApiClient(
      client: MockClient((request) async {
        expect(request.url.path, '/api/login');
        return http.Response(
          jsonEncode({
            'success': true,
            'token': 'session-token',
            'user': {'user_id': 3, 'role': 'member'},
          }),
          200,
        );
      }),
    );
    final controller = AuthController(api);

    await controller.login(email: 'member@example.com', password: 'secret123');
    expect(controller.isAuthenticated, true);
    expect(controller.token, 'session-token');
    expect(controller.user?['user_id'], 3);
    controller.signOut();
    expect(controller.isAuthenticated, false);
    api.close();
  });

  test('OrderController submits order fields accepted by app.js', () async {
    final api = ApiClient(
      client: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(request.url.path, '/api/orders');
        expect(body['product_id'], 5);
        expect(body['meetup_location'], 'Library entrance');
        return http.Response(jsonEncode({'success': true, 'order_id': 8}), 201);
      }),
    );
    final orders = OrderController(api);

    final result = await orders.create(
      productId: 5,
      meetupLocation: 'Library entrance',
    );
    expect(result['order_id'], 8);
    api.close();
  });

  test('ProductController builds supported browse filters', () async {
    final api = ApiClient(
      client: MockClient((request) async {
        expect(request.url.path, '/api/products');
        expect(request.url.queryParameters['keyword'], 'desk');
        expect(request.url.queryParameters['zone'], 'on_campus');
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      }),
    );

    await ProductController(api).browse(keyword: 'desk', zone: 'on_campus');
    api.close();
  });
}
