import 'package:flutter_test/flutter_test.dart';
import 'package:uni_swap/model/admin_transactions.dart';

void main() {
  test('parses transaction summary and completed sale payout details', () {
    final report = AdminTransactionsReport.fromJson({
      'summary': {
        'completed_sales': 2,
        'gross_sales': '450.00',
        'commission_income': '22.50',
        'pending_seller_payouts': '200.00',
      },
      'data': [
        {
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
          'seller_transfer_status': 'pending',
          'seller_transfer_ref': null,
        },
      ],
      'page': 1,
      'limit': 20,
      'has_more': false,
    });

    expect(report.summary.completedSales, 2);
    expect(report.summary.grossSales, 450);
    expect(report.summary.commissionIncome, 22.5);
    expect(report.summary.pendingSellerPayouts, 200);
    expect(report.transactions.single.productTitle, 'Desk lamp');
    expect(report.transactions.single.sellerTransferStatus, 'pending');
    expect(report.hasMore, false);
  });
}
