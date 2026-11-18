// Widget test กลุ่ม 4: สั่งซื้อและจ่ายเงิน
// หน้าที่ครอบคลุม: orders, order_details, payment, arrange_meetup
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/model/order_status.dart';
import 'package:uni_swap/view/user/arrange_meetup_page.dart';
import 'package:uni_swap/view/user/order_details_page.dart';
import 'package:uni_swap/view/user/orders_page.dart';
import 'package:uni_swap/view/user/payment_page.dart';

import 'widget_helpers.dart';

void main() {
  tearDown(() => apiClient.close());

  // ---------------------------------------------------------------------
  // /User/Orders
  // ---------------------------------------------------------------------
  group('Orders page', () {
    Future<ApiLog> openOrders(WidgetTester tester, {ApiOverride? override}) async {
      final log = setupApp(override: override);
      useTallScreen(tester);
      // isActive: true = the orders tab is selected, so the orders are loaded
      await tester.pumpWidget(const MaterialApp(home: OrdersPage(isActive: true)));
      await tester.pumpAndSettle();
      return log;
    }

    testWidgets('1. At first, my buying orders should be shown.', (tester) async {
      await openOrders(tester);

      expect(find.byType(OrdersPage), findsOneWidget);
      expect(find.text('My orders'), findsOneWidget);
      expect(find.text('Buying'), findsOneWidget);
      expect(find.text('Selling'), findsOneWidget);
      // the active order waiting for my payment
      expect(find.text('Study Desk'), findsOneWidget);
      expect(find.text('Awaiting payment'), findsOneWidget);
      expect(find.text('450 THB · Seller: Sam Seller'), findsOneWidget);
      expect(find.textContaining('Pay before'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Pay 450 THB'), findsOneWidget);
      // the finished order is listed under past orders
      expect(find.text('Past orders'), findsOneWidget);
      expect(find.text('Mini Fridge'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      // selling orders are on the other tab
      expect(find.text('Calculus Textbook'), findsNothing);
    });

    testWidgets('2. The Selling tab should show my selling orders.', (tester) async {
      await openOrders(tester);

      await tester.tap(find.text('Selling'));
      await tester.pumpAndSettle();

      expect(find.text('Calculus Textbook'), findsOneWidget);
      expect(find.text('Ready to meet'), findsOneWidget);
      expect(find.text('120 THB · Buyer: Bea Buyer'), findsOneWidget);
      expect(find.textContaining('Meet: Dorm A'), findsOneWidget);
      expect(find.text('Paid · waiting for buyer to confirm receipt'), findsOneWidget);
      expect(find.text('Study Desk'), findsNothing);
    });

    testWidgets('3. With no orders, an empty message should be shown.', (tester) async {
      await openOrders(
        tester,
        override: (request) => request.method == 'GET' && request.url.path == '/api/orders'
            ? json({'success': true, 'data': <Map<String, dynamic>>[], 'has_more': false})
            : null,
      );

      expect(find.text('No orders yet'), findsOneWidget);
    });

    testWidgets('4. If loading fails, an error should be shown.', (tester) async {
      await openOrders(
        tester,
        override: (request) => request.method == 'GET' && request.url.path == '/api/orders'
            ? json({'success': false, 'message': 'Database offline'}, 500)
            : null,
      );

      expect(find.text('Database offline'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('5. Invalid order data from the server should be rejected.', (tester) async {
      await openOrders(
        tester,
        override: (request) => request.method == 'GET' && request.url.path == '/api/orders'
            ? json({
                'success': true,
                'data': [
                  {...sampleOrder(), 'perspective': null},
                ],
                'has_more': false,
              })
            : null,
      );

      expect(find.text('The server returned invalid order data.'), findsOneWidget);
    });

    testWidgets('6. Tapping an order should open its details.', (tester) async {
      await openOrders(tester);

      await tester.tap(find.text('Study Desk'));
      await tester.pumpAndSettle();

      expect(find.byType(OrderDetailsPage), findsOneWidget);
      expect(find.text('Order details'), findsOneWidget);
    });

    testWidgets('7. The Pay button should open the payment page.', (tester) async {
      await openOrders(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Pay 450 THB'));
      await tester.pumpAndSettle();

      expect(find.byType(PaymentPage), findsOneWidget);
      expect(find.text('Simulated payment'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------
  // /User/OrderDetails
  // ---------------------------------------------------------------------
  group('Order details page', () {
    // helper: สร้างหน้ารายละเอียดออเดอร์ (ค่าเริ่มต้น = ผู้ซื้อ รอชำระเงิน 450 THB)
    Widget detailsApp({
      bool isBuying = true,
      OrderStatus status = OrderStatus.pendingPayment,
      double price = 450,
      DateTime? deadline,
      DateTime? meetupAt,
    }) {
      return MaterialApp(
        home: OrderDetailsPage(
          orderId: 401,
          title: 'Study Desk',
          price: price,
          totalAmount: price,
          person: isBuying ? 'Sam Seller' : 'Bea Buyer',
          isBuying: isBuying,
          status: status,
          createdLabel: 'Today, 1:20 PM',
          meetupPlace: 'Test Residence',
          meetupAt: meetupAt,
          paymentDeadline: deadline,
          productLocation: 'Test Residence',
          pickupDetail: 'Near the lobby',
          commissionRate: 5,
          commissionAmount: price * 0.05,
          sellerPayout: price * 0.95,
        ),
      );
    }

    testWidgets('1. The buyer should see a waiting-for-payment order.', (tester) async {
      setupApp();
      useTallScreen(tester);
      await tester.pumpWidget(detailsApp());
      await tester.pumpAndSettle();

      expect(find.byType(OrderDetailsPage), findsOneWidget);
      expect(find.text('Order details'), findsOneWidget);
      expect(find.text('Study Desk'), findsOneWidget);
      expect(find.text('450 THB · Seller: Sam Seller'), findsOneWidget);
      expect(find.text('Awaiting payment'), findsWidgets);
      // the order status steps
      expect(find.text('Order status'), findsOneWidget);
      expect(find.text('Order placed'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Pay 450 THB'), findsOneWidget);
    });

    testWidgets('2. A free item should be confirmed instead of paid.', (tester) async {
      setupApp();
      useTallScreen(tester);
      await tester.pumpWidget(detailsApp(price: 0));
      await tester.pumpAndSettle();

      expect(find.text('Confirm free order'), findsOneWidget);
      expect(find.textContaining('Pay '), findsNothing);
    });

    testWidgets('3. The seller should not have a main action.', (tester) async {
      setupApp();
      useTallScreen(tester);
      await tester.pumpWidget(detailsApp(isBuying: false, status: OrderStatus.paid));
      await tester.pumpAndSettle();

      expect(find.text('450 THB · Buyer: Bea Buyer'), findsOneWidget);
      // only the buyer confirms the receipt
      expect(find.text('Confirm received'), findsNothing);
      expect(find.text('Pay 450 THB'), findsNothing);
    });

    testWidgets('4. An order whose payment time ran out should be expired.', (tester) async {
      setupApp();
      useTallScreen(tester);
      await tester.pumpWidget(
        detailsApp(deadline: DateTime.now().subtract(const Duration(minutes: 1))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Expired'), findsOneWidget);
      expect(find.text('Payment time ran out'), findsWidgets);
      // it cannot be paid any more
      expect(find.text('Pay 450 THB'), findsNothing);
    });

    testWidgets('5. Paying should record the payment and allow confirming receipt.', (tester) async {
      final log = setupApp();
      useTallScreen(tester);
      await tester.pumpWidget(detailsApp());
      await tester.pumpAndSettle();

      // details -> payment page
      await tapVisible(tester, find.text('Pay 450 THB'));
      expect(find.byType(PaymentPage), findsOneWidget);

      // payment page -> confirm dialog
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Simulate payment'));
      expect(find.text('Simulate payment?'), findsOneWidget);
      await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Simulate payment')));
      await tester.pumpAndSettle();

      // back on the details page: paid, so the buyer can confirm receipt
      expect(log.called('POST', '/orders/401/pay'), isTrue);
      expect(find.byType(PaymentPage), findsNothing);
      expect(find.text('Demo payment recorded; no money was transferred'), findsOneWidget);
      expect(find.text('Confirm received'), findsOneWidget);
      expect(find.text('Pay 450 THB'), findsNothing);
    });

    testWidgets('6. Confirming receipt should complete the order.', (tester) async {
      final log = setupApp();
      useTallScreen(tester);
      await tester.pumpWidget(
        detailsApp(
          status: OrderStatus.readyForMeetup,
          meetupAt: DateTime.now().add(const Duration(days: 1)),
        ),
      );
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Confirm received'));
      expect(find.text('Confirm received?'), findsOneWidget);
      await tester.tap(inDialog(find.text('Yes, I got it')));
      await tester.pumpAndSettle();

      expect(log.called('POST', '/orders/401/received'), isTrue);
      // completed: the action is gone
      expect(find.text('Confirm received'), findsNothing);
      expect(find.text('Completed'), findsWidgets);
    });

    testWidgets('7. Not confirming receipt should keep the order open.', (tester) async {
      final log = setupApp();
      useTallScreen(tester);
      await tester.pumpWidget(detailsApp(status: OrderStatus.readyForMeetup));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Confirm received'));
      await tester.tap(inDialog(find.text('Cancel')));
      await tester.pumpAndSettle();

      expect(log.called('POST', '/orders/401/received'), isFalse);
      expect(find.text('Confirm received'), findsOneWidget);
    });

    testWidgets('8. The buyer should be able to cancel an unpaid order.', (tester) async {
      final log = setupApp();
      useTallScreen(tester);
      await tester.pumpWidget(detailsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel this order?'), findsOneWidget);

      await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Cancel order')));
      await tester.pumpAndSettle();

      expect(log.called('POST', '/orders/401/cancel'), isTrue);
      expect(find.text('This order was cancelled'), findsOneWidget);
      expect(find.text('Pay 450 THB'), findsNothing);
    });

    testWidgets('9. The buyer should be able to change the meet-up.', (tester) async {
      final log = setupApp();
      useTallScreen(tester);
      await tester.pumpWidget(
        detailsApp(meetupAt: DateTime.now().add(const Duration(days: 1))),
      );
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Edit'));
      expect(find.byType(ArrangeMeetupPage), findsOneWidget);
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Confirm meet-up'));

      expect(log.called('PUT', '/orders/401/meetup'), isTrue);
      expect(find.text('Meet-up updated'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------
  // /User/Payment (หน้านี้ pop ค่า true เมื่อจ่ายสำเร็จ จึงเปิดผ่าน PushHost)
  // ---------------------------------------------------------------------
  group('Payment page', () {
    Future<void> openPayment(
      WidgetTester tester, {
      double price = 450,
      bool paid = false,
      DateTime? deadline,
    }) async {
      useTallScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: PushHost<bool>(
            builder: (_) => PaymentPage(
              orderId: 401,
              title: 'Study Desk',
              price: price,
              sellerName: 'Sam Seller',
              paid: paid,
              paymentDeadline: deadline,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open page'));
      await tester.pumpAndSettle();
    }

    testWidgets('1. The order and the demo payment details should be shown.', (tester) async {
      setupApp();
      await openPayment(tester);

      expect(find.byType(PaymentPage), findsOneWidget);
      expect(find.text('Payment'), findsOneWidget);
      expect(find.text('Order #US-401'), findsOneWidget);
      expect(find.text('Study Desk'), findsOneWidget);
      expect(find.text('Seller: Sam Seller'), findsOneWidget);
      expect(find.text('Unpaid'), findsOneWidget);
      expect(find.text('Payment method'), findsOneWidget);
      expect(find.text('Demo QR · not scannable'), findsOneWidget);
      expect(find.text('Item price'), findsOneWidget);
      expect(find.text('Demo order total'), findsOneWidget);
      // the amount appears in the order card, the item price and the total
      expect(find.text('450.00 THB'), findsNWidgets(3));
      expect(find.text('Simulated payment'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Simulate payment'), findsOneWidget);
    });

    testWidgets('2. A paid order should not be paid again.', (tester) async {
      setupApp();
      await openPayment(tester, paid: true);

      expect(find.text('Demo paid'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Paid'));
      expect(button.onPressed, isNull);
    });

    testWidgets('3. Confirming the payment should record it and close the page.', (tester) async {
      final log = setupApp();
      await openPayment(tester);

      await tapVisible(tester, find.widgetWithText(FilledButton, 'Simulate payment'));
      expect(find.text('Simulate payment?'), findsOneWidget);
      expect(find.textContaining('No real money is charged'), findsOneWidget);
      await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Simulate payment')));
      await tester.pumpAndSettle();

      expect(log.bodyOf('POST', '/orders/401/pay')['payment_method'], 'gateway');
      expect(find.byType(PaymentPage), findsNothing);
      expect(find.text('Result: true'), findsOneWidget);
    });

    testWidgets('4. Cancelling the dialog should not record a payment.', (tester) async {
      final log = setupApp();
      await openPayment(tester);

      await tapVisible(tester, find.widgetWithText(FilledButton, 'Simulate payment'));
      await tester.tap(inDialog(find.text('Cancel')));
      await tester.pumpAndSettle();

      expect(log.called('POST', '/orders/401/pay'), isFalse);
      expect(find.byType(PaymentPage), findsOneWidget);
    });

    testWidgets('5. A free order should be confirmed with the free method.', (tester) async {
      final log = setupApp();
      await openPayment(tester, price: 0);

      await tapVisible(tester, find.widgetWithText(FilledButton, 'Confirm free order'));
      expect(find.text('Confirm free order?'), findsOneWidget);
      await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Confirm order')));
      await tester.pumpAndSettle();

      expect(log.bodyOf('POST', '/orders/401/pay')['payment_method'], 'free');
      expect(find.text('Result: true'), findsOneWidget);
    });

    testWidgets('6. A server error should be shown and the page should stay.', (tester) async {
      setupApp(
        override: (request) => request.url.path == '/api/orders/401/pay'
            ? json({'success': false, 'message': 'Order has expired'}, 409)
            : null,
      );
      await openPayment(tester);

      await tapVisible(tester, find.widgetWithText(FilledButton, 'Simulate payment'));
      await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Simulate payment')));
      await tester.pumpAndSettle();

      expect(find.text('Order has expired'), findsOneWidget);
      expect(find.byType(PaymentPage), findsOneWidget);
    });

    testWidgets('7. A payment deadline should show the countdown.', (tester) async {
      setupApp();
      await openPayment(tester, deadline: DateTime.now().add(const Duration(minutes: 10)));

      expect(find.textContaining('Pay within'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Simulate payment'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('8. An expired deadline should disable the payment.', (tester) async {
      setupApp();
      await openPayment(tester, deadline: DateTime.now().subtract(const Duration(minutes: 1)));

      expect(find.text('Payment time expired. This order has expired.'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Time expired'));
      expect(button.onPressed, isNull);
    });
  });

  // ---------------------------------------------------------------------
  // /User/ArrangeMeetup (หน้านี้ pop ค่า (when: ...) จึงเปิดผ่าน PushHost)
  // ---------------------------------------------------------------------
  group('Arrange meet-up page', () {
    Future<void> openMeetup(WidgetTester tester, {DateTime? initialWhen}) async {
      useTallScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: PushHost<MeetupChoice>(
            builder: (_) => ArrangeMeetupPage(
              productTitle: 'Study Desk',
              price: 450,
              sellerName: 'Sam Seller',
              sellerLocation: 'Test Residence',
              initialWhen: initialWhen,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open page'));
      await tester.pumpAndSettle();
    }

    testWidgets('1. The item, the seller location and the pickers should be shown.', (tester) async {
      await openMeetup(tester);

      expect(find.byType(ArrangeMeetupPage), findsOneWidget);
      expect(find.text('Arrange meet-up'), findsOneWidget);
      expect(find.text('Study Desk · 450 THB'), findsOneWidget);
      expect(find.text('Seller location'), findsOneWidget);
      expect(find.text('Test Residence'), findsWidgets);
      expect(find.text('Choose date & time'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Confirm meet-up'), findsOneWidget);
    });

    testWidgets('2. Confirming should return the chosen date and time.', (tester) async {
      await openMeetup(tester);

      await tapVisible(tester, find.widgetWithText(FilledButton, 'Confirm meet-up'));

      // the default time is tomorrow evening, so it is accepted
      expect(find.byType(ArrangeMeetupPage), findsNothing);
      expect(find.textContaining('Result: (when:'), findsOneWidget);
    });

    testWidgets('3. A time in the past should not be accepted.', (tester) async {
      await openMeetup(tester, initialWhen: DateTime.now().subtract(const Duration(days: 1)));

      await tapVisible(tester, find.widgetWithText(FilledButton, 'Confirm meet-up'));

      expect(find.text('Please choose a time in the future'), findsOneWidget);
      expect(find.byType(ArrangeMeetupPage), findsOneWidget);
    });

    testWidgets('4. The date picker should open and close.', (tester) async {
      await openMeetup(tester);

      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);
    });

    testWidgets('5. The time picker should open and close.', (tester) async {
      await openMeetup(tester);

      await tester.tap(find.byIcon(Icons.access_time));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsNothing);
    });

    testWidgets('6. Going back should return nothing.', (tester) async {
      await openMeetup(tester);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(ArrangeMeetupPage), findsNothing);
      expect(find.text('Result: null'), findsOneWidget);
    });
  });
}
