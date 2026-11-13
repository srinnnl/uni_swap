import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/model/format.dart';

// ไฟล์นี้ใช้งานได้ด้วยตัวเอง: หน้าชำระเงิน (จำลอง ไม่มีการโอนเงินจริง)
// กด "Simulate payment" แล้วยืนยัน จะบันทึกสถานะ paid ที่ server

class _C {
  static const bg = Color(0xFFFAF9F6);
  static const ink = Color(0xFF2F2F2B);
  static const muted = Color(0xFF7A7973);
  static const faint = Color(0xFFA9A8A2);
  static const border = Color(0xFFE6E4DD);
  static const surface = Color(0xFFF3F2EE);
  static const sage = Color(0xFF3F6B52);
  static const sageBg = Color(0xFFD8E4DC);
  static const amberBg = Color(0xFFFBEBC2);
  static const amberFg = Color(0xFF8A6410);
  static const red = Color(0xFFB3402F);
  static const redBg = Color(0xFFF8DADA);
}

class PaymentPage extends StatelessWidget {
  const PaymentPage({
    super.key,
    required this.orderId,
    required this.title,
    required this.price,
    required this.sellerName,
    this.imageUrl,
    this.paid = false,
    // orders.payment_deadline (สร้างออเดอร์ + 30 นาที) null = ไม่แสดงตัวนับเวลา
    this.paymentDeadline,
  });

  final int orderId; // orders.order_id
  final String title;
  final double price; // orders.total_amount (DECIMAL ใช้ double ทั้งแอป)
  final String sellerName;
  final String? imageUrl;
  final bool paid;
  final DateTime? paymentDeadline;

  String get _amount => '${price.toStringAsFixed(2)} THB';
  String get _orderLabel => orderLabel(orderId);

  Future<void> _markPaid(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.bg,
        title: const Text('Simulate payment?'),
        content: Text(
          'Demo only: mark $_amount as paid for this order? '
          'No real money is charged, held, or transferred.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _C.ink),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simulate payment'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      final response = await orderController.pay(orderId);
      if (response['success'] != true ||
          response['status'] != 'ready_for_meetup') {
        throw const ApiException('The server could not record the payment.');
      }
      if (context.mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildOrderCard(),
            const SizedBox(height: 16),
            _buildSummaryCard(),
            const SizedBox(height: 16),
            _buildNotice(),
            const SizedBox(height: 24),
            _PaySection(
              paid: paid,
              dueAt: paymentDeadline,
              onPay: () => _markPaid(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        Expanded(
          child: Column(
            children: [
              const Text(
                'Payment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _C.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Order $_orderLabel',
                style: const TextStyle(fontSize: 13, color: _C.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _cardBox({required Widget child}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _C.border),
    ),
    child: child,
  );

  Widget _buildOrderCard() {
    return _cardBox(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72,
              height: 72,
              child: imageUrl == null
                  ? Container(
                      color: _C.surface,
                      child: const Icon(Icons.image_outlined, color: _C.faint),
                    )
                  : Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
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
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _C.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  _amount,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _C.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Seller: $sellerName',
                  style: const TextStyle(fontSize: 11, color: _C.muted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: paid ? _C.sageBg : _C.amberBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              paid ? 'Demo paid' : 'Unpaid',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: paid ? _C.sage : _C.amberFg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return _cardBox(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.qr_code_2, color: _C.ink, size: 26),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment method',
                      style: TextStyle(fontSize: 11, color: _C.muted),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Demo QR · not scannable',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _C.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: _C.border),
          _row('Item price', _amount),
          const Divider(height: 1, color: _C.border),
          _row('Reference', _orderLabel),
          const Divider(height: 1, color: _C.border),
          _row('Demo order total', _amount, valueColor: _C.sage, large: true),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    Widget? trailing,
    Color valueColor = _C.ink,
    bool large = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: _C.muted)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: large ? 17 : 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, size: 20, color: _C.sage),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Simulated payment',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _C.ink,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'This demo saves a paid status to the server, but no real '
                  'money is collected, held, or transferred. Real payments '
                  'and seller payouts need a payment provider.',
                  style: TextStyle(fontSize: 12, height: 1.4, color: _C.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Timer and simulated-payment action for the demo.
class _PaySection extends StatefulWidget {
  const _PaySection({
    required this.paid,
    required this.dueAt,
    required this.onPay,
  });

  final bool paid;
  final DateTime? dueAt;
  final Future<void> Function() onPay;

  @override
  State<_PaySection> createState() => _PaySectionState();
}

class _PaySectionState extends State<_PaySection> {
  Timer? _timer;
  Duration? _left;
  bool _isPaying = false;

  bool get _expired => _left != null && _left! <= Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.dueAt != null && !widget.paid) {
      _left = widget.dueAt!.difference(DateTime.now());
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _left = widget.dueAt!.difference(DateTime.now()));
        if (_expired) _timer?.cancel();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _clock {
    final s = _left!.inSeconds.clamp(0, 86400);
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  Future<void> _submitPayment() async {
    if (_isPaying) return;
    setState(() => _isPaying = true);
    try {
      await widget.onPay();
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPay = !widget.paid && !_expired && !_isPaying;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_left != null && !widget.paid) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _expired ? _C.redBg : _C.amberBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 20,
                  color: _expired ? _C.red : _C.amberFg,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _expired
                        ? 'Payment time expired. This order has expired.'
                        : 'Pay within $_clock or the order expires',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _expired ? _C.red : _C.amberFg,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: canPay ? _submitPayment : null,
            style: FilledButton.styleFrom(
              backgroundColor: _C.ink,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _C.border,
              disabledForegroundColor: _C.muted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              _isPaying
                  ? 'Saving payment…'
                  : widget.paid
                  ? 'Paid'
                  : (_expired ? 'Time expired' : 'Simulate payment'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
