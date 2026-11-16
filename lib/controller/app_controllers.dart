import 'package:http/http.dart' as http;

import 'admin_controller.dart';
import 'api_client.dart';
import 'auth_controller.dart';
import 'order_controller.dart';
import 'product_controller.dart';

/// Shared controller instances for the current single-session app flow.
/// A provider-based scope can replace this when the frontend grows.
///
/// ตัวแปรเป็น `late` (ไม่ใช่ final) และมีค่าเริ่มต้นแบบ lazy เพื่อให้
///  - แอปจริงใช้ได้เลยโดยไม่ต้องทำอะไร
///  - widget test เรียก [setupControllers] ใส่ `MockClient` แทน HTTP จริงได้
late ApiClient apiClient = ApiClient(tokenProvider: () => authController.token);
late AuthController authController = AuthController(apiClient);
late ProductController productController = ProductController(apiClient);
late OrderController orderController = OrderController(apiClient);
late AdminController adminController = AdminController(apiClient);

/// สร้าง controller ทั้งหมดใหม่ (state ล้างหมด เช่น token หาย)
///
/// ใช้ใน `main()` และใน widget test:
/// ```dart
/// setUp(() => setupControllers(client: MockClient((req) async =>
///     http.Response('{"success": true, "data": []}', 200))));
/// ```
void setupControllers({http.Client? client, String? baseUrl}) {
  apiClient = ApiClient(
    client: client,
    baseUrl: baseUrl,
    tokenProvider: () => authController.token,
  );
  authController = AuthController(apiClient);
  productController = ProductController(apiClient);
  orderController = OrderController(apiClient);
  adminController = AdminController(apiClient);
}
