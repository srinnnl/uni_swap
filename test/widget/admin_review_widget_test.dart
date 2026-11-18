// Widget test กลุ่ม 5: แอดมินอนุมัติผู้ใช้และตรวจสินค้า
// หน้าที่ครอบคลุม: admin_page (dashboard), admin_users, admin_items
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/view/admin/admin_categories_page.dart';
import 'package:uni_swap/view/admin/admin_items_page.dart';
import 'package:uni_swap/view/admin/admin_locations_page.dart';
import 'package:uni_swap/view/admin/admin_page.dart';
import 'package:uni_swap/view/admin/admin_users_page.dart';
import 'package:uni_swap/view/login.dart';

import 'widget_helpers.dart';

void main() {
  tearDown(() => apiClient.close());

  // ---------------------------------------------------------------------
  // /Admin/Dashboard
  // ---------------------------------------------------------------------
  group('Admin dashboard page', () {
    Future<ApiLog> openDashboard(WidgetTester tester, {ApiOverride? override}) async {
      final log = setupApp(role: 'admin', override: override);
      useTallScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: AdminPage()));
      await tester.pumpAndSettle();
      return log;
    }

    testWidgets('1. The overview of the marketplace should be shown.', (tester) async {
      await openDashboard(tester);

      expect(find.byType(AdminPage), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Marketplace overview'), findsOneWidget);
      expect(find.textContaining(', Admin'), findsOneWidget);
      // the card for items waiting for review
      expect(find.text('Pending Approval'), findsOneWidget);
      expect(find.text('2 items waiting for your review'), findsOneWidget);
      // the 4 statistics
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('3 pending'), findsOneWidget);
      expect(find.text('Locations'), findsOneWidget);
      // 3 active locations from /api/admin/locations
      expect(find.text('3'), findsOneWidget);
      expect(find.text('1 pending'), findsOneWidget);
      expect(find.text('Items'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Manage'), findsOneWidget);
    });

    testWidgets('2. The recent activity should list what needs review.', (tester) async {
      await openDashboard(tester);

      expect(find.text('Recent activity'), findsOneWidget);
      expect(find.text('Old Laptop'), findsOneWidget);
      expect(find.textContaining('Listing awaiting review'), findsOneWidget);
      expect(find.text('Sunrise Apartment'), findsOneWidget);
      expect(find.textContaining('Location request'), findsOneWidget);
    });

    testWidgets('3. With nothing to review, an empty message should be shown.', (tester) async {
      await openDashboard(
        tester,
        override: (request) => request.url.path == '/api/admin/dashboard'
            ? json({
                'success': true,
                'data': {
                  'overview': <String, int>{},
                  'pending_listings': <Map<String, dynamic>>[],
                  'pending_location_requests': <Map<String, dynamic>>[],
                },
              })
            : null,
      );

      expect(find.text('Nothing is waiting for review'), findsOneWidget);
      expect(find.text('0 items waiting for your review'), findsOneWidget);
    });

    testWidgets('4. If loading fails, an error should be shown and retry should work.', (tester) async {
      var failed = false;
      await openDashboard(
        tester,
        override: (request) {
          if (request.url.path == '/api/admin/dashboard' && !failed) {
            failed = true;
            return json({'success': false, 'message': 'Database offline'}, 500);
          }
          return null;
        },
      );

      expect(find.text('Database offline'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Database offline'), findsNothing);
      expect(find.text('Marketplace overview'), findsOneWidget);
      expect(find.text('Pending Approval'), findsOneWidget);
    });

    // การ์ดแต่ละใบต้องพาไปหน้าจัดการที่ตรงกัน
    for (final (label, page) in <(String, Type)>[
      ('Pending Approval', AdminItemsPage),
      ('Users', AdminUsersPage),
      ('Locations', AdminLocationsPage),
      ('Items', AdminItemsPage),
      ('Categories', AdminCategoriesPage),
    ]) {
      testWidgets('5. Tapping "$label" should open the $page.', (tester) async {
        await openDashboard(tester);

        await tapVisible(tester, find.text(label));

        expect(find.byType(page), findsOneWidget);
      });
    }

    testWidgets('6. Log out should ask first and then show the login page.', (tester) async {
      await openDashboard(tester);

      await tapVisible(tester, find.text('Log out'));
      expect(find.text('Log out?'), findsOneWidget);
      expect(find.text('You will need to sign in again.'), findsOneWidget);

      await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Log out')));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('7. Cancelling the log out dialog should stay on the dashboard.', (tester) async {
      await openDashboard(tester);

      await tapVisible(tester, find.text('Log out'));
      await tester.tap(inDialog(find.text('Cancel')));
      await tester.pumpAndSettle();

      expect(find.byType(AdminPage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    });
  });

  // ---------------------------------------------------------------------
  // /Admin/Users
  // ---------------------------------------------------------------------
  group('Admin users page', () {
    Future<ApiLog> openUsers(WidgetTester tester, {ApiOverride? override}) async {
      final log = setupApp(role: 'admin', override: override);
      useTallScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: AdminUsersPage()));
      await tester.pumpAndSettle();
      return log;
    }

    testWidgets('1. All registered users should be listed with their status.', (tester) async {
      await openUsers(tester);

      expect(find.byType(AdminUsersPage), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('4 registered students'), findsOneWidget);
      expect(find.text('4 shown'), findsOneWidget);
      expect(find.text('Maya Kim'), findsOneWidget);
      expect(find.text('@maya · 6501000011'), findsOneWidget);
      expect(find.text('Noah Lee'), findsOneWidget);
      expect(find.text('Olive Park'), findsOneWidget);
      expect(find.text('Root Admin'), findsOneWidget);
      // one badge for each status
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Suspended'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets('2. Typing in the search box should filter the users.', (tester) async {
      await openUsers(tester);

      await tester.enterText(find.byType(TextField), 'noah');
      await tester.pumpAndSettle();

      expect(find.text('1 shown'), findsOneWidget);
      expect(find.text('Noah Lee'), findsOneWidget);
      expect(find.text('Maya Kim'), findsNothing);
    });

    testWidgets('3. A search with no match should show an empty message.', (tester) async {
      await openUsers(tester);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('No users found'), findsOneWidget);
      expect(find.text('0 shown'), findsOneWidget);
    });

    testWidgets('4. The status filter should filter the users.', (tester) async {
      await openUsers(tester);

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Pending'));
      await tester.pumpAndSettle();

      expect(find.text('1 shown'), findsOneWidget);
      expect(find.text('Maya Kim'), findsOneWidget);
      expect(find.text('Noah Lee'), findsNothing);
    });

    testWidgets('5. If loading fails, an error should be shown.', (tester) async {
      await openUsers(
        tester,
        override: (request) => request.url.path == '/api/admin/users'
            ? json({'success': false, 'message': 'Database offline'}, 500)
            : null,
      );

      expect(find.text('Database offline'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('6. A pending user should be approved.', (tester) async {
      final log = await openUsers(tester);

      await tapVisible(tester, find.text('Maya Kim'));
      // details of the user
      expect(find.text('Student ID'), findsOneWidget);
      expect(find.text('6501000011'), findsOneWidget);
      expect(find.text('maya@example.com'), findsOneWidget);
      await tapVisible(tester, find.text('Approve user'));

      expect(log.bodyOf('PUT', '/admin/users/11/status')['status'], 'active');
      expect(find.text('Maya Kim approved'), findsOneWidget);
    });

    testWidgets('7. A pending user should be rejected.', (tester) async {
      final log = await openUsers(tester);

      await tapVisible(tester, find.text('Maya Kim'));
      await tapVisible(tester, find.text('Reject user'));

      expect(log.bodyOf('PUT', '/admin/users/11/status')['status'], 'rejected');
      expect(find.text('Maya Kim rejected'), findsOneWidget);
    });

    testWidgets('8. An active user should be suspended.', (tester) async {
      final log = await openUsers(tester);

      await tapVisible(tester, find.text('Noah Lee'));
      // an active user cannot be approved again
      expect(find.text('Approve user'), findsNothing);
      await tapVisible(tester, find.text('Suspend user'));

      expect(log.bodyOf('PUT', '/admin/users/12/status')['status'], 'suspended');
      expect(find.text('Noah Lee suspended'), findsOneWidget);
    });

    testWidgets('9. A suspended user should be restored.', (tester) async {
      final log = await openUsers(tester);

      await tapVisible(tester, find.text('Olive Park'));
      await tapVisible(tester, find.text('Restore user'));

      expect(log.bodyOf('PUT', '/admin/users/13/status')['status'], 'active');
      expect(find.text('Olive Park restored'), findsOneWidget);
    });

    testWidgets('10. An admin account should have no actions.', (tester) async {
      await openUsers(tester);

      await tapVisible(tester, find.text('Root Admin'));

      expect(find.text('Student ID'), findsOneWidget);
      expect(find.text('Approve user'), findsNothing);
      expect(find.text('Suspend user'), findsNothing);
      expect(find.text('Restore user'), findsNothing);
    });

    testWidgets('11. A server error while changing the status should be shown.', (tester) async {
      await openUsers(
        tester,
        override: (request) => request.method == 'PUT' && request.url.path == '/api/admin/users/11/status'
            ? json({'success': false, 'message': 'Cannot change this user'}, 409)
            : null,
      );

      await tapVisible(tester, find.text('Maya Kim'));
      await tapVisible(tester, find.text('Approve user'));

      expect(find.text('Cannot change this user'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------
  // /Admin/Items (ตรวจสินค้า)
  // ---------------------------------------------------------------------
  group('Admin items page', () {
    Future<ApiLog> openItems(WidgetTester tester, {ApiOverride? override}) async {
      final log = setupApp(role: 'admin', override: override);
      useTallScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: AdminItemsPage()));
      await tester.pumpAndSettle();
      return log;
    }

    testWidgets('1. Listings waiting for review should be shown.', (tester) async {
      await openItems(tester);

      expect(find.byType(AdminItemsPage), findsOneWidget);
      expect(find.text('Items review'), findsOneWidget);
      expect(find.text('2 items waiting for review'), findsOneWidget);
      expect(find.text('Needs attention'), findsOneWidget);
      expect(find.text('2 shown'), findsOneWidget);
      expect(find.text('Old Laptop'), findsOneWidget);
      expect(find.text('Blue Bike'), findsOneWidget);
      expect(find.textContaining('3000.0 THB · Sam Seller'), findsOneWidget);
      // one badge for each kind of review
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Changes requested'), findsOneWidget);
    });

    testWidgets('2. Typing in the search box should filter the listings.', (tester) async {
      await openItems(tester);

      await tester.enterText(find.byType(TextField), 'bike');
      await tester.pumpAndSettle();

      expect(find.text('1 shown'), findsOneWidget);
      expect(find.text('Blue Bike'), findsOneWidget);
      expect(find.text('Old Laptop'), findsNothing);
    });

    testWidgets('3. The status filter should filter the listings.', (tester) async {
      await openItems(tester);

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Changes requested'));
      await tester.pumpAndSettle();

      expect(find.text('1 shown'), findsOneWidget);
      expect(find.text('Blue Bike'), findsOneWidget);
      expect(find.text('Old Laptop'), findsNothing);
    });

    testWidgets('4. With nothing to review, an empty message should be shown.', (tester) async {
      await openItems(
        tester,
        override: (request) => request.url.path == '/api/admin/listings'
            ? json({'success': true, 'data': <Map<String, dynamic>>[], 'has_more': false})
            : null,
      );

      expect(find.text('No items to review'), findsOneWidget);
      expect(find.text('0 items waiting for review'), findsOneWidget);
    });

    testWidgets('5. If loading fails, an error should be shown.', (tester) async {
      await openItems(
        tester,
        override: (request) => request.url.path == '/api/admin/listings'
            ? json({'success': false, 'message': 'Database offline'}, 500)
            : null,
      );

      expect(find.text('Database offline'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('6. Tapping a listing should show its details and the review actions.', (tester) async {
      await openItems(tester);

      await tapVisible(tester, find.text('Old Laptop'));

      expect(find.text('3000 THB'), findsOneWidget);
      expect(find.text('Technology'), findsOneWidget);
      expect(find.text('Sam Seller'), findsOneWidget);
      expect(find.text('Off-campus · Test Residence'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Sturdy and ready for a new home.'), findsOneWidget);
      expect(find.text('Approve item'), findsOneWidget);
      expect(find.text('Request changes'), findsOneWidget);
      expect(find.text('Reject item'), findsOneWidget);
    });

    testWidgets('7. Approving a listing should publish it.', (tester) async {
      final log = await openItems(tester);

      await tapVisible(tester, find.text('Old Laptop'));
      await tapVisible(tester, find.text('Approve item'));

      expect(log.bodyOf('PUT', '/admin/listings/301/review')['action'], 'approve');
      expect(find.text('Old Laptop approved and published.'), findsOneWidget);
    });

    testWidgets('8. Requesting changes should send a message to the seller.', (tester) async {
      final log = await openItems(tester);

      await tapVisible(tester, find.text('Old Laptop'));
      await tapVisible(tester, find.text('Request changes'));
      // the note form is the newest sheet, so its text field is the last one
      await tester.enterText(find.byType(TextField).last, 'Please add clearer photos.');
      await tapVisible(tester, find.text('Send to seller'));

      final body = log.bodyOf('PUT', '/admin/listings/301/review');
      expect(body['action'], 'changes_requested');
      expect(body['review_note'], 'Please add clearer photos.');
      expect(find.text('Changes requested from Sam Seller.'), findsOneWidget);
    });

    testWidgets('9. Requesting changes without a message should show an error.', (tester) async {
      final log = await openItems(tester);

      await tapVisible(tester, find.text('Old Laptop'));
      await tapVisible(tester, find.text('Request changes'));
      await tapVisible(tester, find.text('Send to seller'));

      expect(find.text('Please write a short message'), findsOneWidget);
      expect(log.called('PUT', '/admin/listings/301/review'), isFalse);
    });

    testWidgets('10. Rejecting a listing should ask for a reason.', (tester) async {
      final log = await openItems(tester);

      await tapVisible(tester, find.text('Old Laptop'));
      await tapVisible(tester, find.text('Reject item'));
      // the 5 reasons
      expect(find.text('Prohibited item'), findsOneWidget);
      expect(find.text('Misleading information'), findsOneWidget);
      expect(find.text('Poor quality photos'), findsOneWidget);
      expect(find.text('Duplicate item'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
      await tester.tap(find.text('Prohibited item'));
      await tester.pumpAndSettle();

      final body = log.bodyOf('PUT', '/admin/listings/301/review');
      expect(body['action'], 'reject');
      expect(body['reject_reason'], 'prohibited_item');
      expect(find.text('Old Laptop rejected.'), findsOneWidget);
    });

    testWidgets('11. A listing waiting for the seller should have no review actions.', (tester) async {
      await openItems(tester);

      await tapVisible(tester, find.text('Blue Bike'));

      expect(find.text('Sent to seller: Add clearer photos'), findsOneWidget);
      expect(
        find.text('Waiting for the seller to edit and resubmit this listing.'),
        findsOneWidget,
      );
      expect(find.text('Approve item'), findsNothing);
      expect(find.text('Reject item'), findsNothing);
    });

    testWidgets('12. A server error while reviewing should be shown.', (tester) async {
      await openItems(
        tester,
        override: (request) => request.method == 'PUT' && request.url.path == '/api/admin/listings/301/review'
            ? json({'success': false, 'message': 'This listing was already reviewed'}, 409)
            : null,
      );

      await tapVisible(tester, find.text('Old Laptop'));
      await tapVisible(tester, find.text('Approve item'));

      expect(find.text('This listing was already reviewed'), findsOneWidget);
    });
  });
}
