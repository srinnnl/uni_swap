import 'package:flutter/material.dart';

// ---- colors (local to this file) ----
const _cBg = Color(0xFFFAF9F6);
const _cCard = Color(0xFFFFFFFF);
const _cInk = Color(0xFF2B2B26);
const _cMuted = Color(0xFF8A8A82);
const _cBorder = Color(0xFFE6E4DE);
const _cBlueBg = Color(0xFFE3ECF7);
const _cBlueFg = Color(0xFF3B5E8C);
const _cAmberBg = Color(0xFFFBEBC2);
const _cAmberFg = Color(0xFF8A6410);
const _cRedBg = Color(0xFFF8DADA);
const _cRedFg = Color(0xFFB3402F);

// reports.status: fresh = pending, review = reviewing (high ไม่มีใน DB ให้ API คำนวณ เช่น รายงานต่อสินค้า >= 3)

// refunds (ผู้ซื้อขอคืนเงินหลังจ่าย): refund_status='pending' รอ admin ตัดสิน
// approve -> refund_status='completed', orders.status='refunded', payments.payment_status='refunded'
// reject  -> refund_status='rejected',  orders.status กลับเป็น 'ready_for_meetup'
class _Refund {
  final int id; // refunds.refund_id
  final int orderId; // refunds.order_id
  final String product;
  final String buyer; // refunds.requested_by -> users.display_name
  final String seller;
  final double amount; // refunds.refund_amount
  final String reason; // refunds.reason
  final String requested; // refunds.requested_at (แปลงเป็นข้อความ เช่น '2 hours ago')
  const _Refund(
    this.id,
    this.orderId,
    this.product,
    this.buyer,
    this.seller,
    this.amount,
    this.reason,
    this.requested,
  );

  String get orderRef => '#US-$orderId';
  String get amountText => '${amount.toStringAsFixed(2)} THB';
}

class AdminRefundsPage extends StatefulWidget {
  const AdminRefundsPage({super.key});

  @override
  State<AdminRefundsPage> createState() => _AdminRefundsPageState();
}

class _AdminRefundsPageState extends State<AdminRefundsPage> {
  static const _filters = ['All', '500+ THB'];

  // Mock data (UI only)
  // TODO: GET /api/admin/refunds?status=pending แล้ว map เป็น _Refund
  final List<_Refund> _refunds = [
    const _Refund(1, 12, 'MacBook Air M2', 'Maya Demo', 'Niran Demo', 18500,
        'Seller did not show up at the meetup.', '10 min ago'),
    const _Refund(2, 7, 'Oak study desk', 'Alex S.', 'Priya N.', 450,
        'Item looks different from the photos.', '2 hours ago'),
    const _Refund(3, 9, 'Calculus textbook', 'Noah P.', 'Sam K.', 120,
        'Changed my mind before the meetup.', 'Yesterday'),
  ];

  String _query = '';
  String _filter = 'All';
  bool _busy = false;

  List<_Refund> get _visible {
    final q = _query.trim().toLowerCase();
    return _refunds.where((r) {
      final matchQ = q.isEmpty ||
          r.product.toLowerCase().contains(q) ||
          r.buyer.toLowerCase().contains(q) ||
          r.seller.toLowerCase().contains(q) ||
          r.orderRef.toLowerCase().contains(q);
      final matchF = _filter == 'All' || r.amount >= 500;
      return matchQ && matchF;
    }).toList();
  }

  Future<void> _openFilter() async {
    final r = await _pickFilter(context, _filter, _filters);
    if (r != null) setState(() => _filter = r);
  }

