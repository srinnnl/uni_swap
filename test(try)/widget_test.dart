// นำเข้าแพ็กเกจ Material Design ของ Flutter สำหรับสร้างโครงสร้าง UI พื้นฐาน (เช่น MaterialApp)
import 'package:flutter/material.dart';
// นำเข้าแพ็กเกจหลักสำหรับการเขียน Test (รวมถึงฟังก์ชัน testWidgets และ WidgetTester)
import 'package:flutter_test/flutter_test.dart';
// นำเข้าหน้าจอ LoginPage ที่ต้องการนำมาทดสอบการแสดงผล
import 'package:uni_swap/view/login.dart';

void main() {
  // =========================================================================
  // Widget Test: ทดสอบการเรนเดอร์ (แสดงผล) หน้าจอเข้าสู่ระบบ (LoginPage)
  // =========================================================================
  testWidgets('renders the login screen', (tester) async {
    // จำลองการเปิดหน้า LoginPage ขึ้นมาบนหน้าจอทดสอบ (ครอบด้วย MaterialApp เพื่อให้มี Theme และ Navigator พื้นฐาน)
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    // ตรวจสอบว่าบนหน้าจอมีข้อความ 'UniSwap' แสดงอยู่ 1 แห่งถ้วน
    expect(find.text('UniSwap'), findsOneWidget);
    // ตรวจสอบว่าบนหน้าจอมีข้อความต้อนรับ 'Welcome back' แสดงอยู่ 1 แห่งถ้วน
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
