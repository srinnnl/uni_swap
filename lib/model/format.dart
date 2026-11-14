// ตัวช่วยแสดงผลที่ใช้ร่วมกันทุกหน้า (เดิมแต่ละไฟล์ copy ฟังก์ชันของตัวเอง)

/// ราคาแบบ DECIMAL(10,2): ไม่มีเศษแสดงเป็นจำนวนเต็ม (45), มีเศษแสดงสองตำแหน่ง (12.50)
/// เดิมใช้ toStringAsFixed(0) ทำให้ 12.50 กลายเป็น "13"
String formatPrice(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

/// เช่น "45 THB" หรือ "Free" เมื่อราคา 0
String formatPriceTHB(double v) => v == 0 ? 'Free' : '${formatPrice(v)} THB';

/// รหัสออเดอร์ที่แสดงให้ผู้ใช้ จาก orders.order_id (int)
String orderLabel(int orderId) => '#US-$orderId';

/// เวลาแบบสั้น เช่น "just now", "12 min ago", "3 h ago", "2 d ago" (เกิน 30 วันแสดงวันที่)
/// คืนค่าว่างถ้าไม่มีเวลา
String timeAgo(DateTime? time, {DateTime? now}) {
  if (time == null) return '';
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays <= 30) return '${diff.inDays} d ago';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[time.month - 1]} ${time.day}, ${time.year}';
}

const _shortMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// เวลาแบบ 12 ชั่วโมง เช่น "2:30 PM"
String formatClock(DateTime t) {
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${t.hour < 12 ? 'AM' : 'PM'}';
}

/// วันที่ + เวลา เช่น "Nov 15 · 2:30 PM" (ส่ง DateTime ที่เป็นเวลาท้องถิ่นแล้ว)
String formatWhen(DateTime t) =>
    '${_shortMonths[t.month - 1]} ${t.day} · ${formatClock(t)}';
