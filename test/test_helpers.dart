//ตัวช่วยจำลอง fakeApi และเก็บประวัติ RecordedCall ให้ไฟล์เทสต์ของ Controller นำไปเรียกใช้

// นำเข้าไลบรารีสำหรับแปลงข้อมูลระหว่าง JSON String กับออบเจกต์ใน Dart (jsonEncode / jsonDecode)
import 'dart:convert';

// นำเข้าแพ็กเกจ http และ MockClient สำหรับจำลองการรับ-ส่ง HTTP Request โดยไม่ต้องต่อเน็ตจริง
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
// นำเข้าคลาส ApiClient หลักของแอปพลิเคชัน
import 'package:uni_swap/controller/api_client.dart';

/// request ที่ controller ส่งออกไป (บันทึกไว้ให้เทสต์ตรวจ)
// คลาสโมเดลสำหรับเก็บรายละเอียดของ HTTP Request แต่ละครั้งที่ถูกยิงออกมา เพื่อนำไปตรวจสอบใน Unit Test
class RecordedCall {
  RecordedCall({
    required this.method,
    required this.path,
    required this.query,
    required this.body,
    required this.headers,
  });

  final String method; // ประเภท HTTP Method เช่น GET, POST, PUT, DELETE
  final String path; // เส้นทาง URL ปลายทาง เช่น /api/products
  final Map<String, String> query; // พารามิเตอร์ต่อท้าย URL (Query String)
  final Map<String, dynamic>?
  body; // ข้อมูล JSON ที่ส่งแนบไปใน Request Body (ถ้ามี)
  final Map<String, String>
  headers; // ข้อมูล HTTP Headers เช่น Authorization, Content-Type

  /// เช่น `PUT /api/admin/users/5/status`
  // ตัวช่วยรวม Method และ Path เข้าด้วยกันเป็นข้อความเดียว เพื่อให้อ่านและตรวจสอบในเทสต์ได้ง่ายขึ้น
  String get label => '$method $path';
}

/// สร้าง [ApiClient] ที่ไม่ต่อ server จริง
///
/// - ทุก request ถูกเก็บลง [calls]
/// - server ปลอมตอบ [response] (ถูกแปลงเป็น JSON) พร้อม status [status]
// ฟังก์ชันโรงงาน (Factory Helper) สำหรับสร้าง ApiClient จำลองที่ใช้ทดสอบ Controller ต่างๆ
ApiClient fakeApi(
  List<RecordedCall>
  calls, { // ลิสต์สำหรับบันทึกประวัติการเรียก API ทั้งหมดที่เกิดขึ้น
  int status =
      200, // รหัส HTTP Status Code จำลองที่ต้องการให้ Server ตอบกลับ (ค่าเริ่มต้นคือ 200 OK)
  Object? response = const {
    'success': true,
  }, // ข้อมูลจำลองที่จะถูกแปลงเป็น JSON ส่งกลับมาเป็น Response Body
  String? Function()?
  tokenProvider, // ฟังก์ชันจำลองสำหรับดึง Token ยืนยันตัวตน (ถ้าต้องการทดสอบการแนบ Token)
}) {
  return ApiClient(
    tokenProvider: tokenProvider,
    // ใช้ MockClient ดักจับทุก Request ที่ออกจาก ApiClient แทนการยิงออกไปที่เครือข่ายจริง
    client: MockClient((request) async {
      // บันทึกรายละเอียดของ Request ที่ถูกดักจับได้ลงในรายการ calls
      calls.add(
        RecordedCall(
          method: request.method,
          path: request.url.path,
          query: request.url.queryParameters,
          // ถ้า Request Body ว่างเปล่าให้เก็บเป็น null แต่ถ้ามีข้อมูลให้แปลง JSON String กลับเป็น Map
          body: request.body.isEmpty
              ? null
              : jsonDecode(request.body) as Map<String, dynamic>,
          headers: request.headers,
        ),
      );
      // ส่งคำตอบจำลองกลับไปให้ ApiClient ในรูปแบบ JSON String พร้อมรหัส Status ที่กำหนดไว้
      return http.Response(jsonEncode(response), status);
    }),
  );
}
