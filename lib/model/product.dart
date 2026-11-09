import 'enums.dart';
import 'json_utils.dart';
import 'order_status.dart';

/// รูปสินค้า 1 รูป (ตาราง `product_images`)
class ProductImage {
  const ProductImage({
    required this.id,
    required this.url,
    this.productId,
    this.displayOrder = 1,
    this.createdAt,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: jsonInt(json['image_id'] ?? json['id']) ?? 0,
      productId: jsonInt(json['product_id']),
      url: jsonString(json['image_url'] ?? json['url']) ?? '',
      displayOrder: jsonInt(json['display_order']) ?? 1,
      createdAt: jsonDateTime(json['created_at']),
    );
  }

  final int id; // product_images.image_id
  final int? productId; // product_images.product_id
  final String url; // product_images.image_url
  final int displayOrder; // product_images.display_order
  final DateTime? createdAt; // product_images.created_at

  Map<String, dynamic> toJson() {
    return {
      'image_id': id,
      'product_id': productId,
      'image_url': url,
      'display_order': displayOrder,
      'created_at': createdAt?.toUtc().toIso8601String(),
    };
  }
}

/// ข้อมูลผู้ขายแบบย่อที่ใช้ในหน้า product detail
class SellerInfo {
  const SellerInfo({
    required this.id,
    required this.name,
    this.username,
    this.rating = 0,
    this.sales = 0,
    this.location = '',
  });

  factory SellerInfo.fromJson(Map<String, dynamic> json) {
    return SellerInfo(
      id: jsonInt(json['user_id'] ?? json['seller_id'] ?? json['id']) ?? 0,
      name: jsonString(json['display_name'] ?? json['name']) ?? '',
      username: jsonString(json['username']),
      rating: jsonDouble(json['rating']) ?? 0,
      sales: jsonInt(json['sales']) ?? 0,
      location: jsonString(json['location'] ?? json['location_name']) ?? '',
    );
  }

  final int id; // users.user_id
  final String name; // users.display_name
  final String? username; // users.username
  final double rating; // reviews (ยังไม่มีใน schema ปัจจุบัน)
  final int sales; // นับจาก orders ที่ completed
  final String location;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'display_name': name,
      'username': username,
      'rating': rating,
      'sales': sales,
      'location': location,
    };
  }
}

/// แถวในตาราง `products`
///
/// ใช้ได้ทั้ง listing (`/api/products`, `/api/my/listings`) และ detail
/// (`/api/products/:product_id`) โดย field ที่เป็น join จะเป็น null
/// ถ้า endpoint นั้นไม่ได้ select มา
class Product {
  const Product({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.price,
    required this.category,
    this.sellerName,
    this.sellerUsername,
    this.description,
    this.categoryId,
    this.categoryName,
    this.itemCondition,
    this.urgencyLevel = UrgencyLevel.normal,
    this.zone = ResidenceZone.onCampus,
    this.locationName = '',
    this.locationId,
    this.locationDetail,
    this.clearanceDeadline,
    this.status = ProductStatus.pendingReview,
    this.createdAt,
    this.updatedAt,
    this.reviewNote,
    this.rejectReason,
    this.reviewedBy,
    this.reviewedAt,
    this.viewCount = 0,
    this.imageUrl,
    this.images = const <ProductImage>[],
    this.isOwnItem = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: jsonInt(json['product_id'] ?? json['id']) ?? 0,
      sellerId: jsonInt(json['seller_id']) ?? 0,
      sellerName: jsonString(json['seller_name']),
      sellerUsername: jsonString(json['seller_username'] ?? json['username']),
      title: jsonString(json['title']) ?? '',
      description: jsonString(json['description']),
      // products.category เป็น NOT NULL ใน schema (project_mobile_app.sql)
      category: jsonString(json['category']) ?? '',
      categoryId: jsonInt(json['category_id']),
      categoryName: jsonString(json['category_name']),
      price: jsonDouble(json['price']) ?? 0,
      itemCondition: ItemCondition.tryParse(json['item_condition']),
      urgencyLevel: UrgencyLevel.fromApi(json['urgency_level']),
      zone: ResidenceZone.fromApi(json['zone']),
      locationName: jsonString(json['location_name']) ?? '',
      locationId: jsonInt(json['location_id']),
      locationDetail: jsonString(json['location_detail']),
      clearanceDeadline: jsonDateTime(json['clearance_deadline']),
      status:
          ProductStatus.tryParse(json['status']) ?? ProductStatus.pendingReview,
      createdAt: jsonDateTime(json['created_at']),
      updatedAt: jsonDateTime(json['updated_at']),
      reviewNote: jsonString(json['review_note']),
      rejectReason: RejectReason.tryParse(json['reject_reason']),
      reviewedBy: jsonInt(json['reviewed_by']),
      reviewedAt: jsonDateTime(json['reviewed_at']),
      viewCount: jsonInt(json['view_count']) ?? 0,
      imageUrl: jsonString(json['image_url']),
      images: jsonParseList(json['images'], ProductImage.fromJson),
      isOwnItem: jsonBool(json['is_own_item']) ?? false,
    );
  }

