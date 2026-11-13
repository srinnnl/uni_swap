import 'package:flutter/material.dart';
import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/model/format.dart';
import 'package:uni_swap/model/json_utils.dart';
import 'package:uni_swap/model/order.dart' as order_model;
import 'package:uni_swap/model/order_status.dart';
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

// Order-row view model adapted from the shared Order API model.
class _Order {
  final int id; // orders.order_id
  final String title;
  final double price; // orders.seller_price
  final String person; // seller (Buying tab) / buyer (Selling tab)
  final bool isBuying;
  final DateTime
  createdAt; // orders.created_at (API ส่ง UTC ให้แปลงด้วย toLocal())
  final Color thumbColor;
  final IconData thumbIcon;
  final String? imageUrl;
  final String? pickupDetail;
  final String productLocation; // products.location_name
  final double commissionRate; // orders.commission_rate
  final double commissionAmount; // orders.commission_amount
  final double sellerPayout; // orders.seller_payout
  OrderStatus status;
  String meetupPlace; // orders.meetup_location (NOT NULL)
  DateTime? meetupAt; // orders.meetup_datetime
  DateTime? paymentDeadline; // orders.payment_deadline

  _Order({
    required this.id,
    required this.title,
    required this.price,
    required this.person,
    required this.isBuying,
    required this.createdAt,
    required this.thumbColor,
    required this.thumbIcon,
    required this.productLocation,
    required this.meetupPlace,
    required this.status,
    this.imageUrl,
    this.pickupDetail,
    this.meetupAt,
    this.paymentDeadline,
    this.commissionRate = 5,
    double? commissionAmount,
    double? sellerPayout,
  }) : commissionAmount =
           commissionAmount ??
           double.parse((price * commissionRate / 100).toStringAsFixed(2)),
       sellerPayout =
           sellerPayout ??
           price -
               double.parse((price * commissionRate / 100).toStringAsFixed(2));

  factory _Order.fromModel(order_model.Order order) => _Order(
    id: order.id,
    title: order.productTitle ?? 'Item',
    price: order.sellerPrice,
    person: order.isBuying
        ? order.sellerName ?? 'Seller'
        : order.buyerName ?? 'Buyer',
    isBuying: order.isBuying,
    createdAt: order.createdAt ?? order.updatedAt ?? DateTime.now(),
    thumbColor: const Color(0xFFD9DEE3),
    thumbIcon: Icons.shopping_bag_outlined,
    imageUrl: order.imageUrl,
    pickupDetail: order.pickupDetail,
    productLocation: order.productLocationName ?? 'Seller pickup location',
    commissionRate: order.commissionRate,
    commissionAmount: order.commissionAmount,
    sellerPayout: order.sellerPayout,
    status: order.status,
    meetupPlace: order.meetupLocation,
    meetupAt: order.meetupDatetime,
    paymentDeadline: order.paymentDeadline,
  );

  // เลย payment_deadline แล้วยังไม่จ่าย แสดงเป็น expired (backend เป็นคนเปลี่ยนจริง)
  OrderStatus get shown {
    final due = paymentDeadline;
    if (status == OrderStatus.pendingPayment &&
        due != null &&
        !due.isAfter(DateTime.now())) {
      return OrderStatus.expired;
    }
    return status;
  }

  bool get isActive => shown.isActive;

