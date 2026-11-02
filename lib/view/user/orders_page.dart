import 'package:flutter/material.dart';
import 'package:uni_swap/view/user/order_details_page.dart';

// ---- colors (local to this file) ----
const _cBg = Color(0xFFFAF9F6);
const _cCard = Color(0xFFFFFFFF);
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
  String? meetupPlace;
  DateTime? meetupAt;
  int? rating;

  _Order(this.id, this.title, this.price, this.person, this.isBuying,
      this.timeLabel, this.thumbColor, this.thumbIcon,
      [this.status = _Status.pending]);

  bool get isActive =>
      status == _Status.pending || status == _Status.accepted;
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  static const _meetupPoints = [
    'Maple Hall lobby',
    'Central Library entrance',
    'Student Center cafeteria',
    'Westwood Condos lobby',
    'Main gate',
  ];

  // Mock data (UI only)
  final List<_Order> _orders = [
    _Order('b1', 'Oak study desk', 45, 'Jamie', true, 'Today, 10:24 AM',
        const Color(0xFFD9DEE3), Icons.desk_outlined, _Status.accepted),
    _Order('b2', 'Acoustic guitar', 80, 'Noah', true, 'Yesterday',
        const Color(0xFF4A4036), Icons.music_note),
    _Order('b3', 'City bike', 0, 'Alex', true, 'May 18',
        const Color(0xFFB9B2A6), Icons.pedal_bike, _Status.completed),
    _Order('s1', 'Desk lamp', 12, 'Sam', false, 'Today, 9:02 AM',
        const Color(0xFFE9D9B0), Icons.light_outlined),
    _Order('s2', 'Calculus textbook', 20, 'Priya', false, 'Yesterday',
        const Color(0xFFC9D6CB), Icons.menu_book, _Status.accepted),
    _Order('s3', 'Mini fridge', 60, 'Lee', false, 'Mon',
        const Color(0xFFD3DDE8), Icons.kitchen),
    _Order('s4', 'Bean bag chair', 15, 'Mika', false, 'May 10',
        const Color(0xFFE3C9C9), Icons.chair, _Status.completed),
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
        Row(children: [
          _tab('Buying', _count(true), _showBuying,
              () => setState(() => _showBuying = true)),
          _tab('Selling', _count(false), !_showBuying,
              () => setState(() => _showBuying = false)),
        ]),
        const SizedBox(height: 8),
        if (_active.isEmpty && _past.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(
                child: Text('No orders yet',
                    style: TextStyle(color: _cMuted))),
          ),
        for (final o in _active) _tile(o),
        if (_past.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Past orders',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _cMuted)),
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
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? _cInk : _cMuted)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: _cChip,
                  borderRadius: BorderRadius.circular(10)),
              child: Text('$count',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),
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
    final priceText = o.price == 0 ? 'Free' : '\$${o.price.toStringAsFixed(0)}';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openDetails(o),
      child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _cBorder))),
      child: Opacity(
        opacity: dimmed ? 0.75 : 1,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 80,
            height: 94,
            decoration: BoxDecoration(
                color: o.thumbColor, borderRadius: BorderRadius.circular(10)),
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
                    Text(o.timeLabel,
                        style: const TextStyle(
                            fontSize: 11, color: _cMuted)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(o.title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                    '$priceText · ${o.isBuying ? 'Seller' : 'Buyer'}: ${o.person}',
                    style: const TextStyle(
                        fontSize: 12, color: _cMuted)),
                if (o.meetupPlace != null && o.meetupAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                      'Meet: ${o.meetupPlace} · ${_formatDate(o.meetupAt!)} ${_formatTime(TimeOfDay.fromDateTime(o.meetupAt!))}',
                      style: const TextStyle(
                          fontSize: 12, color: _cSageDark)),
                ],
                const SizedBox(height: 10),
                _actions(o),
              ],
            ),
          ),
        ]),
      ),
    ));
  }

  // เปิดหน้ารายละเอียด แล้วอัปเดตสถานะตามที่ผู้ใช้ทำในหน้านั้น
  // (OrderStage กับ _Status เรียงลำดับเหมือนกัน จึงแปลงด้วย index ได้)
  Future<void> _openDetails(_Order o) async {
    final result = await Navigator.push<OrderStage>(
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
        ),
      ),
    );
    if (result != null && result.index != o.status.index && mounted) {
      setState(() => o.status = _Status.values[result.index]);
    }
  }

  Widget _link(String text, VoidCallback? onTap, {bool arrow = false}) {
    return InkWell(
      onTap: onTap,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: onTap == null ? _cMuted : _cLink)),
        if (arrow)
          const Icon(Icons.chevron_right, size: 16, color: _cLink),
      ]),
    );
  }

  Widget _actions(_Order o) {
    switch (o.status) {
      case _Status.pending:
        if (o.isBuying) {
          return Row(children: [
            _link('Waiting for seller', null),
            const SizedBox(width: 16),
            _link('Cancel', () => setState(() => o.status = _Status.cancelled)),
          ]);
        }
        return Row(children: [
          _link('Accept', () => setState(() => o.status = _Status.accepted)),
          const SizedBox(width: 16),
          _link('Decline', () => setState(() => o.status = _Status.cancelled)),
        ]);

      case _Status.accepted:
        return Wrap(spacing: 16, children: [
          _link('Arrange meet-up', () => _meetupSheet(o), arrow: true),
          if (!o.isBuying)
            _link('Mark completed',
                () => setState(() => o.status = _Status.completed)),
        ]);

      case _Status.completed:
        if (!o.isBuying) return const SizedBox.shrink();
        if (o.rating != null) {
          return Text('Reviewed · ${'★' * o.rating!}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _cAmberFg));
        }
        return _link('Leave a review', () => _reviewDialog(o));

      case _Status.cancelled:
        return const SizedBox.shrink();
    }
  }

  void _meetupSheet(_Order o) {
    String place = o.meetupPlace ?? _meetupPoints.first;
    DateTime date = o.meetupAt ?? DateTime.now().add(const Duration(days: 1));
    TimeOfDay time = o.meetupAt != null
        ? TimeOfDay.fromDateTime(o.meetupAt!)
        : const TimeOfDay(hour: 17, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Meet-up for ${o.title}',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              const _FieldLabel('Meeting point'),
              DropdownButtonFormField<String>(
                value: place,
                decoration: _dec(''),
                items: [
                  for (final p in _meetupPoints)
                    DropdownMenuItem(value: p, child: Text(p)),
                ],
                onChanged: (v) => setSheet(() => place = v ?? place),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(_formatDate(date)),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: date,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 90)),
                      );
                      if (d != null) setSheet(() => date = d);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time, size: 16),
                    label: Text(_formatTime(time)),
                    onPressed: () async {
                      final t = await showTimePicker(
                          context: ctx, initialTime: time);
                      if (t != null) setSheet(() => time = t);
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _DarkButton(
                label: 'Confirm meet-up',
                onPressed: () {
                  setState(() {
                    o.meetupPlace = place;
                    o.meetupAt = DateTime(date.year, date.month, date.day,
                        time.hour, time.minute);
                  });
                  Navigator.pop(ctx);
                  _showSnack(context, 'Meet-up saved (mock)');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _reviewDialog(_Order o) {
    int stars = 5;
    final text = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: _cBg,
          surfaceTintColor: Colors.transparent,
          title: Text('Review ${o.person}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setDialog(() => stars = i),
                  icon: Icon(i <= stars ? Icons.star : Icons.star_border,
                      color: _cAmberFg),
                ),
            ]),
            TextField(
              controller: text,
              maxLines: 3,
              decoration: _dec('How was the seller?'),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
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
    // หมายเหตุ: ไม่ dispose `text` ตรงนี้ เพราะช่องพิมพ์ยังแสดงอยู่ระหว่างหน้าต่างปิด
    // (ถ้า dispose จะเกิด error "used after being disposed")
  }
}

InputDecoration _dec(String hint, {Widget? prefix}) {
  OutlineInputBorder b(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFB0AFA8), fontSize: 14),
    filled: true,
    fillColor: _cCard,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    prefixIcon: prefix,
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    border: b(_cBorder),
    enabledBorder: b(_cBorder),
    disabledBorder: b(_cBorder),
    focusedBorder: b(_cInk),
    errorBorder: b(_cRedFg),
    focusedErrorBorder: b(_cRedFg),
  );
}

// ---- small shared widgets (local to this file) ----
class _DarkButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _DarkButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _cInk,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onPressed,
          child: Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _cInk)),
      );
}

class _PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _PageHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(title,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700, color: _cInk)),
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        Text(subtitle!,
            style: const TextStyle(fontSize: 13, color: _cMuted)),
      ],
    ]);
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _StatusBadge(
      {super.key, required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
      );
}

String _formatDate(DateTime d) {
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${m[d.month - 1]} ${d.day}, ${d.year}';
}

String _formatTime(TimeOfDay t) {
  final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
}

void _showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _cInk,
    ));
}