  // ===== จุดเชื่อมต่อ API =====
  // approve: PUT /api/admin/refunds/:id { action: 'approve' }
  // reject : PUT /api/admin/refunds/:id { action: 'reject' }
  // ถ้า API error ให้แสดงข้อความและไม่ลบรายการออก
  Future<void> _decide(BuildContext ctx, _Refund r, String action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // TODO: await adminController.decideRefund(r.id, action);
      setState(() => _refunds.remove(r));
      if (ctx.mounted) Navigator.pop(ctx);
      if (mounted) {
        _snack(
          context,
          action == 'approve'
              ? 'Refunded ${r.amountText} to ${r.buyer} (mock)'
              : 'Refund rejected (mock)',
        );
      }
    } catch (e) {
      if (mounted) _snack(context, 'Could not update refund. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openRefund(_Refund r) {
    _showSheet(context, (ctx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBox(
                icon: Icons.currency_exchange,
                bg: _cAmberBg,
                fg: _cAmberFg,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  r.product,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const _Badge(label: 'Pending', bg: _cAmberBg, fg: _cAmberFg),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow('Amount', r.amountText),
          _InfoRow('Order', r.orderRef),
          _InfoRow('Buyer', r.buyer),
          _InfoRow('Seller', r.seller),
          _InfoRow('Requested', r.requested),
          if (r.reason.isNotEmpty) _InfoRow('Reason', r.reason),
          const Divider(height: 1, color: _cBorder),
          const SizedBox(height: 20),
          _ActionButton(
            label: 'Approve refund',
            onPressed: () async {
              final ok = await _confirm(
                ctx,
                title: 'Approve refund?',
                message:
                    '${r.amountText} will be returned to ${r.buyer} and the order will be marked as refunded.',
                confirmLabel: 'Approve',
              );
              if (!ok || !ctx.mounted) return;
              await _decide(ctx, r, 'approve');
            },
          ),
          const SizedBox(height: 10),
          _ActionButton(
            filled: false,
            danger: true,
            label: 'Reject request',
            onPressed: () async {
              final ok = await _confirm(
                ctx,
                title: 'Reject refund?',
                message:
                    'The order goes back to waiting for the meetup and the buyer keeps the item reserved.',
                confirmLabel: 'Reject',
              );
              if (!ok || !ctx.mounted) return;
              await _decide(ctx, r, 'reject');
            },
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _visible;
    return Scaffold(
      backgroundColor: _cBg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'Refunds',
              subtitle: '${_refunds.length} waiting for review',
            ),
            _SearchRow(
              hint: 'Search refunds',
              filterActive: _filter != 'All',
              onChanged: (v) => setState(() => _query = v),
              onFilter: _openFilter,
            ),
            _SectionRow(label: 'Needs attention', shown: list.length),
            Expanded(
              child: list.isEmpty
                  ? const _Empty('No refund requests')
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        for (final r in list)
                          _ListRow(
                            icon: Icons.currency_exchange,
                            iconBg: _cAmberBg,
                            iconFg: _cAmberFg,
                            title: r.product,
                            subtitle: '${r.buyer} · ${r.amountText}',
                            badge: 'Pending',
                            badgeBg: _cAmberBg,
                            badgeFg: _cAmberFg,
                            onTap: () => _openRefund(r),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- small shared widgets (local to this file) ----
void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _cInk,
      ),
    );
}

Future<T?> _showSheet<T>(
  BuildContext context,
  Widget Function(BuildContext) builder,
) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _cBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(ctx).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(child: builder(ctx)),
    ),
  );
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: _cBg,
      surfaceTintColor: Colors.transparent,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _cRedFg),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

Future<String?> _pickFilter(
  BuildContext context,
  String current,
  List<String> options,
) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: _cBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final o in options)
                  ChoiceChip(
                    label: Text(o),
                    selected: o == current,
                    showCheckmark: false,
                    selectedColor: _cInk,
                    backgroundColor: _cCard,
                    side: const BorderSide(color: _cBorder),
                    labelStyle: TextStyle(
                      color: o == current ? Colors.white : _cInk,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => Navigator.pop(ctx, o),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _cInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: _cMuted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () => _snack(context, 'More options (coming soon)'),
          ),
        ],
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  final String hint;
  final bool filterActive;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;
  const _SearchRow({
    required this.hint,
    required this.filterActive,
    required this.onChanged,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder b(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFFB0AFA8),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search, size: 20, color: _cInk),
                filled: true,
                fillColor: _cCard,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                border: b(_cBorder),
                enabledBorder: b(_cBorder),
                focusedBorder: b(_cInk),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: _cCard,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onFilter,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: filterActive ? _cInk : _cBorder),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.tune, size: 20),
                    if (filterActive)
                      const Positioned(
                        top: 12,
                        right: 12,
                        child: CircleAvatar(
                          radius: 4,
                          backgroundColor: _cRedFg,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  final String label;
  final int shown;
  const _SectionRow({required this.label, required this.shown});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(
            '$shown shown',
            style: const TextStyle(fontSize: 11, color: _cMuted),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Badge({required this.label, required this.bg, required this.fg});

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

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;
  const _IconBox({
    required this.icon,
    required this.bg,
    required this.fg,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, size: size * 0.42, color: fg),
  );
}

class _ListRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeBg;
  final Color badgeFg;
  final VoidCallback onTap;
  const _ListRow({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeBg,
    required this.badgeFg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _cBorder)),
        ),
        child: Row(
          children: [
            _IconBox(icon: icon, bg: iconBg, fg: iconFg),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: _cMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _Badge(label: badge, bg: badgeBg, fg: badgeFg),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final bool danger;
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? _cRedFg : _cInk;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final text = Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    );
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: filled
          ? FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: color,
                shape: shape,
              ),
              onPressed: onPressed,
              child: text,
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: danger ? _cRedFg : _cBorder),
                shape: shape,
              ),
              onPressed: onPressed,
              child: text,
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: _cMuted)),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);

  @override
  Widget build(BuildContext context) => Center(
    child: Text(text, style: const TextStyle(color: _cMuted)),
  );
}