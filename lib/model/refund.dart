import 'enums.dart';
import 'json_utils.dart';

/// แถวในตาราง `refunds`
class Refund {
  const Refund({
    required this.id,
    required this.orderId,
    required this.requestedBy,
    required this.amount,
    required this.reason,
    this.handledBy,
    this.status = RefundStatus.pending,
    this.gatewayRefundRef,
    this.proofUrl,
    this.requestedAt,
    this.resolvedAt,
    this.refundedAt,
  });

  factory Refund.fromJson(Map<String, dynamic> json) {
    return Refund(
      id: jsonInt(json['refund_id'] ?? json['id']) ?? 0,
      orderId: jsonInt(json['order_id']) ?? 0,
      requestedBy: jsonInt(json['requested_by']) ?? 0,
      handledBy: jsonInt(json['handled_by']),
      amount: jsonDouble(json['refund_amount'] ?? json['amount']) ?? 0,
      reason: jsonString(json['reason']) ?? '',
      status: RefundStatus.fromApi(json['refund_status'] ?? json['status']),
      gatewayRefundRef: jsonString(json['gateway_refund_ref']),
      proofUrl: jsonString(json['refund_proof_url']),
      requestedAt: jsonDateTime(json['requested_at']),
      resolvedAt: jsonDateTime(json['resolved_at']),
      refundedAt: jsonDateTime(json['refunded_at']),
    );
  }

  final int id; // refunds.refund_id
  final int orderId; // refunds.order_id
  final int requestedBy; // refunds.requested_by
  final int? handledBy; // refunds.handled_by
  final double amount; // refunds.refund_amount DECIMAL(10,2)
  final String reason; // refunds.reason
  final RefundStatus status; // refunds.refund_status
  final String? gatewayRefundRef; // refunds.gateway_refund_ref
  final String? proofUrl; // refunds.refund_proof_url
  final DateTime? requestedAt; // refunds.requested_at
  final DateTime? resolvedAt; // refunds.resolved_at
  final DateTime? refundedAt; // refunds.refunded_at

  bool get isOpen =>
      status == RefundStatus.pending ||
      status == RefundStatus.approved ||
      status == RefundStatus.processing;

  Map<String, dynamic> toJson() {
    return {
      'refund_id': id,
      'order_id': orderId,
      'requested_by': requestedBy,
      'handled_by': handledBy,
      'refund_amount': amount,
      'reason': reason,
      'refund_status': status.apiValue,
      'gateway_refund_ref': gatewayRefundRef,
      'refund_proof_url': proofUrl,
      'requested_at': requestedAt?.toUtc().toIso8601String(),
      'resolved_at': resolvedAt?.toUtc().toIso8601String(),
      'refunded_at': refundedAt?.toUtc().toIso8601String(),
    };
  }
}
