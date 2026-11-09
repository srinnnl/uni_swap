import 'package:flutter/material.dart';
import 'package:uni_swap/view/user/campus_locations.dart';

class _C {
  static const bg = Color(0xFFF7F6F2);
  static const ink = Color(0xFF2F2F2B);
  static const muted = Color(0xFF7A7973);
  static const hint = Color(0xFFA9A8A2);
  static const border = Color(0xFFE6E4DD);
}

/// ตัวเลือกสำหรับคนที่หาที่พักของตัวเองไม่เจอ (ส่งให้ admin ตรวจสอบ)
const _otherOption = 'Other (not listed)';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _customResidenceCtrl = TextEditingController(); // ที่พักที่พิมพ์เอง

  bool _obscure = true;
  // ที่พัก: _zone + _location (null + มี _zone = เลือก Other รอแอดมินตรวจ)
  CampusZone? _zone;
  CampusLocation? _location;

  bool get _isOther => _zone != null && _location == null;
  String? get _residenceLabel =>
      _zone == null ? null : (_location?.name ?? _otherOption);
  bool _residenceError = false;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _studentIdCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _customResidenceCtrl.dispose();
    super.dispose();
  }

  // ===== จุดเชื่อมต่อ API: ให้เพื่อนแก้ฟังก์ชันนี้ =====
  void _submit() {
    final formOk = _formKey.currentState!.validate();
    setState(() => _residenceError = _zone == null);
    if (!formOk || _zone == null) return;

    final isOther = _isOther;
    final data = {
      // users.display_name (UI โชว์ชื่อเต็มคู่กับ @username ทั้งแอป)
      'fullName': _fullNameCtrl.text.trim(),
      'studentId': _studentIdCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'username': _usernameCtrl.text.trim(),
      'password': _passwordCtrl.text,
      // ถ้าเลือก Other: residence เป็น null และส่งชื่อที่พิมพ์เองให้ admin ตรวจ
      // backend ควรเก็บเป็นสถานะ pending (approved / merged / rejected ภายหลัง)
      // users.residence_zone / residence_location_id (ต้องรอเพื่อน ALTER ตาม alter_request.sql)
      // ส่ง zone เป็น code ('on_campus' / 'off_campus') ตรงกับ enum ใน DB
      'residenceZone': _zone!.code,
      'residenceLocationId': _location?.id,
      'customResidence': isOther ? _customResidenceCtrl.text.trim() : null,
    };
    debugPrint('register: ${data['username']} (pending: $isOther)');

    // TODO: ส่ง data ไปที่ API สมัครสมาชิก แล้วค่อยกลับหน้า Login เมื่อสำเร็จ
    //   ผู้สมัครใหม่ได้ users.status='pending' (ไม่มี OTP) ต้องรอ admin อนุมัติก่อนเข้าใช้ได้
    //   studentId ส่งเป็นข้อความ (DB ควรเป็น CHAR(10)) ถ้า email/username/studentId ซ้ำ
    //   API จะตอบ error ให้แสดงใต้ช่องที่ซ้ำ
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isOther
              ? 'Account created! An admin will review your account and residence before you can sign in.'
              : 'Account created! You can sign in once an admin approves it.',
        ),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _pickResidence() async {
    final picked = await showCampusLocationPicker(
      context,
      zone: _zone,
      selected: _location,
      otherLabel: _otherOption,
    );
    if (picked != null) {
      setState(() {
        _zone = picked.zone;
        _location = picked.location;
        _residenceError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildCard(),
                        const SizedBox(height: 28),
                        const Text(
                          'By continuing, you agree to our Terms & Community Guidelines.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: _C.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _C.ink,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'U',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w600,
              fontFamily: 'serif',
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'UniSwap',
          style: TextStyle(
            fontSize: 34,
            color: _C.ink,
            fontFamily: 'serif',
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Good things, closer than you think.',
          style: TextStyle(fontSize: 14, color: _C.muted),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: _C.ink.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create your account',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: _C.ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Join your campus marketplace.',
              style: TextStyle(fontSize: 14, color: _C.muted),
            ),
            _buildField(
              label: 'Full name',
              hint: 'e.g. Maya Kim',
              helper: 'Shown on your profile and to people you trade with',
              controller: _fullNameCtrl,
              icon: Icons.person_outline,
              validator: (v) {
                final text = v?.trim() ?? '';
                if (text.length < 2) return 'Enter your full name';
                if (text.length > 100) return 'Too long (max 100 characters)';
                return null;
              },
            ),
            _buildField(
              label: 'Student ID',
              hint: 'Your student ID',
              controller: _studentIdCtrl,
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              // DB: student_id เป็น CHAR(10)
              validator: (v) => RegExp(r'^\d{10}$').hasMatch(v?.trim() ?? '')
                  ? null
                  : 'Student ID must be 10 digits',
            ),
            _buildField(
              label: 'Email',
              hint: 'Your Email',
              controller: _emailCtrl,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final text = v?.trim() ?? '';
                if (text.isEmpty) return 'Enter your email';
                final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
                return ok ? null : 'Enter a valid email';
              },
            ),
            _buildField(
              label: 'Username',
              hint: 'yourname',
              helper: 'This is how others will see you, e.g. @yourname',
              controller: _usernameCtrl,
              icon: Icons.alternate_email,
              validator: (v) {
                final text = v?.trim() ?? '';
                if (text.length < 3) return 'At least 3 characters';
                if (text.length > 30) return 'Too long (max 30 characters)';
                if (!RegExp(r'^[A-Za-z0-9_.]+$').hasMatch(text)) {
                  return 'Use letters, numbers, _ or . only';
                }
                return null;
              },
            ),
            _buildField(
              label: 'Password',
              hint: 'At least 8 characters',
              controller: _passwordCtrl,
              icon: Icons.lock_outline,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              validator: (v) =>
                  (v == null || v.length < 8) ? 'At least 8 characters' : null,
              suffix: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: _C.muted,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            _buildResidenceField(),
            if (_isOther)
              _buildField(
                label: 'Your residence name',
                hint: 'e.g. Sunrise Apartment',
                helper:
                    'An admin will review it. You can keep using the app meanwhile.',
                controller: _customResidenceCtrl,
                icon: Icons.add_location_alt_outlined,
                validator: (v) {
                  final text = v?.trim() ?? '';
                  if (text.length < 3) return 'At least 3 characters';
                  if (text.length > 60) return 'Too long (max 60 characters)';
                  return null;
                },
              ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
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
                  'Create account',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(fontSize: 14, color: _C.muted),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Sign in',
                      style: TextStyle(
                        fontSize: 14,
                        color: _C.ink,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _C.ink,
      ),
    ),
  );

  OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: c, width: w),
  );

  // ช่องกรอกพร้อม label
  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    String? helper,
    bool obscureText = false,
    Widget? suffix,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _C.ink.withValues(alpha: 0.015),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(-1, -1),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: validator,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            style: const TextStyle(fontSize: 15, color: _C.ink),
            decoration: InputDecoration(
              hintText: hint,
              helperText: helper,
              helperStyle: const TextStyle(fontSize: 12, color: _C.muted),
              hintStyle: const TextStyle(color: _C.hint),
              prefixIcon: Icon(icon, size: 20, color: _C.muted),
              suffixIcon: suffix,
              filled: true,
              fillColor: const Color(0xFFF8F7F2),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: _border(Colors.transparent),
              enabledBorder: _border(const Color(0xFFE5E0D6)),
              focusedBorder: _border(_C.ink, 1.5),
              errorBorder: _border(Colors.red.shade300),
              focusedErrorBorder: _border(Colors.red.shade400, 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ช่องเลือกที่พัก (กดแล้วเปิดรายการ)
  Widget _buildResidenceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Where do you live?'),
        InkWell(
          onTap: _pickResidence,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: _C.bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _residenceError ? Colors.red.shade300 : _C.border,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: _C.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _residenceLabel ?? 'Select your residence',
                    style: TextStyle(
                      fontSize: 15,
                      color: _zone == null ? _C.hint : _C.ink,
                    ),
                  ),
                ),
                const Icon(Icons.expand_more, color: _C.muted),
              ],
            ),
          ),
        ),
        if (_residenceError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 16),
            child: Text(
              'Please select your residence',
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          ),
      ],
    );
  }
}
