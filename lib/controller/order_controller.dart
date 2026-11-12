import 'api_client.dart';

/// Order and meetup actions implemented by the current Express API.
class OrderController {
  OrderController(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> list({int page = 1, int limit = 20}) =>
      _api.get('orders', query: {'page': page, 'limit': limit});

  Future<Map<String, dynamic>> create({
    required int productId,
    required String meetupLocation,
    DateTime? meetupDateTime,
  }) => _api.post(
    'orders',
    body: {
      'product_id': productId,
      'meetup_location': meetupLocation,
      'meetup_datetime': meetupDateTime?.toUtc().toIso8601String(),
    },
  );

  Future<Map<String, dynamic>> cancel(int orderId) =>
      _api.post('orders/$orderId/cancel');

  Future<Map<String, dynamic>> updateMeetup({
    required int orderId,
    required String location,
    DateTime? dateTime,
  }) => _api.put(
    'orders/$orderId/meetup',
    body: {
      'meetup_location': location,
      'meetup_datetime': dateTime?.toUtc().toIso8601String(),
    },
  );

  Future<Map<String, dynamic>> pay(
    int orderId, {
    String method = 'gateway',
    String? transactionRef,
    String? slipUrl,
  }) => _api.post(
    'orders/$orderId/pay',
    body: {
      'payment_method': method,
      'transaction_ref': transactionRef,
      'payment_slip_url': slipUrl,
    },
  );

  Future<Map<String, dynamic>> requestRefund(int orderId, String reason) =>
      _api.post('orders/$orderId/refunds', body: {'reason': reason});

  Future<Map<String, dynamic>> report({
    required int orderId,
    required String type,
    required String reason,
    String? evidenceUrl,
  }) => _api.post(
    'reports',
    body: {
      'order_id': orderId,
      'report_type': type,
      'reason': reason,
      'evidence_url': evidenceUrl,
    },
  );
}
