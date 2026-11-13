import 'package:flutter/material.dart';
import 'package:uni_swap/model/format.dart';
import 'package:uni_swap/model/order_status.dart';
import 'package:uni_swap/view/user/arrange_meetup_page.dart';
import 'package:uni_swap/view/user/payment_page.dart';

// หน้ารายละเอียดออเดอร์ (เปิดจากการกดรายการในหน้า Orders)
// ปิดหน้าแล้วจะ pop กลับพร้อมผลล่าสุด (OrderResult: สถานะ + จุดนัด) ให้หน้า Orders อัปเดตตาม
//
// flow ตาม DB (orders.status):
//   pending_payment -> ready_for_meetup -> completed
//   แตกแขนง: cancelled (ก่อนจ่าย), expired (เลย payment_deadline)
// ไม่มีขั้นผู้ขายตอบรับ/ปฏิเสธ: ผู้ซื้อกด Buy now แล้วออเดอร์เริ่มที่ pending_payment ทันที

class _C {
  static const bg = Color(0xFFFAF9F6);
  static const ink = Color(0xFF2F2F2B);
  static const muted = Color(0xFF7A7973);
  static const faint = Color(0xFFA9A8A2);
  static const border = Color(0xFFE6E4DD);
  static const surface = Color(0xFFF3F2EE);
  static const sage = Color(0xFF3F6B52);
  static const sageBg = Color(0xFFD8E4DC);
  static const blueBg = Color(0xFFE3ECF7);
  static const blueFg = Color(0xFF3B5E8C);
  static const amberBg = Color(0xFFFBEBC2);
  static const amberFg = Color(0xFF8A6410);
  static const redBg = Color(0xFFF8DADA);
  static const redFg = Color(0xFFB3402F);
  static const link = Color(0xFF4A5C8F);
}

/// ผลที่ส่งกลับหน้า Orders ตอนปิดหน้ารายละเอียด
class OrderResult {
  const OrderResult({
    required this.status,
    required this.meetupPlace,
    this.meetupAt,
  });

  final OrderStatus status;
  final String meetupPlace;
  final DateTime? meetupAt;
}

