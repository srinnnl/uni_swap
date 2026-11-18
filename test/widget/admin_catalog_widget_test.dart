// Widget test กลุ่ม 6: แอดมินจัดการหมวดหมู่และที่พัก
// หน้าที่ครอบคลุม: admin_categories, admin_locations
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/view/admin/admin_categories_page.dart';
import 'package:uni_swap/view/admin/admin_locations_page.dart';

import 'widget_helpers.dart';

void main() {
  tearDown(() => apiClient.close());

  // ---------------------------------------------------------------------
  // /Admin/Categories
  // ---------------------------------------------------------------------
  group('Admin categories page', () {
    Future<ApiLog> openCategories(WidgetTester tester, {ApiOverride? override}) async {
      final log = setupApp(role: 'admin', override: override);
      useTallScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: AdminCategoriesPage()));
      await tester.pumpAndSettle();
      return log;
    }

    testWidgets('1. All categories should be listed with their status.', (tester) async {
      await openCategories(tester);

      expect(find.byType(AdminCategoriesPage), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('All records'), findsOneWidget);
      expect(find.text('2 shown'), findsOneWidget);
      expect(find.text('Furniture'), findsOneWidget);
      expect(find.text('🪑 3 active products'), findsOneWidget);
      expect(find.text('Books'), findsOneWidget);
      expect(find.text('📚 0 active products'), findsOneWidget);
      // one badge for each status
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
      expect(find.text('Add category'), findsOneWidget);
    });

    testWidgets('2. Typing in the search box should filter the categories.', (tester) async {
      await openCategories(tester);

      await tester.enterText(find.byType(TextField), 'book');
      await tester.pumpAndSettle();

      expect(find.text('1 shown'), findsOneWidget);
      expect(find.text('Books'), findsOneWidget);
      expect(find.text('Furniture'), findsNothing);
    });

    testWidgets('3. The status filter should filter the categories.', (tester) async {
      await openCategories(tester);

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Inactive'));
      await tester.pumpAndSettle();

      expect(find.text('1 shown'), findsOneWidget);
      expect(find.text('Books'), findsOneWidget);
      expect(find.text('Furniture'), findsNothing);
    });

    testWidgets('4. A search with no match should show an empty message.', (tester) async {
      await openCategories(tester);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('No categories found'), findsOneWidget);
    });

    testWidgets('5. If loading fails, an error should be shown.', (tester) async {
      await openCategories(
        tester,
        override: (request) => request.url.path == '/api/admin/categories'
            ? json({'success': false, 'message': 'Database offline'}, 500)
            : null,
      );

      expect(find.text('Database offline'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('6. A new category should be added.', (tester) async {
      final log = await openCategories(tester);

      await tapVisible(tester, find.text('Add category'));
      // text fields: [0] search box, [1] name, [2] emoji
      await tester.enterText(find.byType(TextField).at(1), 'Toys');
      // the form button is the last "Add category" (after the title and the bottom bar)
      await tapVisible(tester, find.text('Add category').last);

      final body = log.bodyOf('POST', '/admin/categories');
      expect(body['name'], 'Toys');
      // no emoji typed: the default one is used
      expect(body['emoji'], '🏷️');
      expect(body['is_active'], isTrue);
      expect(find.text('Category added'), findsOneWidget);
    });

    testWidgets('7. A category without a name should show an error.', (tester) async {
      final log = await openCategories(tester);

      await tapVisible(tester, find.text('Add category'));
      await tapVisible(tester, find.text('Add category').last);

      expect(find.text('Please enter a name'), findsOneWidget);
      expect(log.called('POST', '/admin/categories'), isFalse);
    });

    testWidgets('8. A server error should be shown and the form should stay.', (tester) async {
      await openCategories(
        tester,
        override: (request) => request.method == 'POST' && request.url.path == '/api/admin/categories'
            ? json({'success': false, 'message': 'Category already exists'}, 409)
            : null,
      );

      await tapVisible(tester, find.text('Add category'));
      await tester.enterText(find.byType(TextField).at(1), 'Books');
      await tapVisible(tester, find.text('Add category').last);

      expect(find.text('Category already exists'), findsOneWidget);
      // the form is still open
      expect(find.text('Add category'), findsNWidgets(3));
    });

    testWidgets('9. Tapping a category should open the edit form with its values.', (tester) async {
      await openCategories(tester);

      await tapVisible(tester, find.text('Furniture'));

      expect(find.text('Edit category'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
      final name = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(name.controller!.text, 'Furniture');
      // deleting categories is not available yet
      expect(find.text('Delete category'), findsNothing);
    });

    testWidgets('10. Editing a category should save the changes.', (tester) async {
      final log = await openCategories(tester);

      await tapVisible(tester, find.text('Furniture'));
      await tester.enterText(find.byType(TextField).at(1), 'Home furniture');
      await tapVisible(tester, find.text('Save changes'));

      final body = log.bodyOf('PUT', '/admin/categories/1');
      expect(body['name'], 'Home furniture');
      expect(body['is_active'], isTrue);
      expect(find.text('Category saved'), findsOneWidget);
    });

    testWidgets('11. The Active switch should deactivate a category.', (tester) async {
      final log = await openCategories(tester);

      await tapVisible(tester, find.text('Furniture'));
      await tapVisible(tester, find.byType(Switch));
      await tapVisible(tester, find.text('Save changes'));

      expect(log.bodyOf('PUT', '/admin/categories/1')['is_active'], isFalse);
    });
  });

  // ---------------------------------------------------------------------
  // /Admin/Locations (ตรวจคำขอที่พักใหม่ + เพิ่มที่พักเอง)
  // ---------------------------------------------------------------------
  group('Admin locations page', () {
    Future<ApiLog> openLocations(WidgetTester tester, {ApiOverride? override}) async {
      final log = setupApp(role: 'admin', override: override);
      useTallScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: AdminLocationsPage()));
      await tester.pumpAndSettle();
      return log;
    }

    testWidgets('1. Location requests that need review should be listed.', (tester) async {
      await openLocations(tester);

      expect(find.byType(AdminLocationsPage), findsOneWidget);
      expect(find.text('Location requests'), findsOneWidget);
      expect(find.text('2 requests need review'), findsOneWidget);
      expect(find.text('Needs attention'), findsOneWidget);
      expect(find.text('2 shown'), findsOneWidget);
      expect(find.text('Sunrise Apartment'), findsOneWidget);
      expect(find.textContaining('Requested by Maya Kim'), findsOneWidget);
      expect(find.text('North Hall'), findsOneWidget);
      expect(find.textContaining('Requested by Noah Lee'), findsOneWidget);
      // one badge for each status
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Reviewing'), findsOneWidget);
      expect(find.text('Add location'), findsOneWidget);
    });

    testWidgets('2. Typing in the search box should filter the requests.', (tester) async {
      await openLocations(tester);

      await tester.enterText(find.byType(TextField), 'north');
      await tester.pumpAndSettle();

      expect(find.text('1 shown'), findsOneWidget);
      expect(find.text('North Hall'), findsOneWidget);
      expect(find.text('Sunrise Apartment'), findsNothing);
    });

    testWidgets('3. The status filter should filter the requests.', (tester) async {
      await openLocations(tester);

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Reviewing'));
      await tester.pumpAndSettle();

      expect(find.text('1 shown'), findsOneWidget);
      expect(find.text('North Hall'), findsOneWidget);
      expect(find.text('Sunrise Apartment'), findsNothing);
    });

    testWidgets('4. With no requests, an empty message should be shown.', (tester) async {
      await openLocations(
        tester,
        override: (request) => request.url.path == '/api/admin/location-requests'
            ? json({'success': true, 'data': <Map<String, dynamic>>[], 'has_more': false})
            : null,
      );

      expect(find.text('No pending requests'), findsOneWidget);
    });

    testWidgets('5. If loading fails, an error should be shown.', (tester) async {
      await openLocations(
        tester,
        override: (request) => request.url.path == '/api/admin/location-requests'
            ? json({'success': false, 'message': 'Database offline'}, 500)
            : null,
      );

      expect(find.text('Database offline'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('6. Tapping a pending request should show its details and actions.', (tester) async {
      await openLocations(tester);

      await tapVisible(tester, find.text('Sunrise Apartment'));

      expect(find.text('Zone'), findsOneWidget);
      expect(find.text('Off-campus dorms'), findsOneWidget);
      expect(find.text('Requested by'), findsOneWidget);
      expect(find.text('Maya Kim'), findsOneWidget);
      expect(find.text('12 Main Street'), findsOneWidget);
      expect(find.text('Many students live here'), findsOneWidget);
      expect(find.text('Approve location'), findsOneWidget);
      expect(find.text('Merge into existing location'), findsOneWidget);
      expect(find.text('Mark as reviewing'), findsOneWidget);
      expect(find.text('Reject request'), findsOneWidget);
    });

    testWidgets('7. A request already being reviewed should not offer "Mark as reviewing".', (tester) async {
      await openLocations(tester);

      await tapVisible(tester, find.text('North Hall'));

      expect(find.text('Approve location'), findsOneWidget);
      expect(find.text('Mark as reviewing'), findsNothing);
    });

    testWidgets('8. Approving a request should add the location.', (tester) async {
      final log = await openLocations(tester);

      await tapVisible(tester, find.text('Sunrise Apartment'));
      await tapVisible(tester, find.text('Approve location'));

      expect(log.bodyOf('PUT', '/admin/location-requests/21/review')['action'], 'approve');
      expect(find.text('Sunrise Apartment approved'), findsOneWidget);
    });

    testWidgets('9. A request should be marked as reviewing.', (tester) async {
      final log = await openLocations(tester);

      await tapVisible(tester, find.text('Sunrise Apartment'));
      await tapVisible(tester, find.text('Mark as reviewing'));

      expect(log.bodyOf('PUT', '/admin/location-requests/21/review')['action'], 'reviewing');
      expect(find.text('Sunrise Apartment marked as reviewing'), findsOneWidget);
    });

    testWidgets('10. A request should be rejected.', (tester) async {
      final log = await openLocations(tester);

      await tapVisible(tester, find.text('Sunrise Apartment'));
      await tapVisible(tester, find.text('Reject request'));

      expect(log.bodyOf('PUT', '/admin/location-requests/21/review')['action'], 'reject');
      expect(find.text('Sunrise Apartment rejected'), findsOneWidget);
    });

    testWidgets('11. A request should be merged into an existing location.', (tester) async {
      final log = await openLocations(tester);

      await tapVisible(tester, find.text('Sunrise Apartment'));
      await tapVisible(tester, find.text('Merge into existing location'));
      // only active locations in the same zone (off-campus) are offered
      expect(find.text('Merge into which location?'), findsOneWidget);
      expect(find.text('Dorm A'), findsNothing);
      await tester.tap(find.text('Test Residence'));
      await tester.pumpAndSettle();

      final body = log.bodyOf('PUT', '/admin/location-requests/21/review');
      expect(body['action'], 'merge');
      expect(body['merge_into_location_id'], 1);
      expect(find.text('Sunrise Apartment merged into Test Residence'), findsOneWidget);
    });

    testWidgets('12. A request that was already handled should show the server error.', (tester) async {
      await openLocations(
        tester,
        override: (request) => request.method == 'PUT' && request.url.path.endsWith('/review')
            ? json({'success': false, 'message': 'Location request is not open'}, 409)
            : null,
      );

      await tapVisible(tester, find.text('Sunrise Apartment'));
      await tapVisible(tester, find.text('Approve location'));

      expect(find.text('Location request is not open'), findsOneWidget);
    });

    testWidgets('13. A new location should be added.', (tester) async {
      final log = await openLocations(tester);

      await tapVisible(tester, find.text('Add location'));
      expect(find.text('Zone'), findsOneWidget);
      // text fields: [0] search box, [1] name
      await tester.enterText(find.byType(TextField).at(1), 'Riverside Residence');
      // the form button is the last "Add location" (after the title and the bottom bar)
      await tapVisible(tester, find.text('Add location').last);

      final body = log.bodyOf('POST', '/admin/locations');
      expect(body['name'], 'Riverside Residence');
      expect(body.containsKey('zone'), isTrue);
      expect(find.text('Location added'), findsOneWidget);
    });

    testWidgets('14. A location without a name should show an error.', (tester) async {
      final log = await openLocations(tester);

      await tapVisible(tester, find.text('Add location'));
      await tapVisible(tester, find.text('Add location').last);

      expect(find.text('Please enter a name'), findsOneWidget);
      expect(log.called('POST', '/admin/locations'), isFalse);
    });

    testWidgets('15. A server error should be shown and the form should stay.', (tester) async {
      await openLocations(
        tester,
        override: (request) => request.method == 'POST' && request.url.path == '/api/admin/locations'
            ? json({'success': false, 'message': 'Location already exists'}, 409)
            : null,
      );

      await tapVisible(tester, find.text('Add location'));
      await tester.enterText(find.byType(TextField).at(1), 'Test Residence');
      await tapVisible(tester, find.text('Add location').last);

      expect(find.text('Location already exists'), findsOneWidget);
      expect(find.text('Add location'), findsNWidgets(3));
    });
  });
}
