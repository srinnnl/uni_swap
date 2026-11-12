// Unit tests for AuthController.
//
// Approach: AuthController and ApiClient are the REAL classes under test.
// Only the http.Client at the very edge is replaced with a MockClient, so no
// real server or database is used. Every request the app sends is recorded in
// `requests`, which lets the tests check what the controller sends out
// (path, body, headers) as well as how its state changes.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/auth_controller.dart';
import 'package:uni_swap/model/enums.dart';

void main() {
  group('AuthController', () {
    late ApiClient apiClient;
    late AuthController authController;
    late List<http.Request> requests;

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

    String describe(http.Request request) =>
        '${request.method} ${request.url.path}';

    setUp(() {
      requests = [];

      // Remembers the display name so GET /profile reflects a PUT /profile.
      var profileName = 'Original Name';

      // Profile endpoints only accept the token issued by the member login.
      bool hasMemberToken(http.Request request) =>
          request.headers['authorization'] == 'Bearer test_member_token';

      final mockClient = MockClient((request) async {
        requests.add(request);

        // POST /login
        if (request.method == 'POST' && request.url.path.endsWith('/login')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final email = body['email'];
          final password = body['password'];

          if (email == 'member@test.local' && password == 'Test1234') {
            return jsonResponse({
              'token': 'test_member_token',
              'user': {'user_id': 1, 'role': 'member'},
            });
          }
          if (email == 'admin@test.local' && password == 'Test1234') {
            return jsonResponse({
              'token': 'test_admin_token',
              'user': {'user_id': 2, 'role': 'admin'},
            });
          }
          if (email == 'no-token@test.local') {
            return jsonResponse({
              'user': {'user_id': 3, 'role': 'member'},
            });
          }
          if (email == 'unknown-role@test.local') {
            return jsonResponse({
              'token': 'test_unknown_role_token',
              'user': {'user_id': 4, 'role': 'unknown_role'},
            });
          }
          return jsonResponse({
            'message': 'Invalid credentials',
          }, statusCode: 401);
        }

        // GET /profile
        if (request.method == 'GET' && request.url.path.endsWith('/profile')) {
          if (!hasMemberToken(request)) {
            return jsonResponse({'message': 'Unauthorized'}, statusCode: 401);
          }
          return jsonResponse({
            'data': {
              'user_id': 1,
              'display_name': profileName,
              'role': 'member',
            },
          });
        }

        // PUT /profile
        if (request.method == 'PUT' && request.url.path.endsWith('/profile')) {
          if (!hasMemberToken(request)) {
            return jsonResponse({'message': 'Unauthorized'}, statusCode: 401);
          }
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          if (body.containsKey('display_name')) {
            profileName = body['display_name'] as String;
          }
          return jsonResponse({'message': 'Profile updated.'});
        }

        // POST /register
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

    // ------------------------------------------------------------------
    // Initial state
    // ------------------------------------------------------------------

    test('starts signed out with the lowest privileges', () {
      expect(authController.isAuthenticated, isFalse);
      expect(authController.token, isNull);
      expect(authController.user, isNull);
      expect(authController.isBusy, isFalse);
      expect(authController.role, UserRole.member);
      expect(authController.isAdmin, isFalse);
    });

    // ------------------------------------------------------------------
    // Login
    // ------------------------------------------------------------------

    test('logs in as a member and stores the token and user', () async {
      await authController.login(
        email: 'member@test.local',
        password: 'Test1234',
      );

      expect(authController.isAuthenticated, isTrue);
      expect(authController.token, 'test_member_token');
      expect(authController.user?['user_id'], 1);
      expect(authController.role, UserRole.member);
      expect(authController.isAdmin, isFalse);
      expect(authController.isBusy, isFalse);

      // What the controller actually sent to the API.
      expect(requests, hasLength(1));
      expect(describe(requests.single), 'POST /api/login');
      expect(jsonDecode(requests.single.body), {
        'email': 'member@test.local',
        'password': 'Test1234',
      });
    });

    test('logs in as an admin and grants admin privileges', () async {
      await authController.login(
        email: 'admin@test.local',
        password: 'Test1234',
      );

      expect(authController.token, 'test_admin_token');
      expect(authController.role, UserRole.admin);
      expect(authController.isAdmin, isTrue);
    });

    test('trims the email before sending it', () async {
      await authController.login(
        email: '  member@test.local  ',
        password: 'Test1234',
      );

      final sent = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(sent['email'], 'member@test.local');
      expect(authController.isAuthenticated, isTrue);
    });

    test(
      'throws ApiException and keeps state empty on wrong credentials',
      () async {
        await expectLater(
          authController.login(email: 'wrong@test.local', password: 'bad'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.message, 'message', 'Invalid credentials')
                .having((e) => e.statusCode, 'statusCode', 401),
          ),
        );

        expect(authController.isAuthenticated, isFalse);
        expect(authController.token, isNull);
        expect(authController.user, isNull);
        expect(authController.isBusy, isFalse);
      },
    );

    test(
      'throws when the response has no token and leaves no user behind',
      () async {
        await expectLater(
          authController.login(
            email: 'no-token@test.local',
            password: 'Test1234',
          ),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              contains('did not contain a token'),
            ),
          ),
        );

        expect(authController.isAuthenticated, isFalse);
        expect(authController.token, isNull);
        expect(authController.user, isNull);
        expect(authController.isBusy, isFalse);
      },
    );

    test('falls back to member for an unknown role', () async {
      await authController.login(
        email: 'unknown-role@test.local',
        password: 'Test1234',
      );

      expect(authController.isAuthenticated, isTrue);
      expect(authController.role, UserRole.member);
      expect(authController.isAdmin, isFalse);
    });

    // ------------------------------------------------------------------
    // Busy state and listeners
    // ------------------------------------------------------------------

    test(
      'notifies listeners with the busy flag during a successful login',
      () async {
        final busyValues = <bool>[];
        authController.addListener(() => busyValues.add(authController.isBusy));

        await authController.login(
          email: 'member@test.local',
          password: 'Test1234',
        );

        // busy on, token/user stored (still busy), busy off.
        expect(busyValues, [true, true, false]);
      },
    );

    test('notifies busy on then off when login fails', () async {
      final busyValues = <bool>[];
      authController.addListener(() => busyValues.add(authController.isBusy));

      await expectLater(
        authController.login(email: 'wrong@test.local', password: 'bad'),
        throwsA(isA<ApiException>()),
      );

      expect(busyValues, [true, false]);
    });

    // ------------------------------------------------------------------
    // Sign out
    // ------------------------------------------------------------------

    test('clears all authentication data on sign out', () async {
      await authController.login(
        email: 'admin@test.local',
        password: 'Test1234',
      );
      expect(authController.isAdmin, isTrue);

      authController.signOut();

      expect(authController.isAuthenticated, isFalse);
      expect(authController.token, isNull);
      expect(authController.user, isNull);
      expect(authController.isAdmin, isFalse);
      expect(authController.role, UserRole.member);
    });

    // ------------------------------------------------------------------
    // User getter
    // ------------------------------------------------------------------

    test('exposes the user as an unmodifiable map', () async {
      await authController.login(
        email: 'member@test.local',
        password: 'Test1234',
      );

      expect(
        () => authController.user!['role'] = 'admin',
        throwsUnsupportedError,
      );
      expect(authController.isAdmin, isFalse);
    });

    // ------------------------------------------------------------------
    // Profile
    // ------------------------------------------------------------------

    test('sends no Authorization header before login', () async {
      await expectLater(
        authController.loadProfile(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );

      expect(requests.single.headers.containsKey('authorization'), isFalse);
      expect(authController.user, isNull);
    });

    test('loads the profile with the Bearer token after login', () async {
      await authController.login(
        email: 'member@test.local',
        password: 'Test1234',
      );
      await authController.loadProfile();

      expect(
        requests.last.headers['authorization'],
        'Bearer test_member_token',
      );
      expect(authController.user?['display_name'], 'Original Name');
    });

    test('updateProfile sends PUT then reloads the profile with GET', () async {
      await authController.login(
        email: 'member@test.local',
        password: 'Test1234',
      );
      requests.clear();

      final result = await authController.updateProfile({
        'display_name': 'Updated Name',
      });

      expect(result['message'], 'Profile updated.');
      expect(requests.map(describe).toList(), [
        'PUT /api/profile',
        'GET /api/profile',
      ]);
      expect(jsonDecode(requests.first.body), {'display_name': 'Updated Name'});
      expect(authController.user?['display_name'], 'Updated Name');
    });

    // ------------------------------------------------------------------
    // Register
    // ------------------------------------------------------------------

    test('registers without signing the user in', () async {
      final result = await authController.register({
        'email': 'new@student.ac.th',
        'password': 'password123',
      });

      expect(result['message'], 'Registration submitted.');
      expect(describe(requests.single), 'POST /api/register');
      expect(jsonDecode(requests.single.body), {
        'email': 'new@student.ac.th',
        'password': 'password123',
      });
      expect(authController.isAuthenticated, isFalse);
      expect(authController.token, isNull);
      expect(authController.isBusy, isFalse);
    });

    test('throws ApiException when registration fails', () async {
      await expectLater(
        authController.register({
          'email': 'exist@student.ac.th',
          'password': 'password123',
        }),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Email already exists',
          ),
        ),
      );

      expect(authController.isBusy, isFalse);
    });
  });
}