class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({
    super.key,
    required this.orderId,
    required this.title,
    required this.price,
    required this.person,
    required this.isBuying,
    required this.status,
    required this.createdLabel,
    required this.meetupPlace,
    required this.productLocation,
    required this.commissionRate,
    required this.commissionAmount,
    required this.sellerPayout,
    this.meetupAt,
    this.paymentDeadline, // orders.payment_deadline (null = ไม่แสดงตัวนับเวลา)
    this.imageUrl,
  });

  final int orderId; // orders.order_id
  final String title;
  final double price; // orders.seller_price (ผู้ซื้อจ่ายเท่านี้)
  final String person; // ผู้ขาย (ถ้าเรากำลังซื้อ) หรือ ผู้ซื้อ (ถ้าเรากำลังขาย)
  final bool isBuying;
  final OrderStatus status;
  final String createdLabel; // จาก orders.created_at
  final String meetupPlace; // orders.meetup_location (NOT NULL ใน DB)
  final DateTime? meetupAt; // orders.meetup_datetime
  final DateTime? paymentDeadline;
  final String productLocation; // products.location_name ใช้แนะนำจุดนัด
  // ตัวเลขคิดโดย backend ตอนสร้างออเดอร์ แอปแสดงอย่างเดียว ไม่คำนวณเอง
  // TODO: ยืนยันกับเพื่อนว่า commission_rate เก็บเป็นเปอร์เซ็นต์ (5.00) และหักจากผู้ขาย
  final double commissionRate; // orders.commission_rate
  final double commissionAmount; // orders.commission_amount
  final double sellerPayout; // orders.seller_payout
  final String? imageUrl;

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late OrderStatus _raw = widget.status;
  late String _meetupPlace = widget.meetupPlace;
  late DateTime? _meetupAt = widget.meetupAt;

  // เลย payment_deadline แล้วยังไม่จ่าย ถือว่า expired (backend เป็นคนเปลี่ยนจริง)
  OrderStatus get _status {
    final due = widget.paymentDeadline;
    if (_raw == OrderStatus.pendingPayment &&
        due != null &&
        !due.isAfter(DateTime.now())) {
      return OrderStatus.expired;
    }
    return _raw;
  }

  bool get _completed => _status == OrderStatus.completed;
  bool get _paid => _status.isPaid;
  // สินค้าฟรี (ราคา 0) ไม่มีขั้นจ่ายเงิน (payment_method = 'free')
  bool get _needsPayment => widget.price > 0;
  String get _priceText => formatPriceTHB(widget.price);
  String get _orderLabel => orderLabel(widget.orderId);

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  // Payment is persisted by the demo API; meetup, receipt, and cancellation
  // remain local UI actions until their endpoints are connected.

  Future<void> _arrange() async {
    final r = await Navigator.push<MeetupChoice>(
      context,
      MaterialPageRoute(
        builder: (_) => ArrangeMeetupPage(
          productTitle: widget.title,
          price: widget.price,
          sellerName: widget.person,
          sellerLocation: widget.productLocation,
          initialWhen: _meetupAt,
        ),
      ),
    );
    if (r == null || !mounted) return;
    // TODO: API แก้ orders.meetup_location / meetup_datetime (ถามเพื่อนว่ามี endpoint ไหม)
    setState(() {
      _meetupAt = r.when;
    });
    _toast('Meet-up updated');
  }

  Future<void> _pay() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          orderId: widget.orderId,
          title: widget.title,
          price: widget.price,
          sellerName: widget.person,
          imageUrl: widget.imageUrl,
          paid: _paid,
          paymentDeadline: widget.paymentDeadline,
        ),
      ),
    );
    if (ok == true && mounted) {
      setState(() => _raw = OrderStatus.readyForMeetup);
      _toast('Demo payment recorded; no money was transferred');
    }
  }

  Future<bool> _confirm(
    String title,
    String message,
    String action, {
    bool danger = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.bg,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: danger ? _C.redFg : _C.ink,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true && mounted;
  }

  Future<void> _confirmReceived() async {
    final ok = await _confirm(
      'Confirm received?',
      'Only confirm after you have the item in hand. '
          "This will record the handover and the seller's estimated payout. "
          'No real money is transferred in the demo.',
      'Yes, I got it',
    );
    if (!ok) return;
    // TODO: call the receive endpoint and refresh the order from the server.
    setState(() => _raw = OrderStatus.completed);
  }

  // ยกเลิกก่อนจ่าย: orders.status='cancelled' และสินค้ากลับเป็น available
  Future<void> _cancelOrder() async {
    final ok = await _confirm(
      'Cancel this order?',
      'The item will be available to other buyers again.',
      'Cancel order',
      danger: true,
    );
    if (!ok) return;
    // TODO: API ยกเลิกออเดอร์
    setState(() => _raw = OrderStatus.cancelled);
  }

  void _close() => Navigator.pop(
    context,
    OrderResult(status: _raw, meetupPlace: _meetupPlace, meetupAt: _meetupAt),
  );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: _C.bg,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildOrderCard(),
              const SizedBox(height: 16),
              _buildStatusCard(),
              if (!widget.isBuying && _completed && _needsPayment) ...[
                const SizedBox(height: 16),
                _buildReceipt(),
              ],
              if (_meetupAt != null && (_status.isActive || _completed)) ...[
                const SizedBox(height: 16),
                _buildMeetupCard(),
              ],
              const SizedBox(height: 16),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // ผู้ซื้อยกเลิกได้ก่อนจ่าย
    final canCancel = widget.isBuying && _status == OrderStatus.pendingPayment;
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.arrow_back), onPressed: _close),
        Expanded(
          child: Column(
            children: [
              const Text(
                'Order details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _C.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _orderLabel,
                style: const TextStyle(fontSize: 13, color: _C.muted),
              ),
            ],
          ),
        ),
        if (canCancel)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: _C.ink),
            color: Colors.white,
            onSelected: (_) => _cancelOrder(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'cancel', child: Text('Cancel order')),
            ],
          ),
      ],
    );
  }

  (String, Color, Color) get _badge => switch (_status.tone) {
    StatusTone.amber => (_status.label, _C.amberBg, _C.amberFg),
    StatusTone.blue => (_status.label, _C.blueBg, _C.blueFg),
    StatusTone.green => (_status.label, _C.sageBg, _C.sage),
    StatusTone.red => (_status.label, _C.redBg, _C.redFg),
  };

  Widget _box({required Widget child, EdgeInsets? padding}) => Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _C.border),
    ),
    child: child,
  );

  Widget _buildOrderCard() {
    final (label, bg, fg) = _badge;
    return _box(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 80,
              height: 90,
              child: widget.imageUrl == null
                  ? Container(
                      color: _C.surface,
                      child: const Icon(Icons.image_outlined, color: _C.faint),
                    )
                  : Image.network(
                      widget.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _C.surface,
                        child: const Icon(
                          Icons.image_outlined,
                          color: _C.faint,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _C.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_priceText · ${widget.isBuying ? 'Seller' : 'Buyer'}: '
                  '${widget.person}',
                  style: const TextStyle(fontSize: 12, color: _C.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ใบเสร็จผู้ขาย: ราคาสินค้า - ค่าธรรมเนียม UniSwap = ยอดที่ได้รับ
  // ตัวเลขทั้งหมดมาจาก orders (commission_*, seller_payout) ไม่คำนวณในแอป
  Widget _buildReceipt() {
    String money(double v) => '${v.toStringAsFixed(2)} THB';

    Widget row(
      String label,
      String value, {
      bool strong = false,
      Color? color,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: strong ? 14 : 13,
                fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
                color: strong ? _C.ink : _C.muted,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: strong ? 17 : 13,
                fontWeight: FontWeight.w700,
                color: color ?? _C.ink,
              ),
            ),
          ],
        ),
      );
    }

    return _box(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_outlined, size: 18, color: _C.sage),
              SizedBox(width: 8),
              Text(
                'Receipt',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _C.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          row('Item price', money(widget.price)),
          const Divider(height: 1, color: _C.border),
          row(
            'UniSwap fee (${formatPrice(widget.commissionRate)}%)',
            '- ${money(widget.commissionAmount)}',
          ),
          const Divider(height: 1, color: _C.border),
          row(
            'You receive',
            money(widget.sellerPayout),
            strong: true,
            color: _C.sage,
          ),
          const SizedBox(height: 2),
          Text(
            'Demo payout only; no bank transfer is made · Order $_orderLabel',
            style: const TextStyle(fontSize: 11, color: _C.muted),
          ),
        ],
      ),
    );
  }

  // ===== สถานะออเดอร์แบบเส้นเวลา =====
  Widget _buildStatusCard() {
    final deadline = widget.paymentDeadline;
    final meetupText = _meetupAt == null
        ? _meetupPlace
        : '${_formatDay(_meetupAt!)} · '
              '${_formatTime(TimeOfDay.fromDateTime(_meetupAt!))}';
    final paymentText = !_needsPayment
        ? 'Free item · no payment needed'
        : _paid
        ? 'Marked paid (demo; no funds transferred)'
        : deadline != null
        ? 'Pay before ${_formatTime(TimeOfDay.fromDateTime(deadline))}'
        : 'Waiting for payment';
    final steps = <_Step>[
      _Step('Order placed', widget.createdLabel, true),
      if (_needsPayment) _Step('Payment', paymentText, _paid),
      _Step(
        'Meet-up',
        meetupText,
        _status == OrderStatus.readyForMeetup || _completed,
      ),
      _Step(
        'Completed',
        _completed
            ? (_needsPayment
                  ? 'Confirmed · demo payout recorded'
                  : 'Confirmed · handover done')
            : 'Confirm after handover',
        _completed,
      ),
    ];

    return _box(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order status',
            style: TextStyle(fontSize: 16, color: _C.ink),
          ),
          const SizedBox(height: 18),
          if (_hasSpecialStatus)
            _buildSpecialStatus()
          else
            for (var i = 0; i < steps.length; i++)
              _buildStep(i, steps[i], last: i == steps.length - 1),
        ],
      ),
    );
  }

  // สถานะที่ออกนอกเส้นทางหลัก (ไม่แสดงเป็นเส้นเวลา)
  bool get _hasSpecialStatus => switch (_status) {
    OrderStatus.cancelled || OrderStatus.expired => true,
    _ => false,
  };

  Widget _buildSpecialStatus() {
    final (
      IconData icon,
      Color color,
      String title,
      String detail,
    ) = switch (_status) {
      OrderStatus.cancelled => (
        Icons.cancel_outlined,
        _C.redFg,
        'This order was cancelled',
        'The item is available to other buyers again.',
      ),
      OrderStatus.expired => (
        Icons.timer_off_outlined,
        _C.redFg,
        'Payment time ran out',
        'This order expired and the item is available again.',
      ),
      _ => (
        Icons.timer_off_outlined,
        _C.redFg,
        'Payment time ran out',
        'This order expired and the item is available again.',
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(detail, style: const TextStyle(fontSize: 12, color: _C.muted)),
      ],
    );
  }

  Widget _buildStep(int i, _Step s, {required bool last}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: s.done ? _C.sageBg : Colors.white,
                    border: s.done ? null : Border.all(color: _C.border),
                  ),
                  child: s.done
                      ? const Icon(Icons.check, size: 16, color: _C.sage)
                      : Text(
                          '${i + 1}',
                          style: const TextStyle(fontSize: 11, color: _C.faint),
                        ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: s.done ? _C.sageBg : _C.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _C.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    s.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: s.done ? _C.sage : _C.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetupCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: _C.ink,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Meet-up',
                  style: TextStyle(fontSize: 11, color: _C.muted),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatDay(_meetupAt!)} · '
                  '${_formatTime(TimeOfDay.fromDateTime(_meetupAt!))}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _meetupPlace,
                  style: const TextStyle(fontSize: 11, color: _C.muted),
                ),
              ],
            ),
          ),
          // แก้จุดนัดได้เฉพาะผู้ซื้อ และก่อนจ่ายเงินเท่านั้น
          if (widget.isBuying && _status == OrderStatus.pendingPayment)
            GestureDetector(
              onTap: _arrange,
              child: const Text(
                'Edit',
                style: TextStyle(
                  fontSize: 12,
                  color: _C.link,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===== ปุ่มด้านล่าง: ปุ่มหลักเปลี่ยนตาม "ขั้นตอนถัดไป" ของผู้ซื้อ =====
  Widget _buildActions() {
    final primary = _primaryAction();

    return Row(
      children: [
        if (primary != null) ...[
          Expanded(child: primary),
          const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget? _primaryAction() {
    // ผู้ขายไม่มีปุ่มหลัก: completed เกิดจากผู้ซื้อกด Confirm received เท่านั้น
    if (!widget.isBuying) return null;

    String label;
    VoidCallback? onTap;
    IconData? icon;

    switch (_status) {
      case OrderStatus.pendingPayment:
        label = _needsPayment ? 'Pay $_priceText' : 'Confirm free order';
        icon = Icons.credit_card_outlined;
        onTap = _pay;
      case OrderStatus.paid || OrderStatus.readyForMeetup:
        label = 'Confirm received';
        icon = Icons.check_circle_outline;
        onTap = _confirmReceived;
      default:
        return null;
    }

    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: FilledButton.styleFrom(
          backgroundColor: _C.ink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _C.border,
          disabledForegroundColor: _C.muted,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _Step {
  const _Step(this.title, this.subtitle, this.done);
  final String title;
  final String subtitle;
  final bool done;
}

String _formatDay(DateTime d) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
  return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
}

String _formatTime(TimeOfDay t) {
  final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
}