  final int id; // products.product_id
  final int sellerId; // products.seller_id
  final String? sellerName; // users.display_name (join)
  final String? sellerUsername; // users.username (join)
  final String title; // products.title
  final String? description; // products.description
  final String category; // products.category (NOT NULL ใน schema)
  final int? categoryId; // products.category_id
  final String? categoryName; // categories.name (join)
  final double price; // products.price DECIMAL(10,2)
  final ItemCondition? itemCondition; // products.item_condition
  final UrgencyLevel urgencyLevel; // products.urgency_level
  final ResidenceZone zone; // products.zone
  final String locationName; // products.location_name
  final int? locationId; // products.location_id
  final String? locationDetail; // products.location_detail
  final DateTime? clearanceDeadline; // products.clearance_deadline (date)
  final ProductStatus status; // products.status
  final DateTime? createdAt; // products.created_at
  final DateTime? updatedAt; // products.updated_at
  final String? reviewNote; // products.review_note
  final RejectReason? rejectReason; // products.reject_reason
  final int? reviewedBy; // products.reviewed_by
  final DateTime? reviewedAt; // products.reviewed_at
  final int viewCount; // products.view_count
  final String? imageUrl; // product_images.image_url (join 1 รูป)
  final List<ProductImage> images; // product_images (detail endpoint)
  final bool isOwnItem; // คำนวณจาก seller_id == user ที่ login

  String get categoryLabel => (categoryName != null && categoryName!.isNotEmpty)
      ? categoryName!
      : category;
  bool get isAvailable => status == ProductStatus.available;
  bool get isUrgent => urgencyLevel != UrgencyLevel.normal;

  String? get primaryImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl;
    if (images.isEmpty) return null;
    return images.first.url;
  }

  /// จำนวนวันก่อนหมดเขต clearance (0 = หมดเขตแล้ว)
  int? get daysLeft {
    final deadline = clearanceDeadline;
    if (deadline == null) return null;

    final difference = deadline.difference(DateTime.now()).inDays;
    return difference < 0 ? 0 : difference;
  }

  Product copyWith({
    int? id,
    int? sellerId,
    String? sellerName,
    String? sellerUsername,
    String? title,
    String? description,
    String? category,
    int? categoryId,
    String? categoryName,
    double? price,
    ItemCondition? itemCondition,
    UrgencyLevel? urgencyLevel,
    ResidenceZone? zone,
    String? locationName,
    int? locationId,
    String? locationDetail,
    DateTime? clearanceDeadline,
    ProductStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? reviewNote,
    RejectReason? rejectReason,
    int? reviewedBy,
    DateTime? reviewedAt,
    int? viewCount,
    String? imageUrl,
    List<ProductImage>? images,
    bool? isOwnItem,
  }) {
    return Product(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerUsername: sellerUsername ?? this.sellerUsername,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      price: price ?? this.price,
      itemCondition: itemCondition ?? this.itemCondition,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      zone: zone ?? this.zone,
      locationName: locationName ?? this.locationName,
      locationId: locationId ?? this.locationId,
      locationDetail: locationDetail ?? this.locationDetail,
      clearanceDeadline: clearanceDeadline ?? this.clearanceDeadline,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewNote: reviewNote ?? this.reviewNote,
      rejectReason: rejectReason ?? this.rejectReason,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      viewCount: viewCount ?? this.viewCount,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      isOwnItem: isOwnItem ?? this.isOwnItem,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': id,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'seller_username': sellerUsername,
      'title': title,
      'description': description,
      'category': category,
      'category_id': categoryId,
      'category_name': categoryName,
      'price': price,
      'item_condition': itemCondition?.apiValue,
      'urgency_level': urgencyLevel.apiValue,
      'zone': zone.apiValue,
      'location_name': locationName,
      'location_id': locationId,
      'location_detail': locationDetail,
      'clearance_deadline': clearanceDeadline?.toIso8601String(),
      'status': status.apiValue,
      'created_at': createdAt?.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
      'review_note': reviewNote,
      'reject_reason': rejectReason?.apiValue,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toUtc().toIso8601String(),
      'view_count': viewCount,
      'image_url': imageUrl,
      'images': images.map((image) => image.toJson()).toList(growable: false),
      'is_own_item': isOwnItem,
    };
  }
}

