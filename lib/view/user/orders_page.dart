import 'package:flutter/material.dart';
import 'package:uni_swap/view/user/order_details_page.dart';

// ---- colors (local to this file) ----
const _cBg = Color(0xFFFAF9F6);
const _cInk = Color(0xFF2B2B26);
const _cMuted = Color(0xFF8A8A82);
const _cBorder = Color(0xFFE6E4DE);
const _cChip = Color(0xFFF0EEE9);
const _cSage = Color(0xFFD8E4DC);
const _cSageDark = Color(0xFF3F6B52);
const _cBlueBg = Color(0xFFE3ECF7);
const _cBlueFg = Color(0xFF3B5E8C);
const _cAmberBg = Color(0xFFFBEBC2);
const _cAmberFg = Color(0xFF8A6410);
const _cRedBg = Color(0xFFF8DADA);
const _cRedFg = Color(0xFFB3402F);
const _cLink = Color(0xFF4A5C8F);

// สถานะต้องเรียงลำดับเดียวกับ OrderStage ใน order_details_page.dart
// (แปลงกันด้วย index) และตรงกับ orders.status ใน DB:
//   pending = requested, accepted, completed, cancelled
// "นัดรับแล้ว" ดูจาก meetupPlace/meetupAt  "จ่ายแล้ว" ดูจาก paid
enum _Status { pending, accepted, completed, cancelled }

class _Order {
  final String id;
  final String title;
  final double price;
  final String person; // seller (Buying tab) / buyer (Selling tab)
  final bool isBuying;
  final String timeLabel;
  final Color thumbColor;
  final IconData thumbIcon;
  _Status status;
  bool paid; // payments.status = verified (จำลอง)
  String? meetupPlace; // ผู้ซื้อเสนอตั้งแต่ตอนกด Request to buy
  DateTime? meetupAt;
  int? rating;

  _Order(
    this.id,
    this.title,
    this.price,
    this.person,
    this.isBuying,
    this.timeLabel,
    this.thumbColor,
    this.thumbIcon, {
    this.status = _Status.pending,
    this.paid = false,
    this.meetupPlace,
    this.meetupAt,
  });

  bool get isActive => status == _Status.pending || status == _Status.accepted;

  // สินค้าฟรี (ราคา 0) ข้ามขั้นจ่ายเงิน
  bool get needsPayment => price > 0;
}

