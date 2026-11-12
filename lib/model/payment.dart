import 'enums.dart';
import 'json_utils.dart';

/// แถวในตาราง `payments`
class Payment {
  const Payment({
    required this.id,
    required this.orderId,
    required this.method,
    required this.amount,
    this.gateway,
    this.transactionRef,
    this.slipUrl,
    this.gatewayFee = 0,
    this.status = PaymentStatus.pending,
    this.sellerTransferRef,
    this.sellerTransferStatus = SellerTransferStatus.notReady,
    this.sellerPaidAt,
    this.paidAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: jsonInt(json['payment_id'] ?? json['id']) ?? 0,
      orderId: jsonInt(json['order_id']) ?? 0,
      method: PaymentMethod.fromApi(json['payment_method']),
      gateway: jsonString(json['gateway']),
      transactionRef: jsonString(json['transaction_ref']),
      slipUrl: jsonString(json['payment_slip_url']),
      amount: jsonDouble(json['amount']) ?? 0,
      gatewayFee: jsonDouble(json['gateway_fee']) ?? 0,
      status: PaymentStatus.fromApi(json['payment_status']),
      sellerTransferRef: jsonString(json['seller_transfer_ref']),
      sellerTransferStatus: SellerTransferStatus.fromApi(
        json['seller_transfer_status'],
      ),
      sellerPaidAt: jsonDateTime(json['seller_paid_at']),
      paidAt: jsonDateTime(json['paid_at']),
      createdAt: jsonDateTime(json['created_at']),
      updatedAt: jsonDateTime(json['updated_at']),
    );
  }

  final int id; // payments.payment_id
  final int orderId; // payments.order_id
  final PaymentMethod method; // payments.payment_method
  final String? gateway; // payments.gateway
  final String? transactionRef; // payments.transaction_ref
  final String? slipUrl; // payments.payment_slip_url
  final double amount; // payments.amount DECIMAL(10,2)
  final double gatewayFee; // payments.gateway_fee DECIMAL(10,2)
  final PaymentStatus status; // payments.payment_status
  final String? sellerTransferRef; // payments.seller_transfer_ref
  final SellerTransferStatus sellerTransferStatus;
  final DateTime? sellerPaidAt; // payments.seller_paid_at
  final DateTime? paidAt; // payments.paid_at
  final DateTime? createdAt; // payments.created_at
  final DateTime? updatedAt; // payments.updated_at

  Map<String, dynamic> toJson() {
    return {
      'payment_id': id,
      'order_id': orderId,
      'payment_method': method.apiValue,
      'gateway': gateway,
      'transaction_ref': transactionRef,
      'payment_slip_url': slipUrl,
      'amount': amount,
      'gateway_fee': gatewayFee,
      'payment_status': status.apiValue,
      'seller_transfer_ref': sellerTransferRef,
      'seller_transfer_status': sellerTransferStatus.apiValue,
      'seller_paid_at': sellerPaidAt?.toUtc().toIso8601String(),
      'paid_at': paidAt?.toUtc().toIso8601String(),
      'created_at': createdAt?.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }
}
