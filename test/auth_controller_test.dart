import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/auth_controller.dart';
import 'package:uni_swap/model/enums.dart';

void main() {
  group('AuthController - User Role Tests', () {
    late ApiClient apiClient;
    late AuthController authController;
    late MockClient mockClient;

    // Helper: create JSON HTTP response
    http.Response jsonResponse(
      Map<String, dynamic> body, {
      int statusCode = 200,
    }) {
      return http.Response(
        jsonEncode(body),
        statusCode,
        headers: {'content-type': 'application/json'},
      );
    }

    setUp(() {
      // 💡 ตัวแปรพระเอกของเรา ช่วยจำค่าชื่อที่ถูกอัพเดท
      String mockDisplayName = 'Original Name';

      mockClient = MockClient((request) async {
        // --- ดัก POST /login ---
        if (request.method == 'POST' && request.url.path.endsWith('/login')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;

          final email = body['email'];
          final password = body['password'];

          // Successful Member Login
          if (email == 'member@test.local' && password == 'Test1234') {
            return jsonResponse({
              'token': 'test_member_token',
              'user': {'user_id': 1, 'role': 'member'},
            });
          }

          // Successful Admin Login
          if (email == 'admin@test.local' && password == 'Test1234') {
            return jsonResponse({
              'token': 'test_admin_token',
              'user': {'user_id': 2, 'role': 'admin'},
            });
          }

          // Login response without token
          if (email == 'no-token@test.local') {
            return jsonResponse({
              'user': {'user_id': 3, 'role': 'member'},
            });
          }

          // Successful login with an unknown role
          if (email == 'unknown-role@test.local') {
            return jsonResponse({
              'token': 'test_unknown_role_token',
              'user': {'user_id': 4, 'role': 'unknown_role'},
            });
          }

          // Invalid credentials
          return jsonResponse({
            'message': 'Invalid credentials',
          }, statusCode: 401);
        }

        // --- ดัก GET /profile ---
        if (request.method == 'GET' && request.url.path.endsWith('/profile')) {
          return jsonResponse({
            'data': {
              'user_id': 1,
              'display_name': mockDisplayName,
              'role': 'member',
            },
          });
        }

        // --- ดัก PUT /profile ---
        if (request.method == 'PUT' && request.url.path.endsWith('/profile')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;

          // ถ้ามีข้อมูล display_name ส่งมา ให้อัพเดทค่าในตัวแปรจำลองของเรา
          if (body.containsKey('display_name')) {
            mockDisplayName = body['display_name'];
          }

          return jsonResponse({
            'data': {
              'user_id': 1,
              'display_name': mockDisplayName,
              'role': 'member',
            },
          });
        }

        // --- ดัก POST /register ---
        if (request.method == 'POST' &&
            request.url.path.endsWith('/register')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;

          if (body['email'] == 'new@student.ac.th') {
            return jsonResponse({'message': 'Registration submitted.'});
          }
          return jsonResponse({
            'message': 'Email already exists',
          }, statusCode: 400);
        }

        // Unknown endpoint
        return jsonResponse({'message': 'Not Found'}, statusCode: 404);
      });

      apiClient = ApiClient(
        client: mockClient,
        baseUrl: 'http://mock-api.local/api',
        tokenProvider: () => authController.token,
      );

      authController = AuthController(apiClient);
    });

    tearDown(() {
      authController.dispose();
      apiClient.close();
    });

    // --------------------------------------------------
    // 1. Login Success
    // --------------------------------------------------

    test('should login successfully with Member role', () async {
      await authController.login(
        email: 'member@test.local',
        password: 'Test1234',
      );

      expect(authController.isAuthenticated, isTrue);
      expect(authController.token, 'test_member_token');

      expect(authController.role, UserRole.member);
      expect(authController.isAdmin, isFalse);

      expect(authController.user?['user_id'], 1);
      expect(authController.user?['role'], 'member');

      expect(authController.isBusy, isFalse);
    });

    test('should login successfully with Admin role', () async {
      await authController.login(
        email: 'admin@test.local',
        password: 'Test1234',
      );

      expect(authController.isAuthenticated, isTrue);
      expect(authController.token, 'test_admin_token');

      expect(authController.role, UserRole.admin);
      expect(authController.isAdmin, isTrue);
    });

    // --------------------------------------------------
    // 2. Login Failure
    // --------------------------------------------------

    test('should throw ApiException when login fails', () async {
      final loginFuture = authController.login(
        email: 'wrong@test.local',
        password: 'WrongPassword',
      );

      await expectLater(
        loginFuture,
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'error message',
            contains('Invalid credentials'),
          ),
        ),
      );

      expect(authController.isAuthenticated, isFalse);
      expect(authController.token, isNull);
      expect(authController.isBusy, isFalse);
    });

    // --------------------------------------------------
    // 3. Login Response Without Token
    // --------------------------------------------------

    test('should throw ApiException when response has no token', () async {
      final loginFuture = authController.login(
        email: 'no-token@test.local',
        password: 'Test1234',
      );

      await expectLater(
        loginFuture,
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'error message',
            contains('did not contain a token'),
          ),
        ),
      );

      expect(authController.isAuthenticated, isFalse);
      expect(authController.token, isNull);
      expect(authController.isBusy, isFalse);
    });

    // --------------------------------------------------
    // 4. Unknown Role Fallback
    // --------------------------------------------------

    test('should fallback to Member when role is unknown', () async {
      await authController.login(
        email: 'unknown-role@test.local',
        password: 'Test1234',
      );

      expect(authController.isAuthenticated, isTrue);

      expect(
        authController.role,
        UserRole.member,
        reason: 'Unknown role should fallback to Member',
      );

      expect(
        authController.isAdmin,
        isFalse,
        reason: 'Unknown role must not grant admin privileges',
      );
    });

    // --------------------------------------------------
    // 5. Sign Out
    // --------------------------------------------------

    test('should clear authentication data after sign out', () async {
      await authController.login(
        email: 'member@test.local',
        password: 'Test1234',
      );

      expect(authController.isAuthenticated, isTrue);

      authController.signOut();

      expect(authController.isAuthenticated, isFalse);
      expect(authController.token, isNull);
      expect(authController.user, isNull);
      expect(authController.isAdmin, isFalse);

      expect(authController.role, UserRole.member);
    });

    // --------------------------------------------------
    // 6. Busy State
    // --------------------------------------------------

    test('should notify listeners when login state changes', () async {
      var notificationCount = 0;

      authController.addListener(() {
        notificationCount++;
      });

      await authController.login(
        email: 'member@test.local',
        password: 'Test1234',
      );

      expect(
        notificationCount,
        greaterThanOrEqualTo(2),
        reason:
            'Listeners should be notified when busy state and login state change',
      );

      expect(authController.isBusy, isFalse);
    });

    // --------------------------------------------------
    // 7. Profile Loading & Updating
    // --------------------------------------------------

    test('should load profile and update state', () async {
      await authController.login(
        email: 'member@test.local',
        password: 'Test1234',
      );
      await authController.loadProfile();

      expect(authController.user?['display_name'], 'Original Name');
    });

    test('should update profile and reload data', () async {
      await authController.login(
        email: 'member@test.local',
        password: 'Test1234',
      );
      await authController.updateProfile({'display_name': 'Updated Name'});

      expect(authController.user?['display_name'], 'Updated Name');
    });

    // --------------------------------------------------
    // 8. Register
    // --------------------------------------------------

    test('should register successfully and return message', () async {
      final result = await authController.register({
        'email': 'new@student.ac.th',
        'password': 'password123',
      });

      expect(result['message'], 'Registration submitted.');
      expect(authController.isBusy, isFalse);
    });

    test('should throw ApiException when register fails', () async {
      final registerFuture = authController.register({
        'email': 'exist@student.ac.th',
        'password': 'password123',
      });

      await expectLater(
        registerFuture,
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'error message',
            contains('Email already exists'),
          ),
        ),
      );
      expect(authController.isBusy, isFalse);
    });
  });
}