// เวลาจำลองสำหรับข้อมูลตัวอย่าง: วันนี้ + [days] วัน ที่ [hour]:[minute]
DateTime _soon(int days, int hour, [int minute = 0]) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day + days, hour, minute);
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  // Mock data (UI only)
  // TODO: โหลดจาก API (orders + meetups + payments) แล้วแปลงเป็น _Order
  // ทุกออเดอร์มีจุดนัดตั้งแต่ตอนกด Request to buy (ผู้ซื้อเสนอ ผู้ขายกด Accept = ยืนยัน)
  final List<_Order> _orders = [
    _Order(
      'b1',
      'Oak study desk',
      45,
      'Jamie',
      true,
      'Today, 10:24 AM',
      const Color(0xFFD9DEE3),
      Icons.desk_outlined,
      status: _Status.accepted,
      meetupPlace: 'Maple Hall lobby',
      meetupAt: _soon(1, 17, 30),
    ),
    _Order(
      'b2',
      'Acoustic guitar',
      80,
      'Noah',
      true,
      'Yesterday',
      const Color(0xFF4A4036),
      Icons.music_note,
      meetupPlace: 'Central Library entrance',
      meetupAt: _soon(2, 18),
    ),
    _Order(
      'b3',
      'City bike',
      0,
      'Alex',
      true,
      'May 18',
      const Color(0xFFB9B2A6),
      Icons.pedal_bike,
      status: _Status.completed,
      meetupPlace: 'Main gate',
      meetupAt: DateTime(DateTime.now().year, 5, 20, 16),
    ),
    _Order(
      's1',
      'Desk lamp',
      12,
      'Sam',
      false,
      'Today, 9:02 AM',
      const Color(0xFFE9D9B0),
      Icons.light_outlined,
      meetupPlace: 'Student Center cafeteria',
      meetupAt: _soon(1, 12),
    ),
    _Order(
      's2',
      'Calculus textbook',
      20,
      'Priya',
      false,
      'Yesterday',
      const Color(0xFFC9D6CB),
      Icons.menu_book,
      status: _Status.accepted,
      paid: true,
      meetupPlace: 'Maple Hall lobby',
      meetupAt: _soon(1, 15),
    ),
    _Order(
      's3',
      'Mini fridge',
      60,
      'Lee',
      false,
      'Mon',
      const Color(0xFFD3DDE8),
      Icons.kitchen,
      meetupPlace: 'Westwood Condos lobby',
      meetupAt: _soon(3, 11),
    ),
    _Order(
      's4',
      'Bean bag chair',
      15,
      'Mika',
      false,
      'May 10',
      const Color(0xFFE3C9C9),
      Icons.chair,
      status: _Status.completed,
      paid: true,
      meetupPlace: 'Main gate',
      meetupAt: DateTime(DateTime.now().year, 5, 12, 17),
    ),
  ];

  bool _showBuying = true;

  List<_Order> get _current =>
      _orders.where((o) => o.isBuying == _showBuying).toList();
  List<_Order> get _active => _current.where((o) => o.isActive).toList();
  List<_Order> get _past => _current.where((o) => !o.isActive).toList();
  int _count(bool buying) =>
      _orders.where((o) => o.isBuying == buying && o.isActive).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cBg,
      body: SafeArea(bottom: false, child: _buildList()),
    );
  }

  Widget _buildList() {
    return ListView(
      // ท้ายหน้าเว้น 120 ให้พ้นแถบเมนูล่าง
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        const _PageHeader(title: 'My orders'),
        const SizedBox(height: 24),
        Row(
          children: [
            _tab(
              'Buying',
              _count(true),
              _showBuying,
              () => setState(() => _showBuying = true),
            ),
            _tab(
              'Selling',
              _count(false),
              !_showBuying,
              () => setState(() => _showBuying = false),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_active.isEmpty && _past.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(
              child: Text('No orders yet', style: TextStyle(color: _cMuted)),
            ),
          ),
        for (final o in _active) _tile(o),
        if (_past.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'Past orders',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _cMuted,
            ),
          ),
          const SizedBox(height: 12),
          for (final o in _past) _tile(o, dimmed: true),
        ],
      ],
    );
  }

  Widget _tab(String label, int count, bool selected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? _cInk : _cBorder,
                width: selected ? 2 : 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? _cInk : _cMuted,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _cChip,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color, Color) _statusStyle(_Status s) => switch (s) {
    _Status.pending => ('Pending', _cAmberBg, _cAmberFg),
    _Status.accepted => ('Accepted', _cBlueBg, _cBlueFg),
    _Status.completed => ('Completed', _cSage, _cSageDark),
    _Status.cancelled => ('Cancelled', _cRedBg, _cRedFg),
  };

  Widget _tile(_Order o, {bool dimmed = false}) {
    final (label, bg, fg) = _statusStyle(o.status);
    final priceText = o.price == 0
        ? 'Free'
        : '${o.price.toStringAsFixed(0)} THB';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openDetails(o),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _cBorder)),
        ),
        child: Opacity(
          opacity: dimmed ? 0.75 : 1,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 94,
                decoration: BoxDecoration(
                  color: o.thumbColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(o.thumbIcon, color: Colors.white70, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatusBadge(label: label, bg: bg, fg: fg),
                        Text(
                          o.timeLabel,
                          style: const TextStyle(fontSize: 11, color: _cMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      o.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$priceText · ${o.isBuying ? 'Seller' : 'Buyer'}: ${o.person}',
                      style: const TextStyle(fontSize: 12, color: _cMuted),
                    ),
                    if (o.meetupPlace != null && o.meetupAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${o.status == _Status.pending ? 'Proposed meet-up' : 'Meet'}: ${o.meetupPlace} · ${_formatDate(o.meetupAt!)} ${_formatTime(TimeOfDay.fromDateTime(o.meetupAt!))}',
                        style: const TextStyle(fontSize: 12, color: _cSageDark),
                      ),
                    ],
                    const SizedBox(height: 10),
                    _actions(o),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // เปิดหน้ารายละเอียด แล้วรับผลล่าสุดกลับมาทั้งก้อน (สถานะ, จ่ายแล้วหรือยัง, จุดนัด)
  // เดิม pop ส่งกลับแค่สถานะ ทำให้ "จ่ายแล้ว" กับ "นัดรับ" หายเมื่อกลับมาหน้ารายการ
  // (OrderStage กับ _Status เรียงลำดับเหมือนกัน จึงแปลงด้วย index ได้)
  Future<void> _openDetails(_Order o) async {
    final result = await Navigator.push<OrderResult>(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailsPage(
          orderId: '#US-${o.id.toUpperCase()}',
          title: o.title,
          price: o.price,
          person: o.person,
          isBuying: o.isBuying,
          stage: OrderStage.values[o.status.index],
          requestedLabel: o.timeLabel,
          meetupPlace: o.meetupPlace,
          meetupAt: o.meetupAt,
          paid: o.paid,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      o.status = _Status.values[result.stage.index];
      o.paid = result.paid;
      o.meetupPlace = result.meetupPlace;
      o.meetupAt = result.meetupAt;
    });
  }

  Widget _link(String text, VoidCallback? onTap, {bool arrow = false}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: onTap == null ? _cMuted : _cLink,
            ),
          ),
          if (arrow) const Icon(Icons.chevron_right, size: 16, color: _cLink),
        ],
      ),
    );
  }

  Widget _actions(_Order o) {
    switch (o.status) {
      case _Status.pending:
        if (o.isBuying) {
          return Row(
            children: [
              _link('Waiting for seller', null),
              const SizedBox(width: 16),
              _link(
                'Cancel',
                () => setState(() => o.status = _Status.cancelled),
              ),
            ],
          );
        }
        return Row(
          children: [
            _link('Accept', () => setState(() => o.status = _Status.accepted)),
            const SizedBox(width: 16),
            _link(
              'Decline',
              () => setState(() => o.status = _Status.cancelled),
            ),
          ],
        );

      case _Status.accepted:
        // ผู้ซื้อ: ขั้นตอนถัดไปทั้งหมดทำในหน้ารายละเอียดหน้าเดียว (นัดรับ -> จ่าย -> ยืนยันรับของ)
        // ผู้ขาย: ไม่มีปุ่มปิดงานเอง เพราะ completed เกิดจากผู้ซื้อกด Confirm received เท่านั้น
        if (o.isBuying) {
          final next = o.meetupAt == null
              ? 'Arrange meet-up'
              : (o.needsPayment && !o.paid)
              ? 'Pay now'
              : 'Confirm received';
          return _link(next, () => _openDetails(o), arrow: true);
        }
        return Text(
          !o.needsPayment
              ? 'Waiting for buyer to confirm receipt'
              : o.paid
              ? 'Paid · waiting for buyer to confirm receipt'
              : 'Waiting for buyer to pay',
          style: const TextStyle(fontSize: 12, color: _cMuted),
        );

      case _Status.completed:
        if (!o.isBuying) return const SizedBox.shrink();
        if (o.rating != null) {
          return Text(
            'Reviewed · ${'★' * o.rating!}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _cAmberFg,
            ),
          );
        }
        return _link('Leave a review', () => _reviewDialog(o));

      case _Status.cancelled:
        return const SizedBox.shrink();
    }
  }

  void _reviewDialog(_Order o) {
    int stars = 5;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: _cBg,
          surfaceTintColor: Colors.transparent,
          title: Text('Review ${o.person}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      onPressed: () => setDialog(() => stars = i),
                      icon: Icon(
                        i <= stars ? Icons.star : Icons.star_border,
                        color: _cAmberFg,
                        size: 36,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'How was your experience?',
                style: TextStyle(color: _cMuted, fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _cInk),
              onPressed: () {
                setState(() => o.rating = stars);
                Navigator.pop(ctx);
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- small shared widgets (local to this file) ----
class _PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _PageHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _cInk,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: const TextStyle(fontSize: 13, color: _cMuted)),
        ],
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _StatusBadge({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
    ),
  );
}

String _formatDate(DateTime d) {
  const m = [
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
  return '${m[d.month - 1]} ${d.day}, ${d.year}';
}

String _formatTime(TimeOfDay t) {
  final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
}
