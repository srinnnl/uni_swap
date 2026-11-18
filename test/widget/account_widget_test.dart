// Widget test กลุ่ม 1: บัญชีผู้ใช้
// หน้าที่ครอบคลุม: login, register, profile, request_location
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/view/admin/admin_page.dart';
import 'package:uni_swap/view/login.dart';
import 'package:uni_swap/view/main_screen.dart';
import 'package:uni_swap/view/user/profile_page.dart';
import 'package:uni_swap/view/user/register_page.dart';
import 'package:uni_swap/view/user/request_location_page.dart';

import 'widget_helpers.dart';

void main() {
  tearDown(() => apiClient.close());

  // ---------------------------------------------------------------------
  // /User/Login
  // ---------------------------------------------------------------------
  group('Login page', () {
    testWidgets('1. At first, the login page should be shown.', (tester) async {
      setupApp();
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('UniSwap'), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
      // 2 text fields: email and password
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('2. Incomplete input and sign in should show errors.', (tester) async {
      setupApp();
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      // tap the sign in button without typing anything
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Sign in'));

      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('3. An invalid email should show an error.', (tester) async {
      setupApp();
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
      await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Sign in'));

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('4. The password field can be shown and hidden.', (tester) async {
      setupApp();
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      // hidden at first
      var password = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(password.obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();

      password = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(password.obscureText, isFalse);
    });

    testWidgets('5. Wrong password should show the server error.', (tester) async {
      // mocked server: login fails
      setupApp(
        override: (request) => request.url.path == '/api/login'
            ? json({'success': false, 'message': 'Invalid email or password'}, 401)
            : null,
      );
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrong-pass');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Sign in'));

      expect(find.text('Invalid email or password'), findsOneWidget);
      // still on the login page and not signed in
      expect(find.byType(LoginPage), findsOneWidget);
      expect(authController.isAuthenticated, isFalse);
    });

    testWidgets('6. An account waiting for approval cannot sign in.', (tester) async {
      setupApp(
        override: (request) => request.url.path == '/api/login'
            ? json({'success': false, 'message': 'Your account is waiting for admin approval'}, 403)
            : null,
      );
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'maya@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Sign in'));

      expect(find.text('Your account is waiting for admin approval'), findsOneWidget);
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('7. If the server cannot be reached, an error should be shown.', (tester) async {
      setupApp(
        override: (request) {
          if (request.url.path == '/api/login') {
            throw http.ClientException('connection refused');
          }
          return null;
        },
      );
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Sign in'));

      expect(find.textContaining('Could not reach the server'), findsOneWidget);
    });

    testWidgets('8. Member login should show the user marketplace.', (tester) async {
      setupApp(role: 'member');
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
      final signIn = find.widgetWithText(FilledButton, 'Sign in');
      await tester.ensureVisible(signIn);
      await tester.tap(signIn);
      await pumpAfterNavigation(tester);

      expect(find.byType(MainScreen), findsOneWidget);
      expect(find.text('Home'), findsWidgets);
    });

    testWidgets('9. Admin login should show the admin dashboard.', (tester) async {
      setupApp(role: 'admin');
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'admin@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
      final signIn = find.widgetWithText(FilledButton, 'Sign in');
      await tester.ensureVisible(signIn);
      await tester.tap(signIn);
      await pumpAfterNavigation(tester);

      expect(find.byType(AdminPage), findsOneWidget);
      expect(find.text('Marketplace overview'), findsOneWidget);
    });

    testWidgets('10. Create account should open the registration page.', (tester) async {
      setupApp();
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Create account'));

      expect(find.byType(RegisterPage), findsOneWidget);
      expect(find.text('Create your account'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------
  // /User/Register
  // ---------------------------------------------------------------------
  group('Register page', () {
    // helper: เลือก Dorm A (on-campus) จากรายการที่พักในหน้า register
    Future<void> pickDormA(WidgetTester tester) async {
      await tapVisible(tester, find.text('Select your residence'));
      await tester.tap(find.text('On-campus'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dorm A'));
      await tester.pumpAndSettle();
    }

    testWidgets('1. At first, the registration form should be shown.', (tester) async {
      setupApp();
      useTallScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterPage), findsOneWidget);
      expect(find.text('Create your account'), findsOneWidget);
      // 5 text fields: full name, student id, email, username, password
      expect(find.byType(TextFormField), findsNWidgets(5));
      expect(find.text('Select your residence'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Create account'), findsOneWidget);
    });

    testWidgets('2. Empty input and submit should show errors.', (tester) async {
      setupApp();
      useTallScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.widgetWithText(FilledButton, 'Create account'));

      expect(find.text('Enter your full name'), findsOneWidget);
      expect(find.text('Student ID must be 10 digits'), findsOneWidget);
      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('At least 3 characters'), findsOneWidget);
      // the password hint has the same text, so the error makes it appear twice
      expect(find.text('At least 8 characters'), findsWidgets);
      expect(find.text('Please select your residence'), findsOneWidget);
    });

    testWidgets('3. A student id that is not 10 digits should show an error.', (tester) async {
      setupApp();
      useTallScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(1), '12345');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Create account'));

      expect(find.text('Student ID must be 10 digits'), findsOneWidget);
    });

    testWidgets('4. Choosing a residence should show its name.', (tester) async {
      setupApp();
      useTallScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));
      await tester.pumpAndSettle();

      await pickDormA(tester);

      expect(find.text('Dorm A'), findsOneWidget);
      expect(find.text('Select your residence'), findsNothing);
    });

    testWidgets('5. Choosing "Other" should ask for the residence name.', (tester) async {
      setupApp();
      useTallScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Select your residence'));
      await tester.tap(find.text('Other (not listed)'));
      await tester.pumpAndSettle();

      // a 6th text field appears for the custom residence name
      expect(find.byType(TextFormField), findsNWidgets(6));
      expect(find.textContaining('An admin will review it'), findsOneWidget);
    });

    testWidgets('6. If residences cannot be loaded, a retry button should be shown.', (tester) async {
      setupApp(
        override: (request) => request.url.path == '/api/locations'
            ? json({'success': false, 'message': 'Database offline'}, 500)
            : null,
      );
      useTallScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));
      await tester.pumpAndSettle();

      expect(find.text('Could not load residences. Tap to retry.'), findsOneWidget);
    });

    testWidgets('7. Correct input should register and go back to the login page.', (tester) async {
      final log = setupApp();
      useTallScreen(tester);
      // start from the login page, like a real user
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Create account'));

      await tester.enterText(find.byType(TextFormField).at(0), 'Maya Kim');
      await tester.enterText(find.byType(TextFormField).at(1), '6501000099');
      await tester.enterText(find.byType(TextFormField).at(2), 'maya@example.com');
      await tester.enterText(find.byType(TextFormField).at(3), 'maya');
      await tester.enterText(find.byType(TextFormField).at(4), 'secret123');
      await pickDormA(tester);
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Create account'));

      // the form was sent to the server with the chosen residence
      final body = log.bodyOf('POST', '/register');
      expect(body['fullName'], 'Maya Kim');
      expect(body['studentId'], '6501000099');
      expect(body['residenceZone'], 'on_campus');
      expect(body['residenceLocationId'], 2);

      // back on the login page with a confirmation message
      expect(find.byType(RegisterPage), findsNothing);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(
        find.text('Registration submitted. You can sign in after admin approval.'),
        findsOneWidget,
      );
    });

    testWidgets('8. A duplicate email should show the server error.', (tester) async {
      setupApp(
        override: (request) => request.url.path == '/api/register'
            ? json({'success': false, 'message': 'Email already registered'}, 409)
            : null,
      );
      useTallScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Maya Kim');
      await tester.enterText(find.byType(TextFormField).at(1), '6501000099');
      await tester.enterText(find.byType(TextFormField).at(2), 'maya@example.com');
      await tester.enterText(find.byType(TextFormField).at(3), 'maya');
      await tester.enterText(find.byType(TextFormField).at(4), 'secret123');
      await pickDormA(tester);
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Create account'));

      expect(find.text('Email already registered'), findsOneWidget);
      // stays on the registration page
      expect(find.byType(RegisterPage), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------
  // /User/Profile
  // ---------------------------------------------------------------------
  group('Profile page', () {
    // helper: เปิดหน้า Profile ในสถานะล็อกอินแล้ว
    Future<ApiLog> openProfile(WidgetTester tester, {ApiOverride? override}) async {
      final log = setupApp(override: override);
      await signIn(tester);
      useTallScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await tester.pumpAndSettle();
      return log;
    }

    // helper: เปิด sheet เลือกที่พัก แล้วเลือก Dorm A
    Future<void> chooseDormA(WidgetTester tester) async {
      await tapVisible(tester, find.text('My location'));
      await tester.tap(find.text('On-campus'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dorm A'));
      await tester.pumpAndSettle();
    }

    testWidgets('1. The profile of the signed-in member should be shown.', (tester) async {
      await openProfile(tester);

      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.text('@test_member'), findsOneWidget);
      expect(find.textContaining('Member since Sep 2025'), findsOneWidget);
      // statistics from the dashboard: 5 items, 2 sold
      expect(find.text('Items'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Sold'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      // current residence
      expect(find.text('My location'), findsOneWidget);
      expect(find.text('Off-campus dorms · Test Residence'), findsOneWidget);
    });

    testWidgets('2. Without pending work, "Needs your attention" should be hidden.', (tester) async {
      await openProfile(tester);

      expect(find.text('Needs your attention'), findsNothing);
    });

    testWidgets('3. Items to fix, active orders and reviews should be listed.', (tester) async {
      await openProfile(
        tester,
        override: (request) => request.url.path == '/api/dashboard'
            ? json({
                'success': true,
                'data': sampleDashboard(
                  counts: {
                    'my_listings': 5,
                    'sold_listings': 2,
                    'listings_to_review': 2,
                    'listings_to_fix': 1,
                    'buying_active': 1,
                    'selling_active': 0,
                  },
                  recentOrders: [sampleOrder(deadline: isoIn(const Duration(minutes: 20)))],
                ),
              })
            : null,
      );

      expect(find.text('Needs your attention'), findsOneWidget);
      expect(find.text('1 item needs changes'), findsOneWidget);
      expect(find.text('Buying · Study Desk'), findsOneWidget);
      expect(find.textContaining('Pay before'), findsOneWidget);
      expect(find.text('2 items are waiting for review'), findsOneWidget);
    });

    testWidgets('4. If statistics cannot be loaded, dashes should be shown.', (tester) async {
      await openProfile(
        tester,
        override: (request) => request.url.path == '/api/dashboard'
            ? json({'success': false, 'message': 'Database offline'}, 500)
            : null,
      );

      // one dash for "Items" and one for "Sold"
      expect(find.text('–'), findsNWidgets(2));
    });

    testWidgets('5. If the profile cannot be loaded, a retry button should be shown.', (tester) async {
      await openProfile(
        tester,
        override: (request) => request.method == 'GET' && request.url.path == '/api/profile'
            ? json({'success': false, 'message': 'Database offline'}, 500)
            : null,
      );

      expect(find.text('Unable to load profile. Tap to retry.'), findsOneWidget);
    });

    testWidgets('6. Changing the residence should save it.', (tester) async {
      // the member has no listing at the old place, so no warning is needed
      final log = await openProfile(
        tester,
        override: (request) => request.url.path == '/api/my/listings'
            ? json({'success': true, 'data': <Map<String, dynamic>>[], 'has_more': false})
            : null,
      );

      await chooseDormA(tester);

      final body = log.bodyOf('PUT', '/profile');
      expect(body['residence_location_id'], 2);
      expect(body['residence_zone'], 'on_campus');
      expect(find.text('Residence updated'), findsOneWidget);
      expect(find.text('On-campus dorms · Dorm A'), findsOneWidget);
    });

    testWidgets('7. Changing the residence with active listings should ask first.', (tester) async {
      // the default listings are still at the old residence
      final log = await openProfile(tester);

      await chooseDormA(tester);

      expect(find.text('Change residence?'), findsOneWidget);
      // cancel: nothing is saved
      await tester.tap(inDialog(find.text('Cancel')));
      await tester.pumpAndSettle();

      expect(find.text('Change residence?'), findsNothing);
      expect(log.called('PUT', '/profile'), isFalse);
      expect(find.text('Off-campus dorms · Test Residence'), findsOneWidget);
    });

    testWidgets('8. Confirming the warning should change the residence.', (tester) async {
      final log = await openProfile(tester);

      await chooseDormA(tester);
      await tester.tap(inDialog(find.text('Change anyway')));
      await tester.pumpAndSettle();

      expect(log.called('PUT', '/profile'), isTrue);
      expect(find.text('Residence updated'), findsOneWidget);
    });

    testWidgets('9. "Request a location" should open the request page.', (tester) async {
      await openProfile(tester);

      await tapVisible(tester, find.text('My location'));
      await tester.tap(find.text('Request a location'));
      await tester.pumpAndSettle();

      expect(find.byType(RequestLocationPage), findsOneWidget);
      // the page shows the current residence
      expect(find.text('Your current location'), findsOneWidget);
    });

    testWidgets('10. Log out should ask first and then show the login page.', (tester) async {
      await openProfile(tester);

      await tapVisible(tester, find.text('Log out'));
      expect(find.text('Log out?'), findsOneWidget);

      await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Log out')));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(authController.isAuthenticated, isFalse);
    });
  });

  // ---------------------------------------------------------------------
  // /User/RequestLocation
  // ---------------------------------------------------------------------
  group('Request location page', () {
    // helper: เปิดหน้า request location ผ่าน PushHost (หน้านี้ pop ค่า true กลับ)
    Future<void> openRequestPage(WidgetTester tester, {String? current}) async {
      useTallScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: PushHost<bool>(
            builder: (_) => RequestLocationPage(currentLocation: current),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open page'));
      await tester.pumpAndSettle();
    }

    testWidgets('1. At first, the request form should be shown.', (tester) async {
      setupApp();
      await openRequestPage(tester);

      expect(find.byType(RequestLocationPage), findsOneWidget);
      expect(find.text('Your current location'), findsOneWidget);
      expect(find.text('Not set yet'), findsOneWidget);
      expect(find.text('Location name'), findsOneWidget);
      expect(find.text('Choose a zone'), findsOneWidget);
      // 3 text fields: name, address, reason
      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.widgetWithText(FilledButton, 'Submit request'), findsOneWidget);
    });

    testWidgets('2. The current location should be shown when it is set.', (tester) async {
      setupApp();
      await openRequestPage(tester, current: 'Dorm A');

      expect(find.text('Dorm A'), findsOneWidget);
      expect(find.text('Not set yet'), findsNothing);
    });

    testWidgets('3. Empty input and submit should show errors.', (tester) async {
      final log = setupApp();
      await openRequestPage(tester);

      await tapVisible(tester, find.widgetWithText(FilledButton, 'Submit request'));

      expect(find.text('Please enter the location name'), findsOneWidget);
      expect(find.text('Please choose a zone'), findsOneWidget);
      expect(log.called('POST', '/location-requests'), isFalse);
    });

    testWidgets('4. Choosing a zone should show its name.', (tester) async {
      setupApp();
      await openRequestPage(tester);

      await tapVisible(tester, find.text('Choose a zone'));
      expect(find.text('Where is it?'), findsOneWidget);
      await tester.tap(find.text('Off-campus dorms'));
      await tester.pumpAndSettle();

      expect(find.text('Off-campus dorms'), findsOneWidget);
      expect(find.text('Choose a zone'), findsNothing);
    });

    testWidgets('5. A correct request should be sent and the page should close.', (tester) async {
      final log = setupApp();
      await openRequestPage(tester);

      await tester.enterText(find.byType(TextField).at(0), 'Riverside Residence');
      await tapVisible(tester, find.text('Choose a zone'));
      await tester.tap(find.text('Off-campus dorms'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Submit request'));

      final body = log.bodyOf('POST', '/location-requests');
      expect(body['name'], 'Riverside Residence');
      expect(body['zone'], 'off_campus');
      // the page closed with the result true and a message was shown
      expect(find.byType(RequestLocationPage), findsNothing);
      expect(find.text('Result: true'), findsOneWidget);
      expect(
        find.text('Request sent. Your place shows as pending until an admin reviews it.'),
        findsOneWidget,
      );
    });

    testWidgets('6. A server error should be shown and the page should stay.', (tester) async {
      setupApp(
        override: (request) => request.url.path == '/api/location-requests'
            ? json({'success': false, 'message': 'You already have a pending request'}, 409)
            : null,
      );
      await openRequestPage(tester);

      await tester.enterText(find.byType(TextField).at(0), 'Riverside Residence');
      await tapVisible(tester, find.text('Choose a zone'));
      await tester.tap(find.text('Off-campus dorms'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Submit request'));

      expect(find.text('You already have a pending request'), findsOneWidget);
      expect(find.byType(RequestLocationPage), findsOneWidget);
    });
  });
}
