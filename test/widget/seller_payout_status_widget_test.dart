import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/model/order_status.dart';
import 'package:uni_swap/view/user/order_details_page.dart';
import 'package:uni_swap/view/user/orders_page.dart';

import 'widget_helpers.dart';

void main() {
  tearDown(() => apiClient.close());

  testWidgets('seller sees a pending payout in the list and receipt', (
    tester,
  ) async {
    setupApp(
      override: (request) =>
          request.method == 'GET' && request.url.path == '/api/orders'
          ? json({
              'success': true,
              'data': [
                {
                  ...sampleOrder(
                    id: 404,
                    title: 'Sold Desk',
                    status: 'completed',
                    perspective: 'selling',
                    price: 120,
                  ),
                  'seller_transfer_status': 'pending',
                },
              ],
              'has_more': false,
            })
          : null,
    );
    useTallScreen(tester);
    await tester.pumpWidget(
      const MaterialApp(home: OrdersPage(isActive: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Selling'));
    await tester.pumpAndSettle();
    expect(find.text('Seller payout: Awaiting admin payout'), findsOneWidget);

    await tester.tap(find.text('Sold Desk'));
    await tester.pumpAndSettle();
    expect(find.text('Payout status'), findsOneWidget);
    expect(find.text('Awaiting admin payout'), findsOneWidget);
    expect(find.textContaining('updates this status'), findsOneWidget);
  });

  testWidgets('seller sees the date when admin records a payout as paid', (
    tester,
  ) async {
    setupApp();
    useTallScreen(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: OrderDetailsPage(
          orderId: 405,
          title: 'Sold Desk',
          price: 120,
          totalAmount: 120,
          person: 'Buyer',
          isBuying: false,
          status: OrderStatus.completed,
          createdLabel: 'Yesterday',
          meetupPlace: 'Library',
          productLocation: 'Library',
          commissionRate: 5,
          commissionAmount: 6,
          sellerPayout: 114,
          sellerTransferStatus: 'paid',
          sellerTransferRef: 'BANK-123',
          sellerPaidAt: DateTime(2026, 11, 18, 10, 5),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Payout status'), findsOneWidget);
    expect(find.text('Paid (recorded by admin)'), findsOneWidget);
    expect(find.text('Payout recorded'), findsOneWidget);
    expect(find.text('Transfer reference'), findsOneWidget);
  });
}
