import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uni_swap/controller/app_controllers.dart';

void main() {
  tearDown(() => setupControllers());

  test('setupControllers เชื่อม tokenProvider ของทุก controller และล้าง state เมื่อรีเซ็ต', () async {
    final seenAuthHeaders = <String?>[];

    MockClient buildClient() {
      return MockClient((request) async {
        seenAuthHeaders.add(request.headers['authorization']);
        if (request.url.path.endsWith('/login')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'token': 'shared-jwt-token',
              'user': {'user_id': 1, 'role': 'admin'},
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });
    }

    setupControllers(
      client: buildClient(),
      baseUrl: 'http://example.test/api',
    );

    expect(apiClient.baseUrl, 'http://example.test/api');
    expect(authController.isAuthenticated, isFalse);

    await authController.login(email: 'admin@unisw.ap', password: 'secret');
    expect(authController.isAuthenticated, isTrue);

    await productController.myListings();
    await orderController.list();
    await adminController.dashboard();

    expect(seenAuthHeaders, [
      null, // login request
      'Bearer shared-jwt-token',
      'Bearer shared-jwt-token',
      'Bearer shared-jwt-token',
    ]);

    // รีเซ็ต controllers ใหม่ทั้งหมด token เดิมต้องถูกล้างออก
    setupControllers(client: buildClient());
    expect(authController.isAuthenticated, isFalse);
    expect(authController.token, isNull);

    await productController.browse();
    expect(seenAuthHeaders.last, isNull);
  });
}
