import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/view/admin/admin_transactions_page.dart';

import 'widget_helpers.dart';

void main() {
  tearDown(() => apiClient.close());

  testWidgets('shows completed sales and clearly labels demo payments', (
    tester,
  ) async {
    final log = setupApp(
      role: 'admin',
      override: (request) =>
          request.method == 'GET' &&
              request.url.path == '/api/admin/transactions'
          ? json({
              'success': true,
              'summary': {
                'completed_sales': 1,
                'gross_sales': '200.00',
                'commission_income': '10.00',
                'pending_seller_payouts': '190.00',
              },
              'data': [_sampleSale()],
              'page': 1,
              'limit': 20,
              'has_more': false,
            })
          : null,
    );
    useTallScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: AdminTransactionsPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(log.called('GET', '/admin/transactions'), isTrue);
    expect(find.text('Completed sales'), findsWidgets);
    expect(find.textContaining('buyer payment is simulated'), findsOneWidget);
    expect(find.text('Desk lamp'), findsOneWidget);
    expect(find.text('Awaiting payout'), findsWidgets);
    expect(find.text('Mark as paid'), findsOneWidget);
  });

  testWidgets('records a manual seller payout with its optional reference', (
    tester,
  ) async {
    late ApiLog log;
    var payoutRecorded = false;
    log = setupApp(
      role: 'admin',
      override: (request) {
        if (request.method == 'GET' &&
            request.url.path == '/api/admin/transactions') {
          return json({
            'success': true,
            'summary': {
              'completed_sales': 1,
              'gross_sales': '200.00',
              'commission_income': '10.00',
              'pending_seller_payouts': payoutRecorded ? '0.00' : '190.00',
            },
            'data': [_sampleSale(payoutRecorded: payoutRecorded)],
            'page': 1,
            'limit': 20,
            'has_more': false,
          });
        }
        if (request.method == 'PUT' &&
            request.url.path == '/api/admin/transactions/9/payout') {
          payoutRecorded = true;
          return json({'success': true, 'seller_transfer_status': 'paid'});
        }
        return null;
      },
    );
    useTallScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: AdminTransactionsPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Mark as paid'));
    await tester.pumpAndSettle();
    expect(find.textContaining('This only records the payout'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'BANK-123');
    await tester.tap(find.text('Confirm paid'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(log.bodyOf('PUT', '/admin/transactions/9/payout'), {
      'transfer_ref': 'BANK-123',
    });
    expect(find.text('Paid out'), findsOneWidget);
    expect(find.text('Reference: BANK-123'), findsOneWidget);
    expect(find.textContaining('Paid on:'), findsOneWidget);
    expect(find.text('Mark as paid'), findsNothing);
  });
}

Map<String, dynamic> _sampleSale({bool payoutRecorded = false}) => {
  'order_id': 9,
  'product_id': 3,
  'buyer_id': 1,
  'seller_id': 2,
  'title': 'Desk lamp',
  'buyer_name': 'Buyer',
  'seller_name': 'Seller',
  'seller_price': '200.00',
  'commission_rate': '5.00',
  'commission_amount': '10.00',
  'total_amount': '200.00',
  'seller_payout': '190.00',
  'status': 'completed',
  'meetup_location': 'Library',
  'received_at': '2026-11-18T10:00:00.000Z',
  'payment_status': 'paid',
  'seller_transfer_status': payoutRecorded ? 'paid' : 'pending',
  'seller_transfer_ref': payoutRecorded ? 'BANK-123' : null,
  'seller_paid_at': payoutRecorded ? '2026-11-18T10:05:00.000Z' : null,
};
