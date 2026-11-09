import 'json_utils.dart';

/// แถวในตาราง `categories`
///
/// `/api/admin/categories` ส่ง `product_count` (join) เพิ่มมาด้วย
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.emoji,
    this.isActive = true,
    this.productCount,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: jsonInt(json['category_id'] ?? json['id']) ?? 0,
      name: jsonString(json['name']) ?? '',
      emoji: jsonString(json['emoji']) ?? '',
      isActive: jsonBool(json['is_active']) ?? true,
      productCount: jsonInt(json['product_count']),
      createdAt: jsonDateTime(json['created_at']),
      updatedAt: jsonDateTime(json['updated_at']),
    );
  }

  final int id; // categories.category_id
  final String name; // categories.name
  final String emoji; // categories.emoji
  final bool isActive; // categories.is_active
  final int? productCount; // COUNT(products.product_id) (join)
  final DateTime? createdAt; // categories.created_at
  final DateTime? updatedAt; // categories.updated_at

  Map<String, dynamic> toJson() {
    return {
      'category_id': id,
      'name': name,
      'emoji': emoji,
      'is_active': isActive,
      'product_count': productCount,
      'created_at': createdAt?.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }
}
