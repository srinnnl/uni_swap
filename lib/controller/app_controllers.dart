import 'admin_controller.dart';
import 'api_client.dart';
import 'auth_controller.dart';
import 'order_controller.dart';
import 'product_controller.dart';

/// Shared controller instances for the current single-session app flow.
/// A provider-based scope can replace this when the frontend grows.
final AuthController authController = AuthController(apiClient);
final ApiClient apiClient = ApiClient(
  tokenProvider: () => authController.token,
);
final ProductController productController = ProductController(apiClient);
final OrderController orderController = OrderController(apiClient);
final AdminController adminController = AdminController(apiClient);
