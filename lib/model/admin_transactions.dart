import 'json_utils.dart';
import 'order.dart';

class AdminTransactionSummary {
  const AdminTransactionSummary({
    this.completedSales = 0,
    this.grossSales = 0,
    this.commissionIncome = 0,
    this.pendingSellerPayouts = 0,
  });

  factory AdminTransactionSummary.fromJson(Map<String, dynamic> json) {
    return AdminTransactionSummary(
      completedSales: jsonInt(json['completed_sales']) ?? 0,
      grossSales: jsonDouble(json['gross_sales']) ?? 0,
      commissionIncome: jsonDouble(json['commission_income']) ?? 0,
      pendingSellerPayouts: jsonDouble(json['pending_seller_payouts']) ?? 0,
    );
  }

  final int completedSales;
  final double grossSales;
  final double commissionIncome;
  final double pendingSellerPayouts;
}

class AdminTransactionsReport {
  const AdminTransactionsReport({
    required this.summary,
    required this.transactions,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory AdminTransactionsReport.fromJson(Map<String, dynamic> json) {
    return AdminTransactionsReport(
      summary: AdminTransactionSummary.fromJson(jsonObject(json['summary'])),
      transactions: jsonParseList(json['data'], Order.fromJson),
      page: jsonInt(json['page']) ?? 1,
      limit: jsonInt(json['limit']) ?? 20,
      hasMore: json['has_more'] == true,
    );
  }

  final AdminTransactionSummary summary;
  final List<Order> transactions;
  final int page;
  final int limit;
  final bool hasMore;
}
