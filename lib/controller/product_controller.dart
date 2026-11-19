import 'api_client.dart';

/// Product catalog and seller listing actions backed by app.js routes.
class ProductController {
  ProductController(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> browse({
    String? keyword,
    int? categoryId,
    String? zone,
    int? locationId,
    String sort = 'newest',
    int page = 1,
    int limit = 20,
  }) => _api.get(
    'products',
    query: {
      'keyword': keyword,
      'category_id': categoryId,
      'zone': zone,
      'location_id': locationId,
      'sort': sort,
      'page': page,
      'limit': limit,
    },
  );

  Future<List<Map<String, dynamic>>> categories() async =>
      _rows(await _api.get('categories'));

  Future<List<Map<String, dynamic>>> locations({String? zone}) async =>
      _rows(await _api.get('locations', query: {'zone': zone}));

  /// ขอเพิ่มที่พักที่ยังไม่มีในรายการ (ต้อง login) -> POST /api/location-requests
  /// server ตอบ 201 { success, request_id, status: 'pending' }
  Future<Map<String, dynamic>> requestLocation({
    required String name,
    required String zone,
    String? address,
    String? reason,
  }) => _api.post(
    'location-requests',
    body: {
      'name': name,
      'zone': zone,
      if (address != null && address.isNotEmpty) 'address': address,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    },
  );

  /// โปรไฟล์ผู้ขาย + สินค้า available ของเขา -> GET /api/sellers/:user_id
  /// ตอบ { success, data: { seller, items }, page, limit, has_more }
  Future<Map<String, dynamic>> seller(
    int userId, {
    int page = 1,
    int limit = 20,
  }) => _api.get('sellers/$userId', query: {'page': page, 'limit': limit});

  /// สรุปของฉัน (counts: my_listings, sold_listings, ...) -> GET /api/dashboard
  Future<Map<String, dynamic>> myDashboard() => _api.get('dashboard');

  Future<Map<String, dynamic>> detail(int productId) =>
      _api.get('products/$productId');

  /// Private pickup instructions shown after a buyer starts checkout.
  Future<Map<String, dynamic>> pickupDetail(int productId) =>
      _api.get('products/$productId/pickup-detail');

  Future<Map<String, dynamic>> myListings({int page = 1, int limit = 20}) =>
      _api.get('my/listings', query: {'page': page, 'limit': limit});

  Future<Map<String, dynamic>> create(Map<String, Object?> listing) =>
      _api.post('products', body: listing);

  Future<Map<String, dynamic>> update(
    int productId,
    Map<String, Object?> listing,
  ) => _api.put('products/$productId', body: listing);

  Future<Map<String, dynamic>> deleteUnreviewed(int productId) =>
      _api.delete('products/$productId');

  Future<Map<String, dynamic>> hideAvailable(int productId) =>
      _api.put('products/$productId/hide');

  Future<Map<String, dynamic>> addImage(
    int productId,
    String imageUrl, {
    int displayOrder = 1,
  }) => _api.post(
    'products/$productId/images',
    body: {'image_url': imageUrl, 'display_order': displayOrder},
  );

  Future<Map<String, dynamic>> uploadImage(
    int productId, {
    required List<int> bytes,
    required String fileName,
    String? mimeType,
    required int displayOrder,
  }) => _api.postMultipart(
    'products/$productId/images',
    fileField: 'image',
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
    fields: {'display_order': '$displayOrder'},
  );
}

List<Map<String, dynamic>> _rows(Map<String, dynamic> response) =>
    (response['data'] as List? ?? const [])
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
