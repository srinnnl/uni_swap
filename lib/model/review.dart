import 'json_utils.dart';

/// แถวในตาราง `reviews`
class Review {
  const Review({
    required this.id,
    required this.orderId,
    required this.reviewerId,
    required this.sellerId,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: jsonInt(json['review_id'] ?? json['id']) ?? 0,
      orderId: jsonInt(json['order_id']) ?? 0,
      reviewerId: jsonInt(json['reviewer_id']) ?? 0,
      sellerId: jsonInt(json['seller_id']) ?? 0,
      rating: jsonInt(json['rating']) ?? 0,
      comment: jsonString(json['comment']),
      createdAt: jsonDateTime(json['created_at']),
    );
  }

  final int id; // reviews.review_id
  final int orderId; // reviews.order_id
  final int reviewerId; // reviews.reviewer_id
  final int sellerId; // reviews.seller_id
  final int rating; // reviews.rating 1-5
  final String? comment; // reviews.comment (ไม่เกิน 500 ตัวอักษร)
  final DateTime? createdAt; // reviews.created_at

  Map<String, dynamic> toJson() {
    return {
      'review_id': id,
      'order_id': orderId,
      'reviewer_id': reviewerId,
      'seller_id': sellerId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt?.toUtc().toIso8601String(),
    };
  }
}
