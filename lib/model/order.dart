import 'enums.dart';
import 'json_utils.dart';
import 'order_status.dart';

/// แถวในตาราง `orders` + ข้อมูล join จาก `/api/orders`
class Order {
  const Order({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.sellerPrice,
    required this.commissionRate,
    required this.commissionAmount,
    required this.totalAmount,
    required this.sellerPayout,
    required this.status,
    required this.meetupLocation,
    this.productTitle,
    this.productLocationName,
    this.pickupDetail,
    this.imageUrl,
    this.buyerName,
    this.sellerName,
    this.meetupDatetime,
    this.receivedAt,
    this.paymentDeadline,
    this.createdAt,
    this.updatedAt,
    this.perspective,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: jsonInt(json['order_id'] ?? json['id']) ?? 0,
      productId: jsonInt(json['product_id']) ?? 0,
      productTitle: jsonString(json['product_title'] ?? json['title']),
      productLocationName: jsonString(
        json['product_location_name'] ?? json['location_name'],
      ),
      pickupDetail: jsonString(json['pickup_detail']),
      imageUrl: jsonString(json['image_url']),
      buyerId: jsonInt(json['buyer_id']) ?? 0,
      buyerName: jsonString(json['buyer_name']),
      sellerId: jsonInt(json['seller_id']) ?? 0,
      sellerName: jsonString(json['seller_name']),
      sellerPrice: jsonDouble(json['seller_price']) ?? 0,
      commissionRate: jsonDouble(json['commission_rate']) ?? 0,
      commissionAmount: jsonDouble(json['commission_amount']) ?? 0,
      totalAmount: jsonDouble(json['total_amount']) ?? 0,
      sellerPayout: jsonDouble(json['seller_payout']) ?? 0,
      status:
          OrderStatus.tryParse(json['status']) ?? OrderStatus.pendingPayment,
      meetupLocation: jsonString(json['meetup_location']) ?? '',
      meetupDatetime: jsonDateTime(json['meetup_datetime']),
      receivedAt: jsonDateTime(json['received_at']),
      paymentDeadline: jsonDateTime(json['payment_deadline']),
      createdAt: jsonDateTime(json['created_at']),
      updatedAt: jsonDateTime(json['updated_at']),
      perspective: OrderPerspective.tryParse(json['perspective']),
    );
  }

  final int id; // orders.order_id
  final int productId; // orders.product_id
  final String? productTitle; // products.title (join)
  final String? productLocationName; // products.location_name (join)
  final String?
  pickupDetail; // products.location_detail (joined for participants)
  final String? imageUrl; // product_images.image_url (join)
  final int buyerId; // orders.buyer_id
  final String? buyerName; // users.display_name (join)
  final int sellerId; // orders.seller_id
  final String? sellerName; // users.display_name (join)
  final double sellerPrice; // orders.seller_price DECIMAL(10,2)
  final double commissionRate; // orders.commission_rate DECIMAL(5,2)
  final double commissionAmount; // orders.commission_amount DECIMAL(10,2)
  final double totalAmount; // orders.total_amount DECIMAL(10,2)
  final double sellerPayout; // orders.seller_payout DECIMAL(10,2)
  final OrderStatus status; // orders.status
  final String meetupLocation; // orders.meetup_location
  final DateTime? meetupDatetime; // orders.meetup_datetime
  final DateTime? receivedAt; // orders.received_at
  final DateTime? paymentDeadline; // orders.payment_deadline
  final DateTime? createdAt; // orders.created_at
  final DateTime? updatedAt; // orders.updated_at
  final OrderPerspective? perspective; // 'buying' / 'selling' จาก API

  bool get isBuying => perspective == OrderPerspective.buying;
  bool get isSelling => perspective == OrderPerspective.selling;

  /// ออเดอร์ที่เลย deadline แล้วแต่ยังไม่จ่าย ให้แสดงเป็น expired
  /// (backend จะเปลี่ยนสถานะจริงเมื่อมี cron/worker)
  OrderStatus get shownStatus {
    final deadline = paymentDeadline;
    if (status == OrderStatus.pendingPayment &&
        deadline != null &&
        !deadline.isAfter(DateTime.now())) {
      return OrderStatus.expired;
    }
    return status;
  }

  bool get isActive => shownStatus.isActive;

  /// สินค้าฟรี (ราคา 0) ไม่ต้องผ่านขั้นจ่ายเงิน
  bool get needsPayment => totalAmount > 0;

  Order copyWith({
    int? id,
    int? productId,
    String? productTitle,
    String? productLocationName,
    String? pickupDetail,
    String? imageUrl,
    int? buyerId,
    String? buyerName,
    int? sellerId,
    String? sellerName,
    double? sellerPrice,
    double? commissionRate,
    double? commissionAmount,
    double? totalAmount,
    double? sellerPayout,
    OrderStatus? status,
    String? meetupLocation,
    DateTime? meetupDatetime,
    DateTime? receivedAt,
    DateTime? paymentDeadline,
    DateTime? createdAt,
    DateTime? updatedAt,
    OrderPerspective? perspective,
  }) {
    return Order(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      productLocationName: productLocationName ?? this.productLocationName,
      pickupDetail: pickupDetail ?? this.pickupDetail,
      imageUrl: imageUrl ?? this.imageUrl,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerPrice: sellerPrice ?? this.sellerPrice,
      commissionRate: commissionRate ?? this.commissionRate,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      sellerPayout: sellerPayout ?? this.sellerPayout,
      status: status ?? this.status,
      meetupLocation: meetupLocation ?? this.meetupLocation,
      meetupDatetime: meetupDatetime ?? this.meetupDatetime,
      receivedAt: receivedAt ?? this.receivedAt,
      paymentDeadline: paymentDeadline ?? this.paymentDeadline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      perspective: perspective ?? this.perspective,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': id,
      'product_id': productId,
      'product_title': productTitle,
      'product_location_name': productLocationName,
      'pickup_detail': pickupDetail,
      'image_url': imageUrl,
      'buyer_id': buyerId,
      'buyer_name': buyerName,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'seller_price': sellerPrice,
      'commission_rate': commissionRate,
      'commission_amount': commissionAmount,
      'total_amount': totalAmount,
      'seller_payout': sellerPayout,
      'status': status.apiValue,
      'meetup_location': meetupLocation,
      'meetup_datetime': meetupDatetime?.toUtc().toIso8601String(),
      'received_at': receivedAt?.toUtc().toIso8601String(),
      'payment_deadline': paymentDeadline?.toUtc().toIso8601String(),
      'created_at': createdAt?.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
      'perspective': perspective?.apiValue,
    };
  }
}