/// Model สำหรับหน้า product detail
///
/// มี field แบบ UI-friendly (`place`, `urgent`, `daysLeft`, `imageUrls`)
/// เพื่อให้หน้าเดิมใช้งานต่อได้ง่าย และมี `product` เก็บข้อมูลดิบจาก API ครบถ้วน
class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.title,
    required this.price,
    required this.place,
    this.category,
    this.description,
    this.urgent = false,
    this.daysLeft,
    this.imageUrls = const <String>[],
    this.seller,
    this.status = ProductStatus.available,
    this.isOwnItem = false,
    this.product,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail.fromProduct(Product.fromJson(json));
  }

  factory ProductDetail.fromProduct(Product product) {
    final urls = product.images
        .map((image) => image.url)
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    final primary = product.primaryImageUrl;

    return ProductDetail(
      id: product.id,
      title: product.title,
      price: product.price,
      place: product.locationName,
      category: product.categoryLabel.isEmpty ? null : product.categoryLabel,
      description: product.description,
      urgent: product.isUrgent,
      daysLeft: product.daysLeft,
      imageUrls: urls.isNotEmpty ? urls : <String>[?primary],
      seller: product.sellerId > 0 && (product.sellerName?.isNotEmpty ?? false)
          ? SellerInfo(
              id: product.sellerId,
              name: product.sellerName!,
              username: product.sellerUsername,
              location: product.locationName,
            )
          : null,
      status: product.status,
      isOwnItem: product.isOwnItem,
      product: product,
    );
  }

  /// ข้อมูลตัวอย่างสำหรับ UI ก่อนต่อ API
  factory ProductDetail.mock({
    required int id,
    required String title,
    required double price,
    required String place,
    String? category,
    bool urgent = false,
  }) {
    return ProductDetail(
      id: id,
      title: title,
      price: price,
      place: place,
      category: category,
      description:
          'Solid ${title.toLowerCase()} in great condition. A few small marks, '
          'but sturdy and ready for a new home. Must go soon.',
      urgent: urgent,
      daysLeft: urgent ? 3 : null,
      seller: SellerInfo(
        id: 0,
        name: 'Jamie Lee',
        rating: 4.9,
        sales: 18,
        location: place.split(' · ').last,
      ),
    );
  }

  final int id;
  final String title;
  final double price;
  final String place;
  final String? category;
  final String? description;
  final bool urgent;
  final int? daysLeft;
  final List<String> imageUrls;
  final SellerInfo? seller;
  final ProductStatus status;
  final bool isOwnItem;

  /// ข้อมูลดิบจาก API (null ถ้าสร้างจาก mock)
  final Product? product;

  Map<String, dynamic> toJson() {
    final json = product?.toJson() ?? <String, dynamic>{};
    json['product_id'] = id;
    json['title'] = title;
    json['price'] = price;
    json['location_name'] = place;
    json['category_name'] = category;
    json['description'] = description;
    json['urgency_level'] = urgent
        ? UrgencyLevel.urgent.apiValue
        : UrgencyLevel.normal.apiValue;
    json['status'] = status.apiValue;
    json['is_own_item'] = isOwnItem;
    if (imageUrls.isNotEmpty) {
      json['images'] = [
        for (var index = 0; index < imageUrls.length; index++)
          {'image_url': imageUrls[index], 'display_order': index + 1},
      ];
    }
    return json;
  }
}