  // สินค้าฟรี (ราคา 0) ไม่มีขั้นจ่ายเงิน
  bool get needsPayment => price > 0;
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key, this.isActive = false});

  final bool isActive;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final List<_Order> _orders = [];

  bool _showBuying = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _loadOrders();
  }

  @override
  void didUpdateWidget(covariant OrdersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await orderController.list(limit: 100);
      if (response['success'] != true) {
        throw const ApiException('The server could not load your orders.');
      }
      if (response['data'] is! List) {
        throw const ApiException('The server returned invalid order data.');
      }
      final parsed = jsonParseList(
        response['data'],
        order_model.Order.fromJson,
      );
      if (parsed.any((order) => order.id <= 0 || order.perspective == null)) {
        throw const ApiException('The server returned invalid order data.');
      }
      if (!mounted) return;
      setState(() {
        _orders
          ..clear()
          ..addAll(parsed.map(_Order.fromModel));
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_Order> get _current =>
      _orders.where((o) => o.isBuying == _showBuying).toList();
  List<_Order> get _active => _current.where((o) => o.isActive).toList();
  List<_Order> get _past => _current.where((o) => !o.isActive).toList();
  // ตัวเลขบนแท็บ: ออเดอร์ที่ยังดำเนินอยู่
  int _count(bool buying) =>
      _orders.where((o) => o.isBuying == buying && o.isActive).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cBg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(onRefresh: _loadOrders, child: _buildList()),
      ),
    );
  }

  Widget _buildList() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
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
        const SizedBox(height: 24),
        if (_loading && _orders.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null && _orders.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loadOrders,
                  child: const Text('Try again'),
                ),
              ],
            ),
          )
        else if (_active.isEmpty && _past.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(
              child: Text('No orders yet', style: TextStyle(color: _cMuted)),
            ),
          ),
        if (_error != null && _orders.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_error!, style: const TextStyle(color: _cRedFg)),
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

  (String, Color, Color) _statusStyle(OrderStatus s) => switch (s.tone) {
    StatusTone.amber => (s.label, _cAmberBg, _cAmberFg),
    StatusTone.blue => (s.label, _cBlueBg, _cBlueFg),
    StatusTone.green => (s.label, _cSage, _cSageDark),
    StatusTone.red => (s.label, _cRedBg, _cRedFg),
  };

  // เวลาที่สร้างออเดอร์ แสดงแบบสั้น (Today, 10:24 AM / Yesterday / May 18)
  String _createdLabel(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) {
      return 'Today, ${_formatTime(TimeOfDay.fromDateTime(t))}';
    }
    if (diff == 1) return 'Yesterday';
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
    return '${m[t.month - 1]} ${t.day}';
  }

  Widget _tile(_Order o, {bool dimmed = false}) {
    final (label, bg, fg) = _statusStyle(o.shown);
    final priceText = formatPriceTHB(o.price);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openDetails(o),
      child: Container(
        // ✨ 1. เปลี่ยน padding จากบน/ล่าง เป็นรอบๆ การ์ด
        margin: const EdgeInsets.only(bottom: 16), // ระยะห่างระหว่างการ์ด
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, // ✨ 2. สีพื้นหลังของการ์ด
          borderRadius: BorderRadius.circular(16),
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
                child: o.imageUrl == null
                    ? Icon(o.thumbIcon, color: Colors.white70, size: 30)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          o.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            o.thumbIcon,
                            color: Colors.white70,
                            size: 30,
                          ),
                        ),
                      ),
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
                          _createdLabel(o.createdAt),
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
                    if (o.meetupAt != null && o.isActive) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Meet: ${o.meetupPlace} · ${_formatDate(o.meetupAt!)} ${_formatTime(TimeOfDay.fromDateTime(o.meetupAt!))}',
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

  // เปิดหน้ารายละเอียด แล้วรับผลล่าสุด (สถานะ + จุดนัด) กลับมาอัปเดตรายการ
  // ใช้ OrderStatus ตัวเดียวกันทั้งสองหน้า ไม่ต้องแปลงด้วย index อีกต่อไป
  Future<void> _openDetails(_Order o) async {
    final result = await Navigator.push<OrderResult>(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailsPage(
          orderId: o.id,
          title: o.title,
          price: o.price,
          person: o.person,
          isBuying: o.isBuying,
          status: o.status,
          createdLabel: _createdLabel(o.createdAt),
          meetupPlace: o.meetupPlace,
          meetupAt: o.meetupAt,
          paymentDeadline: o.paymentDeadline,
          productLocation: o.productLocation,
          pickupDetail: o.pickupDetail,
          commissionRate: o.commissionRate,
          commissionAmount: o.commissionAmount,
          sellerPayout: o.sellerPayout,
          imageUrl: o.imageUrl,
        ),
      ),
    );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        o.status = result.status;
        o.meetupPlace = result.meetupPlace;
        o.meetupAt = result.meetupAt;
      });
    }
    await _loadOrders();
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
    switch (o.shown) {
      case OrderStatus.pendingPayment:
        // ผู้ซื้อ: จ่ายเงิน/ยกเลิกต่อในหน้ารายละเอียด (มี confirm dialog)
        if (o.isBuying) {
          return _link(
            o.price > 0 ? 'Pay now' : 'View order',
            () => _openDetails(o),
            arrow: true,
          );
        }
        return const Text(
          'Waiting for buyer to pay',
          style: TextStyle(fontSize: 12, color: _cMuted),
        );

      case OrderStatus.paid || OrderStatus.readyForMeetup:
        // ผู้ซื้อ: นัดรับของแล้วกด Confirm received ในหน้ารายละเอียด
        // ผู้ขาย: ไม่มีปุ่มปิดงานเอง เพราะ completed เกิดจากผู้ซื้อกด Confirm received เท่านั้น
        if (o.isBuying) {
          return _link('Confirm received', () => _openDetails(o), arrow: true);
        }
        return Text(
          o.needsPayment
              ? 'Paid · waiting for buyer to confirm receipt'
              : 'Waiting for buyer to confirm receipt',
          style: const TextStyle(fontSize: 12, color: _cMuted),
        );

      case OrderStatus.completed:
        return const SizedBox.shrink();

      case OrderStatus.cancelled || OrderStatus.expired:
        return const SizedBox.shrink();
    }
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
