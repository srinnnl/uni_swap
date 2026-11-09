// ตัวช่วยแสดงผลที่ใช้ร่วมกันทุกหน้า (เดิมแต่ละไฟล์ copy ฟังก์ชันของตัวเอง)

/// ราคาแบบ DECIMAL(10,2): ไม่มีเศษแสดงเป็นจำนวนเต็ม (45), มีเศษแสดงสองตำแหน่ง (12.50)
/// เดิมใช้ toStringAsFixed(0) ทำให้ 12.50 กลายเป็น "13"
String formatPrice(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

/// เช่น "45 THB" หรือ "Free" เมื่อราคา 0
String formatPriceTHB(double v) => v == 0 ? 'Free' : '${formatPrice(v)} THB';

/// รหัสออเดอร์ที่แสดงให้ผู้ใช้ จาก orders.order_id (int)
String orderLabel(int orderId) => '#US-$orderId';
