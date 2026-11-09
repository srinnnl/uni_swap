import 'package:flutter_test/flutter_test.dart';
import 'package:uni_swap/model/models.dart';

Map<String, dynamic> userJson() {
  return {
    'user_id': '2',
    'student_id': '6501000002',
    'username': 'maya_demo',
    'email': 'maya@unisw.ap',
    'display_name': 'Maya Demo',
    'residence_zone': 'on_campus',
    'residence_location_id': '1',
    'residence_name': 'Lamduan 1 Dormitory',
    'role': 'member',
    'status': 'active',
    'verified_by': '1',
    'verified_at': '2026-11-01T09:00:00.000Z',
    'created_at': '2026-11-01T08:00:00.000Z',
    'updated_at': '2026-11-02T08:00:00.000Z',
  };
}

Map<String, dynamic> productJson() {
  return {
    'product_id': '10',
    'seller_id': '3',
    'seller_name': 'Niran Demo',
    'seller_username': 'niran_demo',
    'title': 'Oak study desk',
    'description': 'Solid desk in good condition',
    'category': 'Furniture',
    'category_id': '1',
    'category_name': 'Furniture & Decor',
    'price': '450.00',
    'item_condition': 'good',
    'urgency_level': 'urgent',
    'zone': 'on_campus',
    'location_name': 'Lamduan 1 Dormitory',
    'location_id': '2',
    'location_detail': 'Building A',
    'clearance_deadline': '2099-01-01',
    'status': 'available',
    'created_at': '2026-11-05T10:00:00.000Z',
    'updated_at': '2026-11-05T11:00:00.000Z',
    'review_note': null,
    'reject_reason': null,
    'reviewed_by': null,
    'reviewed_at': null,
    'view_count': '7',
    'image_url': 'https://example.com/desk-cover.jpg',
    'images': [
      {
        'image_id': '1',
        'product_id': '10',
        'image_url': 'https://example.com/desk-1.jpg',
        'display_order': '1',
      },
      {
        'image_id': '2',
        'product_id': '10',
        'image_url': 'https://example.com/desk-2.jpg',
        'display_order': '2',
      },
    ],
    'is_own_item': 0,
  };
}

Map<String, dynamic> orderJson() {
  return {
    'order_id': '5',
    'product_id': '10',
    'title': 'Oak study desk',
    'location_name': 'Lamduan 1 Dormitory',
    'image_url': 'https://example.com/desk-cover.jpg',
    'buyer_id': '2',
    'buyer_name': 'Maya Demo',
    'seller_id': '3',
    'seller_name': 'Niran Demo',
    'seller_price': '450.00',
    'commission_rate': '5.00',
    'commission_amount': '22.50',
    'total_amount': '472.50',
    'seller_payout': '450.00',
    'status': 'pending_payment',
    'meetup_location': 'Lamduan 1 lobby',
    'meetup_datetime': '2026-11-10T10:00:00.000Z',
    'received_at': null,
    'payment_deadline': '2020-01-01T00:00:00.000Z',
    'created_at': '2026-11-05T10:00:00.000Z',
    'updated_at': '2026-11-05T10:01:00.000Z',
    'perspective': 'buying',
  };
}

