import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ไฟล์นี้ใช้งานได้ด้วยตัวเอง: หน้าชำระเงิน (จำลอง ไม่มีการโอนเงินจริง)
// กด "Mark as paid" แล้วยืนยัน จะ pop กลับพร้อมค่า true

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
    // ผู้ซื้อโอนเข้า "บัญชีกลางของ UniSwap" (escrow) ไม่ใช่บัญชีผู้ขาย
    // แพลตฟอร์มจะโอนต่อให้ผู้ขายหลังผู้ซื้อกดยืนยันรับของ
    // TODO: ดึงบัญชีกลางจาก API (ตาราง platform_bank_accounts ของ orders)
    this.bankName = 'Kasikornbank',
    this.accountNumber = '123-4-56789-0',
    this.accountName = 'UniSwap Campus Escrow',
  });

  final String orderId;
  final String title;
  final double price;
  final String sellerName;
  final String? imageUrl;
  final bool paid;
  final String bankName;
  final String accountNumber;
  final String accountName;

  String get _amount => '${price.toStringAsFixed(2)} THB';

  // ===== จุดเชื่อมต่อ API: ให้เพื่อนแก้ฟังก์ชันนี้ =====
  Future<void> _markPaid(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.bg,
        title: const Text('Confirm payment'),
        content: Text('Have you transferred $_amount to UniSwap?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _C.ink),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, mark as paid'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    // TODO: ส่งสถานะ "ชำระแล้ว" ไปที่ API (orderId) ผู้ขายจะเห็นว่าผู้ซื้อแจ้งโอนแล้ว
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildOrderCard(),
            const SizedBox(height: 16),
            _buildTransferCard(context),
            const SizedBox(height: 16),
            _buildNotice(),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: paid ? null : () => _markPaid(context),
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
                  paid ? 'Paid' : 'Mark as paid',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
                'Order $orderId',
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
              paid ? 'Paid' : 'Unpaid',
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

  Widget _buildTransferCard(BuildContext context) {
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
                child: const Icon(Icons.apartment, color: _C.ink, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transfer to',
                      style: TextStyle(fontSize: 11, color: _C.muted),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'UniSwap (held until you confirm)',
                      style: const TextStyle(
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
          _row('Bank', bankName),
          const Divider(height: 1, color: _C.border),
          _row(
            'Account number',
            accountNumber,
            trailing: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: accountNumber));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('Account number copied')),
                  );
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.copy_outlined, size: 16, color: _C.muted),
              ),
            ),
          ),
          const Divider(height: 1, color: _C.border),
          _row('Account name', accountName),
          const Divider(height: 1, color: _C.border),
          // เลขอ้างอิงให้ฝั่งแพลตฟอร์มจับคู่การโอนกับออเดอร์
          _row('Reference', orderId),
          const Divider(height: 1, color: _C.border),
          _row('Amount', _amount, valueColor: _C.sage, large: true),
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
                  'UniSwap holds your payment and releases it to the seller '
                  'after you confirm the item. No real money moves in this demo.',
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
