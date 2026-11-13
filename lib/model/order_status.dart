// สถานะออเดอร์และสินค้า ตรงกับ enum ใน project_mobile_app.sql
// ใช้ร่วมกันทุกหน้า (เดิมแต่ละหน้ามี enum ของตัวเอง แล้วแปลงกันด้วย index)

/// โทนสีของป้ายสถานะ (แต่ละหน้าแปลงเป็นสีของตัวเอง)
enum StatusTone { amber, blue, green, red }

/// orders.status
enum OrderStatus {
  pendingPayment('pending_payment'),
  paid('paid'),
  readyForMeetup('ready_for_meetup'),
  completed('completed'),
  cancelled('cancelled'),
  expired('expired');

  const OrderStatus(this.apiValue);

  /// ค่าที่ส่ง/รับกับ API (ตรงกับ enum ใน DB)
  final String apiValue;

  static OrderStatus? tryParse(Object? value) {
    for (final status in OrderStatus.values) {
      if (status.apiValue == value) return status;
    }
    return null;
  }

  static OrderStatus fromApi(String value) =>
      tryParse(value) ?? OrderStatus.pendingPayment;

  /// ออเดอร์ที่ยังดำเนินอยู่ (แสดงในส่วนบนของหน้า Orders)
  bool get isActive =>
      this == pendingPayment || this == paid || this == readyForMeetup;

  /// จ่ายเงินเข้า UniSwap แล้ว (เงินถูกพักไว้หรือจ่ายต่อให้ผู้ขายแล้ว)
  bool get isPaid =>
      this == paid || this == readyForMeetup || this == completed;

  /// ผู้ซื้อกด Confirm received ได้ในสถานะนี้
  bool get canConfirmReceived => this == paid || this == readyForMeetup;

  /// ข้อความบนป้ายสถานะ
  String get label => switch (this) {
    pendingPayment => 'Awaiting payment',
    paid => 'Paid',
    readyForMeetup => 'Ready to meet',
    completed => 'Completed',
    cancelled => 'Cancelled',
    expired => 'Expired',
  };

  StatusTone get tone => switch (this) {
    pendingPayment => StatusTone.amber,
    paid || readyForMeetup => StatusTone.blue,
    completed => StatusTone.green,
    cancelled || expired => StatusTone.red,
  };
}

/// products.status
enum ProductStatus {
  pendingReview('pending_review'),
  changesRequested('changes_requested'),
  rejected('rejected'),
  available('available'),
  reserved('reserved'),
  sold('sold'),
  hidden('hidden');

  const ProductStatus(this.apiValue);

  final String apiValue;

  static ProductStatus? tryParse(Object? value) {
    for (final status in ProductStatus.values) {
      if (status.apiValue == value) return status;
    }
    return null;
  }

  static ProductStatus fromApi(String value) =>
      tryParse(value) ?? ProductStatus.available;
}

/// อายุของออเดอร์ก่อนต้องจ่ายเงิน (orders.payment_deadline = created_at + 30 นาที)
/// TODO: backend เป็นคนตั้งค่านี้ แอปใช้แค่ในข้อมูลจำลอง
const kPaymentWindow = Duration(minutes: 30);