void main() {
  group('JSON helpers', () {
    test('อ่านตัวเลขที่ MySQL ส่งมาเป็น string', () {
      expect(jsonInt('42'), 42);
      expect(jsonDouble('12.50'), 12.50);
      expect(jsonBool(1), isTrue);
      expect(jsonBool('0'), isFalse);
    });

    test('อ่านวันที่ ISO-8601 เป็นเวลาท้องถิ่น', () {
      final date = jsonDateTime('2026-11-09T10:00:00.000Z');

      expect(date, isNotNull);
      expect(date!.toUtc(), DateTime.utc(2026, 11, 9, 10));
      expect(date.isUtc, isFalse);
    });
  });

  group('User', () {
    test('parse จาก /api/profile และคำนวณ initials', () {
      final user = User.fromJson(userJson());

      expect(user.id, 2);
      expect(user.studentId, '6501000002');
      expect(user.email, 'maya@unisw.ap');
      expect(user.displayName, 'Maya Demo');
      expect(user.initials, 'MD');
      expect(user.residenceZone, ResidenceZone.onCampus);
      expect(user.residenceName, 'Lamduan 1 Dormitory');
      expect(user.role, UserRole.member);
      expect(user.status, UserStatus.active);
      expect(user.isActive, isTrue);
      expect(user.createdAt?.toUtc(), DateTime.utc(2026, 11, 1, 8));
    });

    test('toJson ใช้ชื่อ field แบบเดียวกับ API', () {
      final json = User.fromJson(userJson()).toJson();

      expect(json['user_id'], 2);
      expect(json['residence_zone'], 'on_campus');
      expect(json['role'], 'member');
      expect(json['status'], 'active');
      expect(json['created_at'], '2026-11-01T08:00:00.000Z');
    });
  });

  group('Category, Location และ LocationRequest', () {
    test('parse Category พร้อม product_count', () {
      final category = Category.fromJson({
        'category_id': '1',
        'name': 'Furniture & Decor',
        'emoji': '🛋️',
        'is_active': 1,
        'product_count': '12',
        'created_at': '2026-11-01T08:00:00.000Z',
      });

      expect(category.id, 1);
      expect(category.name, 'Furniture & Decor');
      expect(category.isActive, isTrue);
      expect(category.productCount, 12);
    });

    test('parse Location', () {
      final location = Location.fromJson({
        'location_id': '2',
        'zone': 'off_campus',
        'name': 'Sunrise Apartment',
        'is_active': 0,
      });

      expect(location.id, 2);
      expect(location.zone, ResidenceZone.offCampus);
      expect(location.name, 'Sunrise Apartment');
      expect(location.isActive, isFalse);
    });

    test('parse LocationRequest พร้อมข้อมูลผู้ขอ', () {
      final request = LocationRequest.fromJson({
        'request_id': '4',
        'user_id': '2',
        'name': 'Sunrise Apartment',
        'zone': 'off_campus',
        'address': '123 Road',
        'reason': 'Not listed',
        'status': 'pending',
        'approved_location_id': null,
        'merged_into_location_id': null,
        'handled_by': null,
        'requester_name': 'Maya Demo',
        'username': 'maya_demo',
        'created_at': '2026-11-05T10:00:00.000Z',
        'resolved_at': null,
      });

      expect(request.id, 4);
      expect(request.zone, ResidenceZone.offCampus);
      expect(request.status, LocationRequestStatus.pending);
      expect(request.requesterName, 'Maya Demo');
      expect(request.isOpen, isTrue);
    });
  });

  group('Product', () {
    test('parse listing/detail ที่มี DECIMAL และ join fields', () {
      final product = Product.fromJson(productJson());

      expect(product.id, 10);
      expect(product.sellerId, 3);
      expect(product.sellerName, 'Niran Demo');
      expect(product.title, 'Oak study desk');
      expect(product.price, 450.0);
      expect(product.categoryLabel, 'Furniture & Decor');
      expect(product.itemCondition, ItemCondition.good);
      expect(product.urgencyLevel, UrgencyLevel.urgent);
      expect(product.isUrgent, isTrue);
      expect(product.zone, ResidenceZone.onCampus);
      expect(product.locationName, 'Lamduan 1 Dormitory');
      expect(product.locationDetail, 'Building A');
      expect(product.status, ProductStatus.available);
      expect(product.isAvailable, isTrue);
      expect(product.viewCount, 7);
      expect(product.images, hasLength(2));
      expect(product.primaryImageUrl, 'https://example.com/desk-cover.jpg');
      expect(product.daysLeft, greaterThan(0));
      expect(product.isOwnItem, isFalse);
    });

    test('ProductDetail.fromJson แปลงเป็น field ที่ UI ใช้', () {
      final detail = ProductDetail.fromJson(productJson());

      expect(detail.id, 10);
      expect(detail.title, 'Oak study desk');
      expect(detail.price, 450.0);
      expect(detail.place, 'Lamduan 1 Dormitory');
      expect(detail.category, 'Furniture & Decor');
      expect(detail.urgent, isTrue);
      expect(detail.imageUrls, [
        'https://example.com/desk-1.jpg',
        'https://example.com/desk-2.jpg',
      ]);
      expect(detail.seller?.id, 3);
      expect(detail.seller?.name, 'Niran Demo');
      expect(detail.seller?.initials, 'ND');
      expect(detail.status, ProductStatus.available);
      expect(detail.product?.id, 10);
    });

    test('ProductDetail.mock ยังใช้กับหน้า UI เดิมได้', () {
      final detail = ProductDetail.mock(
        id: 1,
        title: 'City bike',
        price: 0,
        place: 'On-campus dorms · Lamduan 1 Dormitory',
        category: 'Sports',
        urgent: true,
      );

      expect(detail.id, 1);
      expect(detail.place, 'On-campus dorms · Lamduan 1 Dormitory');
      expect(detail.seller?.name, 'Jamie Lee');
      expect(detail.daysLeft, 3);
      expect(detail.product, isNull);
    });
  });

  group('Order', () {
    test('parse order พร้อม join และตรวจ deadline ที่เลยแล้ว', () {
      final order = Order.fromJson(orderJson());

      expect(order.id, 5);
      expect(order.productId, 10);
      expect(order.productTitle, 'Oak study desk');
      expect(order.buyerName, 'Maya Demo');
      expect(order.sellerName, 'Niran Demo');
      expect(order.sellerPrice, 450.0);
      expect(order.commissionAmount, 22.50);
      expect(order.totalAmount, 472.50);
      expect(order.status, OrderStatus.pendingPayment);
      expect(order.perspective, OrderPerspective.buying);
      expect(order.isBuying, isTrue);
      expect(order.isSelling, isFalse);
      expect(order.shownStatus, OrderStatus.expired);
      expect(order.isActive, isFalse);
      expect(order.needsPayment, isTrue);
    });

    test('copyWith เปลี่ยนสถานะได้โดยไม่กระทบ field อื่น', () {
      final paid = Order.fromJson(
        orderJson(),
      ).copyWith(status: OrderStatus.paid);

      expect(paid.status, OrderStatus.paid);
      expect(paid.shownStatus, OrderStatus.paid);
      expect(paid.id, 5);
    });
  });

  group('Payment, Refund, Report, Review และ BankAccount', () {
    test('parse Payment', () {
      final payment = Payment.fromJson({
        'payment_id': '8',
        'order_id': '5',
        'payment_method': 'bank_transfer',
        'gateway': null,
        'transaction_ref': 'REF-001',
        'payment_slip_url': 'https://example.com/slip.jpg',
        'amount': '472.50',
        'gateway_fee': '0.00',
        'payment_status': 'paid',
        'seller_transfer_ref': null,
        'seller_transfer_status': 'held',
        'seller_paid_at': null,
        'paid_at': '2026-11-05T10:30:00.000Z',
      });

      expect(payment.method, PaymentMethod.bankTransfer);
      expect(payment.status, PaymentStatus.paid);
      expect(payment.sellerTransferStatus, SellerTransferStatus.held);
      expect(payment.amount, 472.50);
    });

    test('parse Refund', () {
      final refund = Refund.fromJson({
        'refund_id': '3',
        'order_id': '5',
        'requested_by': '2',
        'handled_by': null,
        'refund_amount': '472.50',
        'reason': 'Item not as described',
        'refund_status': 'pending',
        'gateway_refund_ref': null,
        'refund_proof_url': null,
        'requested_at': '2026-11-06T10:00:00.000Z',
      });

      expect(refund.id, 3);
      expect(refund.status, RefundStatus.pending);
      expect(refund.isOpen, isTrue);
      expect(refund.amount, 472.50);
    });

    test('parse Report พร้อม join จาก admin', () {
      final report = Report.fromJson({
        'report_id': '9',
        'reporter_id': '2',
        'reporter_name': 'Maya Demo',
        'order_id': '5',
        'product_id': '10',
        'product_title': 'Oak study desk',
        'report_type': 'product_problem',
        'reason': 'Broken leg',
        'evidence_url': 'https://example.com/evidence.jpg',
        'status': 'reviewing',
        'reviewed_by': '1',
        'admin_note': 'Checking with seller',
        'created_at': '2026-11-06T10:00:00.000Z',
        'resolved_at': null,
      });

      expect(report.type, ReportType.productProblem);
      expect(report.status, ReportStatus.reviewing);
      expect(report.productTitle, 'Oak study desk');
      expect(report.isOpen, isTrue);
    });

    test('parse Review', () {
      final review = Review.fromJson({
        'review_id': '1',
        'order_id': '5',
        'reviewer_id': '2',
        'seller_id': '3',
        'rating': '5',
        'comment': 'Great seller',
        'created_at': '2026-11-07T10:00:00.000Z',
      });

      expect(review.rating, 5);
      expect(review.comment, 'Great seller');
    });

    test('parse BankAccount และปิดเลขบัญชี', () {
      final account = BankAccount.fromJson({
        'bank_account_id': '1',
        'user_id': '3',
        'bank_name': 'Kasikorn Bank',
        'account_last4': '1234',
        'account_name': 'Niran Demo',
        'status': 'verified',
        'verified_by': '1',
        'verified_at': '2026-11-01T10:00:00.000Z',
      });

      expect(account.status, BankAccountStatus.verified);
      expect(account.maskedNumber, '•••• 1234');
    });
  });

  group('Response wrappers', () {
    test('ApiPage parse pagination และ data', () {
      final page = ApiPage.fromJson({
        'data': [productJson()],
        'page': '1',
        'limit': '20',
        'has_more': 0,
      }, Product.fromJson);

      expect(page.data, hasLength(1));
      expect(page.data.single.title, 'Oak study desk');
      expect(page.page, 1);
      expect(page.limit, 20);
      expect(page.hasMore, isFalse);
    });

    test('AuthSession parse token และ user', () {
      final session = AuthSession.fromJson({
        'token': 'jwt-token',
        'user': userJson(),
      });

      expect(session.isValid, isTrue);
      expect(session.user.email, 'maya@unisw.ap');
    });

    test('DashboardSummary parse counts และ pending location request', () {
      final dashboard = DashboardSummary.fromJson({
        'user': userJson(),
        'counts': {
          'my_listings': '2',
          'listings_to_review': '1',
          'listings_to_fix': '0',
          'buying_active': '1',
          'selling_active': '0',
          'refunds_pending': '0',
        },
        'recent_listings': [productJson()],
        'recent_orders': [orderJson()],
        'pending_location_request': {
          'request_id': '4',
          'name': 'Sunrise Apartment',
          'zone': 'off_campus',
          'status': 'pending',
        },
      });

      expect(dashboard.user.displayName, 'Maya Demo');
      expect(dashboard.counts.myListings, 2);
      expect(dashboard.recentListings.single.title, 'Oak study desk');
      expect(dashboard.recentOrders.single.id, 5);
      expect(dashboard.pendingLocationRequest?.name, 'Sunrise Apartment');
      expect(
        dashboard.pendingLocationRequest?.status,
        LocationRequestStatus.pending,
      );
    });

    test('AdminDashboard parse overview และ queue ต่าง ๆ', () {
      final dashboard = AdminDashboard.fromJson({
        'overview': {
          'users_total': '3',
          'users_pending': '1',
          'items_live': '2',
          'items_pending': '1',
          'reports_open': '1',
          'locations_pending': '1',
          'categories_active': '4',
          'refunds_pending': '0',
        },
        'pending_listings': [productJson()],
        'open_reports': [
          {
            'report_id': '9',
            'reporter_id': '2',
            'report_type': 'product_problem',
            'reason': 'Broken leg',
            'status': 'pending',
            'title': 'Oak study desk',
            'order_id': '5',
          },
        ],
        'pending_location_requests': [
          {
            'request_id': '4',
            'name': 'Sunrise Apartment',
            'zone': 'off_campus',
            'status': 'pending',
            'requester_name': 'Maya Demo',
          },
        ],
      });

      expect(dashboard.overview.usersTotal, 3);
      expect(dashboard.overview.itemsPending, 1);
      expect(dashboard.pendingListings.single.id, 10);
      expect(dashboard.openReports.single.productTitle, 'Oak study desk');
      expect(
        dashboard.pendingLocationRequests.single.requesterName,
        'Maya Demo',
      );
    });
  });
}
