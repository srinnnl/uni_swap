// Widget test กลุ่ม 3: ลงขายและจัดการสินค้าของฉัน
// หน้าที่ครอบคลุม: my_items, sell, main_screen (แถบเมนู)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/view/main_screen.dart';
import 'package:uni_swap/view/user/my_items_page.dart';
import 'package:uni_swap/view/user/sell_page.dart';

import 'widget_helpers.dart';

void main() {
  tearDown(() => apiClient.close());

  // ---------------------------------------------------------------------
  // /User/MyItems
  // ---------------------------------------------------------------------
  group('My items page', () {
    Future<ApiLog> openMyItems(
      WidgetTester tester, {
      bool signedIn = false,
      ApiOverride? override,
    }) async {
      final log = setupApp(override: override);
      if (signedIn) await signIn(tester);
      useTallScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: MyItemsPage()));
      await tester.pumpAndSettle();
      return log;
    }

    testWidgets('1. The summary and my listings should be shown.', (tester) async {
      await openMyItems(tester);

      expect(find.byType(MyItemsPage), findsOneWidget);
      expect(find.text('My items'), findsOneWidget);
      // 1 available item
      expect(find.text('1 active items'), findsOneWidget);
      // total views: 12 + 3 + 0 + 40
      expect(find.text('55'), findsOneWidget);
      expect(find.text('Sell a new item'), findsOneWidget);
      expect(find.text('Recent items'), findsOneWidget);
      // every listing with its status
      expect(find.text('Wooden Chair'), findsOneWidget);
      expect(find.text('Old Laptop'), findsOneWidget);
      expect(find.text('Blue Bike'), findsOneWidget);
      expect(find.text('Sold Book'), findsOneWidget);
      expect(find.text('Pending review'), findsOneWidget);
      expect(find.text('Action required'), findsOneWidget);
      expect(find.text('250.0 THB · Test Residence'), findsOneWidget);
      // the note from the admin
      expect(find.text('Please add clearer photos'), findsOneWidget);
    });

    testWidgets('2. Each status should offer the right actions.', (tester) async {
      await openMyItems(tester);

      // available + pending review can be edited, a change request must be fixed
      expect(find.text('Edit item'), findsNWidgets(2));
      expect(find.text('Fix item'), findsOneWidget);
      // only listings that are not live yet can be deleted
      expect(find.text('Delete listing'), findsNWidgets(2));
      // only the available listing can be taken off the marketplace
      expect(find.text('Take off marketplace'), findsOneWidget);
    });

    testWidgets('3. With no listings, an empty message should be shown.', (tester) async {
      await openMyItems(
        tester,
        override: (request) => request.url.path == '/api/my/listings'
            ? json({'success': true, 'data': <Map<String, dynamic>>[], 'has_more': false})
            : null,
      );

      expect(find.text('You have not listed any items yet.'), findsOneWidget);
      expect(find.text('0 active items'), findsOneWidget);
    });

    testWidgets('4. If loading fails, an error should be shown.', (tester) async {
      await openMyItems(
        tester,
        override: (request) => request.url.path == '/api/my/listings'
            ? json({'success': false, 'message': 'Database offline'}, 500)
            : null,
      );

      expect(find.text('Database offline'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('5. A listing at another place than my residence should show a warning.', (tester) async {
      await openMyItems(
        tester,
        signedIn: true,
        override: (request) => request.url.path == '/api/my/listings'
            ? json({
                'success': true,
                'data': [
                  sampleProduct(
                    id: 201,
                    title: 'Wooden Chair',
                    locationId: 2,
                    locationName: 'Dorm A',
                    zone: 'on_campus',
                  ),
                ],
                'has_more': false,
              })
            : null,
      );

      expect(find.textContaining('Pickup differs from your current residence'), findsOneWidget);
    });

    testWidgets('6. Taking an item off the marketplace should ask first.', (tester) async {
      final log = await openMyItems(tester);

      await tapVisible(tester, find.text('Take off marketplace'));
      expect(find.text('Take listing off the marketplace?'), findsOneWidget);

      await tester.tap(inDialog(find.text('Take off marketplace')));
      await tester.pumpAndSettle();

      expect(log.called('PUT', '/products/201/hide'), isTrue);
      expect(find.text('Listing taken off the marketplace.'), findsOneWidget);
    });

    testWidgets('7. Cancelling the dialog should keep the listing.', (tester) async {
      final log = await openMyItems(tester);

      await tapVisible(tester, find.text('Take off marketplace'));
      await tester.tap(inDialog(find.text('Cancel')));
      await tester.pumpAndSettle();

      expect(find.text('Take listing off the marketplace?'), findsNothing);
      expect(log.called('PUT', '/products/201/hide'), isFalse);
    });

    testWidgets('8. Deleting a listing under review should ask first.', (tester) async {
      final log = await openMyItems(tester);

      // the first "Delete listing" belongs to Old Laptop (pending review)
      await tapVisible(tester, find.text('Delete listing').first);
      expect(find.text('Remove listing?'), findsOneWidget);

      await tester.tap(inDialog(find.text('Remove listing')));
      await tester.pumpAndSettle();

      expect(log.called('DELETE', '/products/202'), isTrue);
      expect(find.text('Listing deleted.'), findsOneWidget);
    });

    testWidgets('9. A listing with order history should be hidden, not deleted.', (tester) async {
      await openMyItems(
        tester,
        override: (request) => request.method == 'DELETE'
            ? json({'success': true, 'status': 'hidden'})
            : null,
      );

      await tapVisible(tester, find.text('Delete listing').first);
      await tester.tap(inDialog(find.text('Remove listing')));
      await tester.pumpAndSettle();

      expect(find.text('Listing hidden to preserve its order history.'), findsOneWidget);
    });

    testWidgets('10. "Sell a new item" should open the sell page.', (tester) async {
      await openMyItems(tester);

      await tapVisible(tester, find.text('Sell a new item'));

      expect(find.byType(SellPage), findsOneWidget);
      expect(find.text('Sell an item'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------
  // /User/Sell (เปิดจากหน้า My items เหมือนใช้งานจริง เพราะหน้านี้ pop ค่าผลลัพธ์กลับ)
  // ---------------------------------------------------------------------
  group('Sell page', () {
    Future<ApiLog> openSell(WidgetTester tester, {ApiOverride? override}) async {
      final log = setupApp(override: override);
      await signIn(tester);
      useTallScreen(tester, height: 2600);
      await tester.pumpWidget(const MaterialApp(home: MyItemsPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sell a new item'));
      await tester.pumpAndSettle();
      return log;
    }

    testWidgets('1. At first, the empty sell form should be shown.', (tester) async {
      await openSell(tester);

      expect(find.byType(SellPage), findsOneWidget);
      expect(find.text('Sell an item'), findsOneWidget);
      expect(find.text('Takes less than 2 minutes'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Add up to 6 photos'), findsOneWidget);
      expect(find.text('Item title'), findsOneWidget);
      expect(find.text('Condition'), findsOneWidget);
      expect(find.text('Move-out deadline'), findsOneWidget);
      expect(find.text('Select a date'), findsOneWidget);
      // 4 text fields: title, price, pickup detail, description
      expect(find.byType(TextFormField), findsNWidgets(4));
      // the first category and my residence are chosen by default
      expect(find.text('Furniture'), findsOneWidget);
      expect(find.text('Off-campus · Test Residence'), findsOneWidget);
      expect(find.text('Pickup is set to the residence saved in your profile.'), findsOneWidget);
      // condition chips
      for (final label in ['New', 'Like new', 'Good', 'Fair']) {
        expect(find.widgetWithText(ChoiceChip, label), findsOneWidget);
      }
      expect(find.widgetWithText(FilledButton, 'Publish item'), findsOneWidget);
    });

    testWidgets('2. Publishing an empty form should show errors.', (tester) async {
      final log = await openSell(tester);

      await tapVisible(tester, find.widgetWithText(FilledButton, 'Publish item'));

      expect(find.text('Please enter a title'), findsOneWidget);
      expect(find.text('Please enter a price'), findsOneWidget);
      expect(find.text('Please fix the errors'), findsOneWidget);
      expect(log.called('POST', '/products'), isFalse);
    });

    testWidgets('3. A free item should set the price to 0.', (tester) async {
      await openSell(tester);

      await tapVisible(tester, find.byType(Switch));

      final price = tester.widget<TextFormField>(find.byType(TextFormField).at(1));
      expect(price.controller!.text, '0');
      // the price cannot be edited while the item is free
      expect(price.enabled, isFalse);
    });

    testWidgets('4. Choosing a category should change the category.', (tester) async {
      await openSell(tester);

      await tapVisible(tester, find.text('Furniture'));
      await tester.tap(find.text('Books'));
      await tester.pumpAndSettle();

      expect(find.text('Books'), findsOneWidget);
      expect(find.text('Furniture'), findsNothing);
    });

    testWidgets('5. Choosing a condition should select its chip.', (tester) async {
      await openSell(tester);

      await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Good'));

      final chip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Good'));
      expect(chip.selected, isTrue);
      final other = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Fair'));
      expect(other.selected, isFalse);
    });

    testWidgets('6. A move-out deadline should mark the item as urgent.', (tester) async {
      await openSell(tester);

      await tapVisible(tester, find.text('Select a date'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Select a date'), findsNothing);
      expect(find.text('Urgent'), findsOneWidget);

      // removing the deadline removes the badge
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Select a date'), findsOneWidget);
      expect(find.text('Urgent'), findsNothing);
    });

    testWidgets('7. A correct form should be published for review.', (tester) async {
      final log = await openSell(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'Desk Lamp');
      await tester.enterText(find.byType(TextFormField).at(1), '80');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Publish item'));

      // the listing was sent with my residence as the pickup place
      final body = log.bodyOf('POST', '/products');
      expect(body['title'], 'Desk Lamp');
      expect(body['price'], 80);
      expect(body['category_id'], 1);
      expect(body['location_id'], 1);
      expect(body['zone'], 'off_campus');
      expect(body['urgency_level'], 'normal');
      // back on My items with a confirmation message
      expect(find.byType(SellPage), findsNothing);
      expect(find.text('My items'), findsOneWidget);
      expect(find.text('Listing submitted for admin review.'), findsOneWidget);
    });

    testWidgets('8. A server error should be shown and the form should stay.', (tester) async {
      await openSell(
        tester,
        override: (request) => request.method == 'POST' && request.url.path == '/api/products'
            ? json({'success': false, 'message': 'Title contains prohibited words'}, 400)
            : null,
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Desk Lamp');
      await tester.enterText(find.byType(TextFormField).at(1), '80');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Publish item'));

      expect(find.text('Title contains prohibited words'), findsOneWidget);
      expect(find.byType(SellPage), findsOneWidget);
    });

    testWidgets('9. Leaving a changed form should ask to discard it.', (tester) async {
      await openSell(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'Desk Lamp');
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Discard this listing?'), findsOneWidget);
      expect(find.text('Your listing has not been submitted.'), findsOneWidget);

      // keep editing: the dialog closes and the form stays
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('Discard this listing?'), findsNothing);
      expect(find.byType(SellPage), findsOneWidget);
    });

    testWidgets('10. Discarding the form should go back to My items.', (tester) async {
      final log = await openSell(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'Desk Lamp');
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.byType(SellPage), findsNothing);
      expect(find.text('My items'), findsOneWidget);
      expect(log.called('POST', '/products'), isFalse);
    });

    testWidgets('11. Without an approved residence, the form cannot be published.', (tester) async {
      await openSell(
        tester,
        override: (request) => request.method == 'GET' && request.url.path == '/api/profile'
            ? json({
                'success': true,
                'data': {...sampleProfile(), 'residence_location_id': null},
              })
            : null,
      );

      expect(
        find.text('Set an approved residence in your profile before listing an item.'),
        findsOneWidget,
      );
      expect(find.text('Retry loading options'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Publish item'));
      expect(button.onPressed, isNull);
    });

    testWidgets('12. Editing an item should fill the form and resubmit it.', (tester) async {
      final log = setupApp();
      await signIn(tester);
      useTallScreen(tester, height: 2600);
      await tester.pumpWidget(const MaterialApp(home: MyItemsPage()));
      await tester.pumpAndSettle();

      // the first "Edit item" belongs to Wooden Chair
      await tapVisible(tester, find.text('Edit item').first);

      expect(find.text('Edit item'), findsOneWidget);
      expect(find.text('Saving sends it for review again'), findsOneWidget);
      final title = tester.widget<TextFormField>(find.byType(TextFormField).at(0));
      expect(title.controller!.text, 'Wooden Chair');
      final price = tester.widget<TextFormField>(find.byType(TextFormField).at(1));
      expect(price.controller!.text, '250');

      await tapVisible(tester, find.widgetWithText(FilledButton, 'Save and resubmit'));

      expect(log.called('PUT', '/products/201'), isTrue);
      expect(find.byType(SellPage), findsNothing);
      expect(find.text('Changes submitted for admin review.'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------
  // /User/MainScreen (แถบเมนูด้านล่าง)
  // ---------------------------------------------------------------------
  group('Main screen', () {
    Future<void> openMain(WidgetTester tester) async {
      setupApp();
      await signIn(tester);
      allowPlatformChannel();
      useTallScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: MainScreen()));
      await tester.pumpAndSettle();
    }

    testWidgets('1. At first, the home tab and the 5 menus should be shown.', (tester) async {
      await openMain(tester);

      expect(find.byType(MainScreen), findsOneWidget);
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Search'), findsWidgets);
      expect(find.text('Sell'), findsWidgets);
      expect(find.text('Orders'), findsWidgets);
      expect(find.text('Profile'), findsWidgets);
      // the home tab shows the items at my residence
      expect(find.text('Find something nearby.'), findsOneWidget);
    });

    testWidgets('2. The Search menu should show the search page.', (tester) async {
      await openMain(tester);

      // the menu label is the last match (it sits at the bottom of the screen)
      await tester.tap(find.text('Search').last);
      await tester.pumpAndSettle();

      expect(find.text('Price range'), findsOneWidget);
      expect(find.text('Find something nearby.'), findsNothing);
    });

    testWidgets('3. The Sell menu should show my items.', (tester) async {
      await openMain(tester);

      // the menu label is the last match (it sits at the bottom of the screen)
      await tester.tap(find.text('Sell').last);
      await tester.pumpAndSettle();

      expect(find.text('My items'), findsOneWidget);
      expect(find.text('Sell a new item'), findsOneWidget);
    });

    testWidgets('4. The Orders menu should load my orders.', (tester) async {
      await openMain(tester);

      // the menu label is the last match (it sits at the bottom of the screen)
      await tester.tap(find.text('Orders').last);
      await tester.pumpAndSettle();

      expect(find.text('My orders'), findsOneWidget);
      expect(find.text('Pay 450 THB'), findsOneWidget);
    });

    testWidgets('5. The Profile menu should show my profile.', (tester) async {
      await openMain(tester);

      // the menu label is the last match (it sits at the bottom of the screen)
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();

      expect(find.text('@test_member'), findsOneWidget);
      expect(find.text('My account'), findsOneWidget);
    });
  });
}
