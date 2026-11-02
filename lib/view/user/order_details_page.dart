import 'package:flutter/material.dart';
import 'package:uni_swap/view/user/arrange_meetup_page.dart';
import 'package:uni_swap/view/user/chat_page.dart';
import 'package:uni_swap/view/user/payment_page.dart';

// หน้ารายละเอียดออเดอร์ (เปิดจากการกดรายการในหน้า Orders)
// ปิดหน้าแล้วจะ pop กลับพร้อมสถานะล่าสุด (OrderStage) ให้หน้า Orders อัปเดตตาม

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

/// สถานะหลักของออเดอร์ (ลำดับเดียวกับ _Status ในหน้า Orders)
enum OrderStage { pending, accepted, completed, cancelled }

class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({
    super.key,
    required this.orderId,
    required this.title,
    required this.price,
    required this.person,
    required this.isBuying,
    required this.stage,
    required this.requestedLabel,
    this.meetupPlace,
    this.meetupAt,
    this.paid = false,
    this.imageUrl,
    // TODO: ดึงที่พักของผู้ขายจาก API
    this.sellerLocation = 'North Campus · Maple Hall',
  });

  final String orderId;
  final String title;
  final double price;
  final String person; // ผู้ขาย (ถ้าเรากำลังซื้อ) หรือ ผู้ซื้อ (ถ้าเรากำลังขาย)
  final bool isBuying;
  final OrderStage stage;
  final String requestedLabel;
  final String? meetupPlace;
  final DateTime? meetupAt;
  final bool paid;
  final String? imageUrl;
  final String sellerLocation;

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late OrderStage _stage = widget.stage;
  late bool _paid = widget.paid;
  DateTime? _meetupAt;
  String? _meetupPlace;

  @override
  void initState() {
    super.initState();
    _meetupAt = widget.meetupAt;
    _meetupPlace = widget.meetupPlace;
  }

  String get _firstName => widget.person.trim().split(RegExp(r'\s+')).first;
  bool get _cancelled => _stage == OrderStage.cancelled;
  bool get _completed => _stage == OrderStage.completed;
  String get _priceText =>
      widget.price == 0 ? 'Free' : '\$${widget.price.toStringAsFixed(0)}';

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  // ===== การกระทำต่างๆ (ทั้งหมดเป็นข้อมูลจำลอง) =====
  // TODO: แต่ละฟังก์ชันด้านล่างให้เพื่อนต่อ API แล้วอัปเดตสถานะจากผลลัพธ์จริง

  Future<void> _arrange() async {
    final r = await Navigator.push<MeetupChoice>(
      context,
      MaterialPageRoute(
        builder: (_) => ArrangeMeetupPage(
          productTitle: widget.title,
          price: widget.price.round(),
          sellerName: widget.person,
          sellerLocation: widget.sellerLocation,
        ),
      ),
    );
    if (r == null || !mounted) return;
    setState(() {
      _meetupPlace = r.spot;
      _meetupAt = r.when;
    });
    _toast('Meet-up saved');
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
        ),
      ),
    );
    if (ok == true && mounted) {
      setState(() => _paid = true);
      _toast('Marked as paid');
    }
  }

  Future<bool> _confirm(String title, String message, String action,
      {bool danger = false}) async {
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
          'UniSwap will then release your payment to the seller.',
      'Yes, I got it',
    );
    if (ok) setState(() => _stage = OrderStage.completed);
  }

  Future<void> _cancelOrder() async {
    final ok = await _confirm(
      'Cancel this order?',
      'The other person will be notified.',
      'Cancel order',
      danger: true,
    );
    if (ok) setState(() => _stage = OrderStage.cancelled);
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          sellerName: widget.person,
          productTitle: widget.title,
          price: widget.price.round(),
          imageUrl: widget.imageUrl,
          // แชทของออเดอร์ที่จบแล้ว/ยกเลิกแล้ว อ่านได้อย่างเดียว
          ended: _completed || _cancelled,
        ),
      ),
    );
  }

  void _close() => Navigator.pop(context, _stage);

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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildOrderCard(),
              const SizedBox(height: 16),
              _buildStatusCard(),
              if (_meetupAt != null && !_cancelled) ...[
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
    final canCancel = widget.isBuying &&
        (_stage == OrderStage.pending || _stage == OrderStage.accepted);
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
                widget.orderId,
                style: const TextStyle(fontSize: 13, color: _C.muted),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz, color: _C.ink),
          color: Colors.white,
          onSelected: (v) {
            if (v == 'cancel') _cancelOrder();
            if (v == 'report') _toast('Report sent');
          },
          itemBuilder: (_) => [
            if (canCancel)
              const PopupMenuItem(value: 'cancel', child: Text('Cancel order')),
            const PopupMenuItem(value: 'report', child: Text('Report a problem')),
          ],
        ),
      ],
    );
  }

  (String, Color, Color) get _badge => switch (_stage) {
        OrderStage.pending => ('Pending', _C.amberBg, _C.amberFg),
        OrderStage.accepted => ('Accepted', _C.blueBg, _C.blueFg),
        OrderStage.completed => ('Completed', _C.sageBg, _C.sage),
        OrderStage.cancelled => ('Cancelled', _C.redBg, _C.redFg),
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
                        child:
                            const Icon(Icons.image_outlined, color: _C.faint),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  // ===== สถานะออเดอร์แบบเส้นเวลา =====
  Widget _buildStatusCard() {
    final accepted =
        _stage == OrderStage.accepted || _stage == OrderStage.completed;
    final steps = <_Step>[
      _Step('Order requested', widget.requestedLabel, true),
      _Step('Seller accepted',
          accepted ? 'Seller confirmed' : 'Waiting for seller', accepted),
      _Step(
        'Meet-up arranged',
        _meetupAt == null
            ? 'Not arranged yet'
            : '${_formatDay(_meetupAt!)} · ${_formatTime(TimeOfDay.fromDateTime(_meetupAt!))}',
        _meetupAt != null,
      ),
      _Step('Payment', _paid ? 'Paid to UniSwap (held safely)' : 'Waiting for payment',
          _paid),
      _Step(
          'Completed',
          _completed
              ? 'Confirmed · seller payout sent'
              : 'Confirm after handover',
          _completed),
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
          if (_cancelled)
            const Row(
              children: [
                Icon(Icons.cancel_outlined, color: _C.redFg),
                SizedBox(width: 12),
                Text(
                  'This order was cancelled',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _C.redFg,
                  ),
                ),
              ],
            )
          else
            for (var i = 0; i < steps.length; i++)
              _buildStep(i, steps[i], last: i == steps.length - 1),
        ],
      ),
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
                          style: const TextStyle(
                            fontSize: 11,
                            color: _C.faint,
                          ),
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
            child: const Icon(Icons.calendar_today_outlined,
                size: 20, color: _C.ink),
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
                if (_meetupPlace != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    _meetupPlace!,
                    style: const TextStyle(fontSize: 11, color: _C.muted),
                  ),
                ],
              ],
            ),
          ),
          if (!_completed)
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
        Expanded(
          child: SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: _openChat,
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: Text(
                'Chat with $_firstName',
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _C.ink,
                backgroundColor: Colors.white,
                side: const BorderSide(color: _C.border),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _primaryAction() {
    // ผู้ขายจัดการรับ/ปฏิเสธ/ปิดงานที่หน้ารายการ Orders อยู่แล้ว
    if (!widget.isBuying || _cancelled || _completed) return null;

    String label;
    VoidCallback? onTap;
    IconData? icon;

    if (_stage == OrderStage.pending) {
      label = 'Waiting for seller';
      onTap = null;
    } else if (_meetupAt == null) {
      label = 'Arrange meet-up';
      icon = Icons.event_outlined;
      onTap = _arrange;
    } else if (!_paid) {
      label = 'View payment';
      icon = Icons.credit_card_outlined;
      onTap = _pay;
    } else {
      label = 'Confirm received';
      icon = Icons.check_circle_outline;
      onTap = _confirmReceived;
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
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
}

String _formatTime(TimeOfDay t) {
  final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
}
