// Widget test กลุ่ม 2: ดูและค้นหาสินค้า
// หน้าที่ครอบคลุม: home, search, product_detail, seller_profile
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/model/product.dart';
import 'package:uni_swap/view/user/arrange_meetup_page.dart';
import 'package:uni_swap/view/user/home_page.dart';
import 'package:uni_swap/view/user/product_detail_page.dart';
import 'package:uni_swap/view/user/search_page.dart';
import 'package:uni_swap/view/user/seller_profile_page.dart';

import 'widget_helpers.dart';

void main() {
  tearDown(() => apiClient.close());

  // ---------------------------------------------------------------------
  // /User/Home
  // ---------------------------------------------------------------------
  group('Home page', () {
    // helper: เปิดหน้า Home (ล็อกอินเป็นสมาชิกที่อยู่ Test Residence เว้นแต่ signedIn = false)
    Future<ApiLog> openHome(
      WidgetTester tester, {
      bool signedIn = true,
      ApiOverride? override,
    }) async {
      final log = setupApp(override: override);
      if (signedIn) await signIn(tester);
      useTallScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();
      return log;
    }

    testWidgets('1. At first, items at my own residence should be shown.', (tester) async {
      await openHome(tester);

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Find something nearby.'), findsOneWidget);
      expect(find.text('Off-campus dorms · Test Residence'), findsOneWidget);
      // 3 tabs
      expect(find.text('Same place'), findsOneWidget);
      expect(find.text('Same zone'), findsOneWidget);
      expect(find.text('Explore all'), findsOneWidget);
      // the first tab shows only items at Test Residence
      expect(find.text('Items in Test Residence'), findsOneWidget);
      expect(find.text('Study Desk'), findsOneWidget);
      expect(find.text('Mini Fridge'), findsOneWidget);
      expect(find.text('Calculus Textbook'), findsNothing);
    });

    testWidgets('2. "Same zone" should show items in my zone only.', (tester) async {
      await openHome(tester);

      await tester.tap(find.text('Same zone'));
      await tester.pumpAndSettle();

      expect(find.text('Items in Off-campus dorms'), findsOneWidget);
      expect(find.text('In your zone'), findsOneWidget);
      expect(find.text('Study Desk'), findsOneWidget);
      // Calculus Textbook is in an on-campus dorm
      expect(find.text('Calculus Textbook'), findsNothing);
    });

    testWidgets('3. "Explore all" should show every item with the urgent badge.', (tester) async {
      await openHome(tester);

      await tester.tap(find.text('Explore all'));
      await tester.pumpAndSettle();

      expect(find.text('Items across campus'), findsOneWidget);
      expect(find.text('Study Desk'), findsOneWidget);
      expect(find.text('Calculus Textbook'), findsOneWidget);
      expect(find.text('Mini Fridge'), findsOneWidget);
      // only Calculus Textbook is urgent
      expect(find.text('Urgent'), findsOneWidget);
    });

    testWidgets('4. Without a saved residence, all items should be shown.', (tester) async {
      // not signed in: no residence
      await openHome(tester, signedIn: false);

      expect(find.text('Set your residence in Profile'), findsOneWidget);
      expect(find.text('Items across campus'), findsOneWidget);
      expect(find.text('Calculus Textbook'), findsOneWidget);
    });

    testWidgets('5. With no items, an empty message should be shown.', (tester) async {
      await openHome(
        tester,
        override: (request) => request.url.path == '/api/products'
            ? json({'success': true, 'data': <Map<String, dynamic>>[], 'has_more': false})
            : null,
      );

      expect(find.text('Nothing here yet'), findsOneWidget);
    });

    testWidgets('6. If loading fails, an error should be shown and retry should work.', (tester) async {
      var failed = false;
      // the first request fails, the retry succeeds
      await openHome(
        tester,
        override: (request) {
          if (request.url.path == '/api/products' && !failed) {
            failed = true;
            return json({'success': false, 'message': 'Database offline'}, 500);
          }
          return null;
        },
      );

      expect(find.text('Could not load products'), findsOneWidget);
      expect(find.text('Database offline'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Could not load products'), findsNothing);
      expect(find.text('Study Desk'), findsOneWidget);
    });

    testWidgets('7. Tapping an item should open its detail page.', (tester) async {
      await openHome(tester);

      await tester.tap(find.text('Study Desk'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductDetailPage), findsOneWidget);
      expect(find.text('Buy now'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------
  // /User/Search
  // ---------------------------------------------------------------------
  group('Search page', () {
    Future<ApiLog> openSearch(WidgetTester tester, {ApiOverride? override}) async {
      final log = setupApp(override: override);
      useTallScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: SearchPage()));
      await tester.pumpAndSettle();
      return log;
    }

    testWidgets('1. At first, all items and the filters should be shown.', (tester) async {
      await openSearch(tester);

      expect(find.byType(SearchPage), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      // 1 text field: the search box
      expect(find.byType(TextField), findsOneWidget);
      // category chips come from the server
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Furniture'), findsOneWidget);
      expect(find.text('Books'), findsOneWidget);
      expect(find.text('Appliances'), findsOneWidget);
      // filters and sorting
      expect(find.text('Price range'), findsOneWidget);
      expect(find.text('Any price'), findsOneWidget);
      expect(find.text('All campus'), findsOneWidget);
      expect(find.text('Price: low to high'), findsOneWidget);
      expect(find.text('3 items'), findsOneWidget);
    });

    testWidgets('2. Typing a keyword should filter the items.', (tester) async {
      await openSearch(tester);

      await tester.enterText(find.byType(TextField), 'desk');
      await tester.pumpAndSettle();

      expect(find.text('1 item'), findsOneWidget);
      expect(find.text('Study Desk'), findsOneWidget);
      expect(find.text('Mini Fridge'), findsNothing);

      // "Clear all" brings every item back
      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();
      expect(find.text('3 items'), findsOneWidget);
    });

    testWidgets('3. A keyword with no match should show an empty message.', (tester) async {
      await openSearch(tester);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('No items found'), findsOneWidget);
      expect(find.text('Try a different keyword or loosen your filters.'), findsOneWidget);
      expect(find.text('0 items'), findsOneWidget);
    });

    testWidgets('4. Choosing a category should filter the items.', (tester) async {
      await openSearch(tester);

      await tester.tap(find.text('Books'));
      await tester.pumpAndSettle();

      expect(find.text('1 item'), findsOneWidget);
      expect(find.text('Calculus Textbook'), findsOneWidget);
      expect(find.text('Study Desk'), findsNothing);
    });

    testWidgets('5. The price range filter should filter the items.', (tester) async {
      await openSearch(tester);

      await tester.tap(find.text('Price range'));
      await tester.pumpAndSettle();
      // fields in the sheet: [0] search box, [1] min, [2] max
      await tester.enterText(find.byType(TextField).at(2), '200');
      await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
      await tester.pumpAndSettle();

      // only Calculus Textbook (120 THB) is not above 200 THB
      expect(find.text('1 item'), findsOneWidget);
      expect(find.text('Calculus Textbook'), findsOneWidget);
      expect(find.text('Any price'), findsNothing);
    });

    testWidgets('6. The location filter should filter the items.', (tester) async {
      await openSearch(tester);

      await tester.tap(find.text('All campus'));
      await tester.pumpAndSettle();
      // the sheet starts at on-campus dorms (the item card also shows "Dorm A")
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Dorm A'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
      await tester.pumpAndSettle();

      expect(find.text('1 item'), findsOneWidget);
      expect(find.text('Calculus Textbook'), findsOneWidget);
      expect(find.text('Study Desk'), findsNothing);
    });

    testWidgets('7. Sorting by price should change the order of the items.', (tester) async {
      await openSearch(tester);

      // low to high: Calculus (120) comes before Mini Fridge (1500)
      expect(
        tester.getTopLeft(find.text('Calculus Textbook')).dy,
        lessThan(tester.getTopLeft(find.text('Mini Fridge')).dy),
      );

      await tester.tap(find.text('Price: low to high'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Price: high to low'));
      await tester.pumpAndSettle();

      // high to low: Mini Fridge comes before Calculus
      expect(find.text('Price: high to low'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Mini Fridge')).dy,
        lessThan(tester.getTopLeft(find.text('Calculus Textbook')).dy),
      );
    });

    testWidgets('8. If loading fails, an error should be shown and retry should work.', (tester) async {
      var failed = false;
      await openSearch(
        tester,
        override: (request) {
          if (request.url.path == '/api/products' && !failed) {
            failed = true;
            return json({'success': false, 'message': 'Database offline'}, 500);
          }
          return null;
        },
      );

      expect(find.text('Could not load products'), findsOneWidget);
      expect(find.text('Database offline'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Could not load products'), findsNothing);
      expect(find.text('3 items'), findsOneWidget);
    });

    testWidgets('9. Tapping an item should open its detail page.', (tester) async {
      await openSearch(tester);

      await tester.tap(find.text('Mini Fridge'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductDetailPage), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------
  // /User/ProductDetail
  // ---------------------------------------------------------------------
  group('Product detail page', () {
    // helper: เปิดหน้ารายละเอียดของสินค้า [item] (JSON) โดยให้ server ปลอมตอบข้อมูลเดิมกลับ
    Future<ApiLog> openDetail(
      WidgetTester tester, {
      Map<String, dynamic>? item,
      ApiOverride? override,
    }) async {
      final data = item ?? sampleProduct();
      final log = setupApp(
        override: (request) {
          if (request.method == 'GET' && request.url.path == '/api/products/${data['product_id']}') {
            return json({'success': true, 'data': data});
          }
          return override?.call(request);
        },
      );
      await signIn(tester);
      useTallScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailPage(product: ProductDetail.fromProduct(Product.fromJson(data))),
        ),
      );
      await tester.pumpAndSettle();
      return log;
    }

    testWidgets('1. The details of the item should be shown.', (tester) async {
      await openDetail(tester);

      expect(find.byType(ProductDetailPage), findsOneWidget);
      expect(find.text('Study Desk'), findsOneWidget);
      // the price is shown in the content and in the bottom bar
      expect(find.text('450 THB'), findsNWidgets(2));
      expect(find.text('Furniture'), findsOneWidget);
      expect(find.text('Condition: GOOD'), findsOneWidget);
      expect(find.text('About this item'), findsOneWidget);
      expect(find.text('Sturdy and ready for a new home.'), findsOneWidget);
      expect(find.text('Pickup detail'), findsOneWidget);
      expect(find.text('Near the lobby'), findsOneWidget);
      // the seller
      expect(find.text('Sam Seller'), findsOneWidget);
      expect(find.text('18 sales'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Buy now'), findsOneWidget);
    });

    testWidgets('2. An urgent item should show the urgent badge.', (tester) async {
      await openDetail(
        tester,
        item: sampleProduct(urgency: 'urgent', deadline: isoIn(const Duration(days: 3))),
      );

      expect(find.textContaining('Urgent'), findsOneWidget);
    });

    // สินค้าที่ซื้อไม่ได้ ปุ่มต้องบอกสถานะและกดไม่ได้
    for (final (status, label) in [
      ('reserved', 'Reserved'),
      ('sold', 'Sold'),
      ('hidden', 'Unavailable'),
    ]) {
      testWidgets('3. A $status item should not be bought ($label).', (tester) async {
        await openDetail(tester, item: sampleProduct(status: status));

        final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));
        expect(button.onPressed, isNull);
      });
    }

    testWidgets('4. My own item should not be bought.', (tester) async {
      await openDetail(tester, item: sampleProduct(isOwn: true));

      final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Your item'));
      expect(button.onPressed, isNull);
    });

    testWidgets('5. "Buy now" should open the meet-up page.', (tester) async {
      await openDetail(tester);

      await tapVisible(tester, find.widgetWithText(FilledButton, 'Buy now'));

      expect(find.byType(ArrangeMeetupPage), findsOneWidget);
      expect(find.text('Arrange meet-up'), findsOneWidget);
    });

    testWidgets('6. Going back from the meet-up page should not place an order.', (tester) async {
      final log = await openDetail(tester);

      await tapVisible(tester, find.widgetWithText(FilledButton, 'Buy now'));
      await tester.tap(find.byIcon(Icons.arrow_back).last);
      await tester.pumpAndSettle();

      expect(find.byType(ArrangeMeetupPage), findsNothing);
      expect(log.called('POST', '/orders'), isFalse);
      expect(find.text('Buy now'), findsOneWidget);
    });

    testWidgets('7. Confirming the meet-up should place the order.', (tester) async {
      final log = await openDetail(tester);

      await tapVisible(tester, find.widgetWithText(FilledButton, 'Buy now'));
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Confirm meet-up'));

      // the order was sent for this item and place
      final body = log.bodyOf('POST', '/orders');
      expect(body['product_id'], 101);
      expect(body['meetup_location'], 'Test Residence');
      // the page shows the result
      expect(find.text('Order #US-501 placed with Sam Seller'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Order placed'));
      expect(button.onPressed, isNull);
    });

    testWidgets('8. If the order fails, the error should be shown.', (tester) async {
      await openDetail(
        tester,
        override: (request) => request.method == 'POST' && request.url.path == '/api/orders'
            ? json({'success': false, 'message': 'This item was just reserved'}, 409)
            : null,
      );

      await tapVisible(tester, find.widgetWithText(FilledButton, 'Buy now'));
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Confirm meet-up'));

      expect(find.text('This item was just reserved'), findsOneWidget);
      // the item can still be bought
      expect(find.widgetWithText(FilledButton, 'Buy now'), findsOneWidget);
    });

    testWidgets('9. Tapping the seller should open the seller profile.', (tester) async {
      await openDetail(tester);

      await tapVisible(tester, find.text('Sam Seller'));

      expect(find.byType(SellerProfilePage), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------
  // /User/SellerProfile
  // ---------------------------------------------------------------------
  group('Seller profile page', () {
    Future<ApiLog> openSeller(WidgetTester tester, {ApiOverride? override}) async {
      final log = setupApp(override: override);
      useTallScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: SellerProfilePage(sellerId: 7)));
      await tester.pumpAndSettle();
      return log;
    }

    testWidgets('1. The seller and the active items should be shown.', (tester) async {
      final log = await openSeller(tester);

      expect(find.byType(SellerProfilePage), findsOneWidget);
      expect(log.called('GET', '/sellers/7'), isTrue);
      expect(find.text('Seller'), findsOneWidget);
      expect(find.text('Sam Seller'), findsOneWidget);
      expect(find.textContaining('Member since Sep 2025'), findsOneWidget);
      expect(find.text('4 completed sales'), findsOneWidget);
      expect(find.text('Items'), findsOneWidget);
      expect(find.text('Study Desk'), findsOneWidget);
      expect(find.text('Mini Fridge'), findsOneWidget);
      // no more pages
      expect(find.text('Load more'), findsNothing);
    });

    testWidgets('2. A seller with no items should show an empty message.', (tester) async {
      await openSeller(
        tester,
        override: (request) => request.url.path == '/api/sellers/7'
            ? json({
                'success': true,
                'data': {...sampleSeller(), 'items': <Map<String, dynamic>>[]},
                'has_more': false,
              })
            : null,
      );

      expect(find.text('Sam Seller'), findsOneWidget);
      expect(find.text('No active items'), findsOneWidget);
    });

    testWidgets('3. "Load more" should add the next page of items.', (tester) async {
      await openSeller(
        tester,
        override: (request) {
          if (request.url.path != '/api/sellers/7') return null;
          final secondPage = request.url.queryParameters['page'] == '2';
          return json({
            'success': true,
            'data': {
              ...sampleSeller(),
              'items': [
                secondPage
                    ? sampleProduct(id: 104, title: 'Desk Lamp', price: 80)
                    : sampleProduct(),
              ],
            },
            'has_more': !secondPage,
          });
        },
      );

      expect(find.text('Study Desk'), findsOneWidget);
      expect(find.text('Desk Lamp'), findsNothing);

      await tapVisible(tester, find.text('Load more'));

      expect(find.text('Study Desk'), findsOneWidget);
      expect(find.text('Desk Lamp'), findsOneWidget);
      // it was the last page
      expect(find.text('Load more'), findsNothing);
    });

    testWidgets('4. If the seller cannot be found, an error should be shown.', (tester) async {
      await openSeller(
        tester,
        override: (request) => request.url.path == '/api/sellers/7'
            ? json({'success': false, 'message': 'Seller not found'}, 404)
            : null,
      );

      expect(find.text('Seller not found'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
