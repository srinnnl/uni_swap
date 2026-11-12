import 'enums.dart';
import 'json_utils.dart';

/// แถวในตาราง `reports` + join จาก `/api/admin/reports`
class Report {
  const Report({
    required this.id,
    required this.reporterId,
    required this.type,
    required this.reason,
    this.reporterName,
    this.orderId,
    this.productId,
    this.productTitle,
    this.evidenceUrl,
    this.status = ReportStatus.pending,
    this.reviewedBy,
    this.adminNote,
    this.createdAt,
    this.resolvedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: jsonInt(json['report_id'] ?? json['id']) ?? 0,
      reporterId: jsonInt(json['reporter_id']) ?? 0,
      reporterName: jsonString(json['reporter_name']),
      orderId: jsonInt(json['order_id']),
      productId: jsonInt(json['product_id']),
      productTitle: jsonString(json['product_title'] ?? json['title']),
      type: ReportType.fromApi(json['report_type'] ?? json['type']),
      reason: jsonString(json['reason']) ?? '',
      evidenceUrl: jsonString(json['evidence_url']),
      status: ReportStatus.fromApi(json['status']),
      reviewedBy: jsonInt(json['reviewed_by']),
      adminNote: jsonString(json['admin_note']),
      createdAt: jsonDateTime(json['created_at']),
      resolvedAt: jsonDateTime(json['resolved_at']),
    );
  }

  final int id; // reports.report_id
  final int reporterId; // reports.reporter_id
  final String? reporterName; // users.display_name (join)
  final int? orderId; // reports.order_id
  final int? productId; // orders.product_id (join)
  final String? productTitle; // products.title (join)
  final ReportType type; // reports.report_type
  final String reason; // reports.reason
  final String? evidenceUrl; // reports.evidence_url
  final ReportStatus status; // reports.status
  final int? reviewedBy; // reports.reviewed_by
  final String? adminNote; // reports.admin_note
  final DateTime? createdAt; // reports.created_at
  final DateTime? resolvedAt; // reports.resolved_at

  bool get isOpen =>
      status == ReportStatus.pending || status == ReportStatus.reviewing;

  Map<String, dynamic> toJson() {
    return {
      'report_id': id,
      'reporter_id': reporterId,
      'reporter_name': reporterName,
      'order_id': orderId,
      'product_id': productId,
      'product_title': productTitle,
      'report_type': type.apiValue,
      'reason': reason,
      'evidence_url': evidenceUrl,
      'status': status.apiValue,
      'reviewed_by': reviewedBy,
      'admin_note': adminNote,
      'created_at': createdAt?.toUtc().toIso8601String(),
      'resolved_at': resolvedAt?.toUtc().toIso8601String(),
    };
  }
}
