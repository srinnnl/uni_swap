import 'package:flutter/material.dart';
import 'package:uni_swap/model/format.dart';
// ไฟล์นี้ใช้งานได้ด้วยตัวเอง: หน้ารายงานปัญหาของออเดอร์ (เปิดจาก Order details > Report a problem)
// กด Submit แล้วจะ pop กลับพร้อมค่า true

class _C {
  static const bg = Color(0xFFFAF9F6);
  static const ink = Color(0xFF2F2F2B);
  static const muted = Color(0xFF7A7973);
  static const faint = Color(0xFFA9A8A2);
  static const border = Color(0xFFE6E4DD);
  static const surface = Color(0xFFF3F2EE);
  static const red = Color(0xFFB3402F);
}

class ReportProductPage extends StatefulWidget {
  const ReportProductPage({
    super.key,
    required this.orderId,
    required this.productTitle,
    required this.price,
    required this.personName,
    this.imageUrl,
  });

  final int orderId; // reports.order_id
  final String productTitle;
  final double price;
  final String personName; // อีกฝ่ายของออเดอร์ (ผู้ขาย หรือ ผู้ซื้อ)
  final String? imageUrl;

  @override
  State<ReportProductPage> createState() => _ReportProductPageState();
}

class _ReportProductPageState extends State<ReportProductPage> {
  // (ค่าที่ส่ง API, ข้อความที่แสดง)
  // ค่าเหล่านี้ตรงกับ enum reports.report_type ใน DB และหน้า Admin > Reports
  static const _reasons = <(String, String)>[
    ('product_problem', 'Problem with the item'),
    ('seller_problem', 'Problem with the seller / buyer'),
    ('payment_problem', 'Payment problem'),
    ('refund_problem', 'Refund problem'),
    ('other', 'Other'),
  ];

  final _detailsCtrl = TextEditingController();
  int _reason = 0;
  String? _error;

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  // ===== จุดเชื่อมต่อ API: ให้เพื่อนแก้ฟังก์ชันนี้ =====
  void _submit() {
    final details = _detailsCtrl.text.trim();
    if (_reasons[_reason].$1 == 'other' && details.length < 5) {
      setState(() => _error = 'Please tell us what happened');
      return;
    }

    // TODO: ส่งไป API (ตาราง reports): order_id: widget.orderId, report_type: _reasons[_reason].$1,
    //   reason: details (NOT NULL ส่ง '' ได้ถ้าไม่ได้กรอก), status เริ่มต้น = pending
    // (admin จะเห็นในหน้า Reports และจัดกลุ่มตามสินค้าของออเดอร์)
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildProductCard(),
            const SizedBox(height: 24),
            const Text(
              'Why are you reporting this?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _C.ink,
              ),
            ),
            const SizedBox(height: 10),
            _buildReasons(),
            const SizedBox(height: 24),
            const Text(
              'Additional details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _C.ink,
              ),
            ),
            const SizedBox(height: 10),
            _buildDetails(),
            const SizedBox(height: 8),
            const Text(
              'Do not include sensitive personal information.',
              style: TextStyle(fontSize: 12, color: _C.muted),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _C.ink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Submit report',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                'Report a problem',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _C.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.productTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: _C.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildProductCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 64,
              height: 64,
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
                Text(
                  widget.productTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatPriceTHB(widget.price)} · ${widget.personName}',
                  style: const TextStyle(fontSize: 11, color: _C.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < _reasons.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _C.border),
            InkWell(
              onTap: () => setState(() {
                _reason = i;
                _error = null;
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 17,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _reasons[i].$2,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _C.ink,
                        ),
                      ),
                    ),
                    _RadioDot(selected: i == _reason),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetails() {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );

    return TextField(
      controller: _detailsCtrl,
      minLines: 4,
      maxLines: 6,
      maxLength: 500,
      textCapitalization: TextCapitalization.sentences,
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
      style: const TextStyle(fontSize: 14, color: _C.ink),
      decoration: InputDecoration(
        hintText: 'Tell us what happened...',
        hintStyle: const TextStyle(color: _C.faint),
        errorText: _error,
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        border: border(_C.border),
        enabledBorder: border(_C.border),
        focusedBorder: border(_C.ink, 1.5),
        errorBorder: border(_C.red),
        focusedErrorBorder: border(_C.red, 1.5),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    width: 22,
    height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: selected ? _C.ink : _C.border,
        width: selected ? 2 : 1.5,
      ),
    ),
    child: selected
        ? Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: _C.ink,
              shape: BoxShape.circle,
            ),
          )
        : null,
  );
}
