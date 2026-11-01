import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:uni_swap/view/main_screen.dart';
import 'package:uni_swap/view/user/register_page.dart';

/// สีและค่าคงที่ของหน้านี้ (ย้ายไป theme กลางของแอปได้ภายหลัง)
class _C {
  static const bg = Color(0xFFF7F6F2); // ครีมอุ่น ตรงกับสเก็ตช์
  static const ink = Color(0xFF2F2F2B);
  static const muted = Color(0xFF7A7973);
  static const border = Color(0xFFE6E4DD);
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // TODO: เรียก API login จริงตรงนี้
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  void _goRegister() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const RegisterPage()),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            // กันการลากเกินขอบแล้วเห็นสีอื่น
            physics: const ClampingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              // ให้เนื้อหาสูงเต็มจอเสมอ -> จัดกลางได้ + พื้นหลังเป็นสีเดียว
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  // จำกัดความกว้างบนแท็บเล็ต/เว็บ
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _Header(),
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
              'Welcome back',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: _C.ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sign in to your campus marketplace.',
              style: TextStyle(fontSize: 14, color: _C.muted),
            ),
            const SizedBox(height: 28),
            _AppTextField(
              label: 'Username',
              hint: 'Your Username',
              controller: _usernameCtrl,
              icon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter your username'
                  : null,
            ),
            const SizedBox(height: 20),
            _AppTextField(
              label: 'Password',
              hint: 'Your password',
              controller: _passwordCtrl,
              icon: Icons.lock_outline,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _submit(),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter your password' : null,
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
                  'Sign in',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 14, color: _C.muted),
                  children: [
                    const TextSpan(text: 'New to UniSwap? '),
                    TextSpan(
                      text: 'Create account',
                      style: const TextStyle(
                        color: _C.ink,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = _goRegister,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
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
}

/// ช่องกรอกข้อความ ใช้ซ้ำได้ (หน้า Register ก็เอาไปใช้ต่อได้)
class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _C.ink,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          onFieldSubmitted: onSubmitted,
          style: const TextStyle(fontSize: 15, color: _C.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFA9A8A2)),
            prefixIcon: Icon(icon, size: 20, color: _C.muted),
            suffixIcon: suffix,
            filled: true,
            fillColor: _C.bg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: _border(_C.border),
            enabledBorder: _border(_C.border),
            focusedBorder: _border(_C.ink, 1.5),
            errorBorder: _border(Colors.red.shade300),
            focusedErrorBorder: _border(Colors.red.shade400, 1.5),
          ),
        ),
      ],
    );
  }
}
