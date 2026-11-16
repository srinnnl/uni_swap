import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/view/admin/admin_page.dart';
import 'package:uni_swap/view/login.dart';
import 'package:uni_swap/view/main_screen.dart';
import 'package:uni_swap/view/user/register_page.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

void _setupApp(String role) {
  setupControllers(
    baseUrl: 'http://test.local/api',
    client: MockClient((request) async {
      if (request.url.path == '/api/login') {
        return _json({
          'success': true,
          'token': 'test-session',
          'user': {
            'user_id': role == 'admin' ? 2 : 3,
            'role': role,
            'display_name': role == 'admin' ? 'Test Admin' : 'Test Member',
            'email': 'test@example.com',
            'status': 'active',
            'residence_zone': 'off_campus',
            'residence_location_id': 1,
          },
        });
      }
      if (request.url.path == '/api/profile') {
        return _json({
          'success': true,
          'data': {
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
          },
        });
      }
      if (request.url.path == '/api/dashboard') {
        return _json({
          'success': true,
          'data': {
            'user': {'user_id': 3, 'display_name': 'Test Member'},
            'counts': <String, int>{},
            'recent_listings': [],
            'recent_orders': [],
            'pending_location_request': null,
          },
        });
      }
      if (request.url.path == '/api/admin/dashboard') {
        return _json({
          'success': true,
          'data': {
            'overview': <String, int>{},
            'pending_listings': [],
            'pending_location_requests': [],
          },
        });
      }
      if (request.url.path == '/api/locations') {
        return _json({
          'success': true,
          'data': [
            {
              'location_id': 1,
              'name': 'Test Residence',
              'zone': 'off_campus',
              'is_active': 1,
            },
          ],
        });
      }
      return _json({'success': true, 'data': []});
    }),
  );
}

Future<void> _pumpAfterNavigation(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

void main() {
  tearDown(() => apiClient.close());

  // /User/Login — renders the shared sign-in screen.
  testWidgets('renders the login screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('UniSwap'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  // /User/Register — login navigation opens the student registration form.
  testWidgets('Create account opens the registration page', (tester) async {
    _setupApp('member');
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    final createAccount = find.text('Create account');
    await tester.ensureVisible(createAccount);
    await tester.tap(createAccount);
    await _pumpAfterNavigation(tester);

    expect(find.byType(RegisterPage), findsOneWidget);
    expect(find.text('Create your account'), findsOneWidget);
  });

  // /User/Login — a member session routes to the marketplace shell.
  testWidgets('member login opens the user marketplace', (tester) async {
    _setupApp('member');
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    final signIn = find.widgetWithText(FilledButton, 'Sign in');
    await tester.ensureVisible(signIn);
    await tester.tap(signIn);
    await _pumpAfterNavigation(tester);

    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
  });

  // /Admin/Login — the same auth endpoint routes an admin to AdminPage.
  testWidgets('admin login opens the admin dashboard', (tester) async {
    _setupApp('admin');
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'admin@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    final signIn = find.widgetWithText(FilledButton, 'Sign in');
    await tester.ensureVisible(signIn);
    await tester.tap(signIn);
    await _pumpAfterNavigation(tester);

    expect(find.byType(AdminPage), findsOneWidget);
    expect(find.text('Marketplace overview'), findsOneWidget);
  });
}
