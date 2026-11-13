import 'enums.dart';
import 'json_utils.dart';
import 'location.dart';
import 'order.dart';
import 'product.dart';
import 'user.dart';

/// ตัวเลขสรุปใน `/api/dashboard`
class DashboardCounts {
  const DashboardCounts({
    this.myListings = 0,
    this.listingsToReview = 0,
    this.listingsToFix = 0,
    this.buyingActive = 0,
    this.sellingActive = 0,
  });

  factory DashboardCounts.fromJson(Map<String, dynamic> json) {
    return DashboardCounts(
      myListings: jsonInt(json['my_listings']) ?? 0,
      listingsToReview: jsonInt(json['listings_to_review']) ?? 0,
      listingsToFix: jsonInt(json['listings_to_fix']) ?? 0,
      buyingActive: jsonInt(json['buying_active']) ?? 0,
      sellingActive: jsonInt(json['selling_active']) ?? 0,
    );
  }

  final int myListings;
  final int listingsToReview;
  final int listingsToFix;
  final int buyingActive;
  final int sellingActive;

  Map<String, dynamic> toJson() {
    return {
      'my_listings': myListings,
      'listings_to_review': listingsToReview,
      'listings_to_fix': listingsToFix,
      'buying_active': buyingActive,
      'selling_active': sellingActive,
    };
  }
}

/// คำขอเพิ่มที่พักที่ยังรอ admin ตรวจ ใน `/api/dashboard`
class PendingLocationRequest {
  const PendingLocationRequest({
    required this.id,
    required this.name,
    required this.zone,
    this.status = LocationRequestStatus.pending,
  });

  factory PendingLocationRequest.fromJson(Map<String, dynamic> json) {
    return PendingLocationRequest(
      id: jsonInt(json['request_id'] ?? json['id']) ?? 0,
      name: jsonString(json['name']) ?? '',
      zone: ResidenceZone.fromApi(json['zone']),
      status: LocationRequestStatus.fromApi(json['status']),
    );
  }

  final int id;
  final String name;
  final ResidenceZone zone;
  final LocationRequestStatus status;

  Map<String, dynamic> toJson() {
    return {
      'request_id': id,
      'name': name,
      'zone': zone.apiValue,
      'status': status.apiValue,
    };
  }
}

/// Response ของ `/api/dashboard`
class DashboardSummary {
  const DashboardSummary({
    required this.user,
    required this.counts,
    this.recentListings = const <Product>[],
    this.recentOrders = const <Order>[],
    this.pendingLocationRequest,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final pending = json['pending_location_request'];
    return DashboardSummary(
      user: User.fromJson(jsonObject(json['user'])),
      counts: DashboardCounts.fromJson(jsonObject(json['counts'])),
      recentListings: jsonParseList(json['recent_listings'], Product.fromJson),
      recentOrders: jsonParseList(json['recent_orders'], Order.fromJson),
      pendingLocationRequest: pending is Map
          ? PendingLocationRequest.fromJson(Map<String, dynamic>.from(pending))
          : null,
    );
  }

  final User user;
  final DashboardCounts counts;
  final List<Product> recentListings;
  final List<Order> recentOrders;
  final PendingLocationRequest? pendingLocationRequest;
}

/// ตัวเลขสรุปใน `/api/admin/dashboard`
class AdminOverview {
  const AdminOverview({
    this.usersTotal = 0,
    this.usersPending = 0,
    this.itemsLive = 0,
    this.itemsPending = 0,
    this.locationsPending = 0,
    this.categoriesActive = 0,
  });

  factory AdminOverview.fromJson(Map<String, dynamic> json) {
    return AdminOverview(
      usersTotal: jsonInt(json['users_total']) ?? 0,
      usersPending: jsonInt(json['users_pending']) ?? 0,
      itemsLive: jsonInt(json['items_live']) ?? 0,
      itemsPending: jsonInt(json['items_pending']) ?? 0,
      locationsPending: jsonInt(json['locations_pending']) ?? 0,
      categoriesActive: jsonInt(json['categories_active']) ?? 0,
    );
  }

  final int usersTotal;
  final int usersPending;
  final int itemsLive;
  final int itemsPending;
  final int locationsPending;
  final int categoriesActive;

  Map<String, dynamic> toJson() {
    return {
      'users_total': usersTotal,
      'users_pending': usersPending,
      'items_live': itemsLive,
      'items_pending': itemsPending,
      'locations_pending': locationsPending,
      'categories_active': categoriesActive,
    };
  }
}

/// Response ของ `/api/admin/dashboard`
class AdminDashboard {
  const AdminDashboard({
    required this.overview,
    this.pendingListings = const <Product>[],
    this.pendingLocationRequests = const <LocationRequest>[],
  });

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    return AdminDashboard(
      overview: AdminOverview.fromJson(jsonObject(json['overview'])),
      pendingListings: jsonParseList(
        json['pending_listings'],
        Product.fromJson,
      ),
      pendingLocationRequests: jsonParseList(
        json['pending_location_requests'],
        LocationRequest.fromJson,
      ),
    );
  }

  final AdminOverview overview;
  final List<Product> pendingListings;
  final List<LocationRequest> pendingLocationRequests;
}
