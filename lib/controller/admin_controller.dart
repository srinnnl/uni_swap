import 'api_client.dart';

/// Admin queues and moderation operations exposed by the Express API.
class AdminController {
  AdminController(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> dashboard() => _api.get('admin/dashboard');

  Future<Map<String, dynamic>> users({
    String? status,
    int page = 1,
    int limit = 20,
  }) => _api.get(
    'admin/users',
    query: {'status': status, 'page': page, 'limit': limit},
  );

  Future<Map<String, dynamic>> setUserStatus(int userId, String status) =>
      _api.put('admin/users/$userId/status', body: {'status': status});

  Future<Map<String, dynamic>> listings({
    String status = 'pending_review',
    int page = 1,
    int limit = 20,
  }) => _api.get(
    'admin/listings',
    query: {'status': status, 'page': page, 'limit': limit},
  );

  Future<Map<String, dynamic>> reviewListing(
    int productId, {
    required String action,
    String? note,
    String? rejectReason,
  }) => _api.put(
    'admin/listings/$productId/review',
    body: {
      'action': action,
      'review_note': note,
      'reject_reason': rejectReason,
    },
  );

  Future<Map<String, dynamic>> reports({int page = 1, int limit = 20}) =>
      _api.get('admin/reports', query: {'page': page, 'limit': limit});

  Future<Map<String, dynamic>> resolveReport(
    int reportId, {
    required String status,
    String? note,
    bool hideProduct = false,
  }) => _api.put(
    'admin/reports/$reportId',
    body: {'status': status, 'admin_note': note, 'hide_product': hideProduct},
  );

  Future<Map<String, dynamic>> categories() => _api.get('admin/categories');
  Future<Map<String, dynamic>> createCategory({
    required String name,
    String emoji = '🏷️',
    bool active = true,
  }) => _api.post(
    'admin/categories',
    body: {'name': name, 'emoji': emoji, 'is_active': active},
  );
  Future<Map<String, dynamic>> updateCategory(
    int id, {
    required String name,
    required String emoji,
    required bool active,
  }) => _api.put(
    'admin/categories/$id',
    body: {'name': name, 'emoji': emoji, 'is_active': active},
  );

  Future<Map<String, dynamic>> locations({String? zone}) =>
      _api.get('admin/locations', query: {'zone': zone});
  Future<Map<String, dynamic>> createLocation({
    required String name,
    required String zone,
  }) => _api.post('admin/locations', body: {'name': name, 'zone': zone});
  Future<Map<String, dynamic>> updateLocation(
    int id, {
    required String name,
    required bool active,
  }) => _api.put(
    'admin/locations/$id',
    body: {'name': name, 'is_active': active},
  );

  Future<Map<String, dynamic>> locationRequests({
    String? status,
    int page = 1,
    int limit = 20,
  }) => _api.get(
    'admin/location-requests',
    query: {'status': status, 'page': page, 'limit': limit},
  );

  Future<Map<String, dynamic>> reviewLocationRequest(
    int requestId, {
    required String action,
    int? mergeIntoLocationId,
  }) => _api.put(
    'admin/location-requests/$requestId/review',
    body: {'action': action, 'merge_into_location_id': mergeIntoLocationId},
  );
}
