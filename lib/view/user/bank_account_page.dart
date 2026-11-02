import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ไฟล์นี้ใช้งานได้ด้วยตัวเอง: หน้าตั้งค่าบัญชีธนาคารสำหรับรับเงิน (ผู้ขาย)
// บัญชีนี้ใช้ให้ UniSwap โอนเงินให้ผู้ขาย (payout) หลังผู้ซื้อยืนยันรับของ
// ผู้ซื้อไม่เห็นบัญชีนี้ (ผู้ซื้อโอนเข้าบัญชีกลางของแพลตฟอร์มแทน)
// หมายเหตุ: ข้อมูลในหน้านี้เป็นค่าจำลอง ตอนเดโมอย่าใช้เลขบัญชีจริง

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
}

class BankAccountPage extends StatefulWidget {
  const BankAccountPage({super.key});

  @override
  State<BankAccountPage> createState() => _BankAccountPageState();
}

class _BankAccountPageState extends State<BankAccountPage> {
  static const _banks = [
    'Kasikornbank',
    'Siam Commercial Bank',
    'Bangkok Bank',
    'Krungthai Bank',
    'Krungsri (Bank of Ayudhya)',
    'ttb (TMBThanachart)',
    'Government Savings Bank',
  ];

  final _formKey = GlobalKey<FormState>();
  // TODO: โหลดบัญชีปัจจุบันของผู้ใช้จาก API
  final _numberCtrl = TextEditingController(text: '1234564821');
  final _nameCtrl = TextEditingController(text: 'Maya Kim');

  String _bank = _banks.first;
  bool _verified = true; // หลังแก้ไข/บันทึก จะกลับเป็นรอตรวจสอบ
  bool _bankError = false;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  String get _masked {
    final n = _numberCtrl.text;
    return n.length < 4 ? n : '•••• ${n.substring(n.length - 4)}';
  }

  Future<void> _pickBank() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final b in _banks)
              ListTile(
                title: Text(b),
                trailing:
                    b == _bank ? const Icon(Icons.check, color: _C.ink) : null,
                onTap: () => Navigator.pop(context, b),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _bank = picked);
  }

  // ===== จุดเชื่อมต่อ API: ให้เพื่อนแก้ฟังก์ชันนี้ =====
  void _save() {
    final ok = _formKey.currentState!.validate();
    setState(() => _bankError = false);
    if (!ok) return;

    // TODO: ส่ง bank, number, name ไป API
    // backend ควรตรวจว่าชื่อบัญชีตรงกับชื่อผู้ใช้ที่ลงทะเบียน แล้วตั้งสถานะ pending
    // ห้ามเก็บเลขบัญชีเป็นข้อความธรรมดาโดยไม่เข้ารหัส
    setState(() => _verified = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Saved. We will verify your account.')),
      );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildCurrentCard(),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Bank'),
                  _buildBankPicker(),
                  const SizedBox(height: 20),
                  _label('Account number'),
                  TextFormField(
                    controller: _numberCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 12,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => (v == null || v.length < 10)
                        ? 'Enter 10 to 12 digits'
                        : null,
                    decoration: _dec('e.g. 1234567890'),
                  ),
                  const SizedBox(height: 12),
                  _label('Account name'),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().length < 2)
                        ? 'Enter the account holder name'
                        : null,
                    decoration: _dec('Name on the bank account'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildNotice(),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _C.ink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Save bank account',
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
        const Expanded(
          child: Column(
            children: [
              Text(
                'Bank account',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _C.ink,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Where UniSwap sends your earnings',
                style: TextStyle(fontSize: 13, color: _C.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildCurrentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.credit_card_outlined, color: _C.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current account',
                  style: TextStyle(fontSize: 11, color: _C.muted),
                ),
                const SizedBox(height: 3),
                Text(
                  '$_bank · $_masked',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.ink,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _verified ? _C.sageBg : _C.amberBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _verified ? 'Verified' : 'Pending',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _verified ? _C.sage : _C.amberFg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankPicker() {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _bankError ? _C.red : _C.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _pickBank,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _bank,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _C.ink,
                  ),
                ),
              ),
              const Icon(Icons.expand_more, color: _C.muted),
            ],
          ),
        ),
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
          Icon(Icons.lock_outline, size: 20, color: _C.sage),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kept private',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _C.ink,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Buyers never see these details. UniSwap sends your earnings '
                  'here after the buyer confirms the item. The account name '
                  'should match your own name.',
                  style: TextStyle(fontSize: 12, height: 1.4, color: _C.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          t,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _C.ink,
          ),
        ),
      );

  InputDecoration _dec(String hint) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _C.faint),
      counterText: '',
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: b(_C.border),
      enabledBorder: b(_C.border),
      focusedBorder: b(_C.ink, 1.5),
      errorBorder: b(_C.red),
      focusedErrorBorder: b(_C.red, 1.5),
    );
  }
}
