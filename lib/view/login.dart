import 'package:flutter/material.dart';
import 'package:uni_swap/view/main_screen.dart';
import 'package:uni_swap/view/admin/admin_page.dart';
import 'package:uni_swap/view/user/register_page.dart';

class _C {
  static const bg = Color(0xFFF7F6F2);
  static const ink = Color(0xFF2F2F2B);
  static const muted = Color(0xFF7A7973);
  static const hint = Color(0xFFA9A8A2);
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

  // ===== จำลองการ login (mock) =====
  ({String token, String role}) _mockLogin(String username) {
    final role = username.toLowerCase() == 'admin' ? 'admin' : 'user';
    return (token: 'mock-token-$role', role: role);
  }

  // ===== จุดเชื่อมต่อ API =====
  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameCtrl.text.trim();
    final session = _mockLogin(username);
    debugPrint('login: $username as ${session.role}');

    final Widget home = session.role == 'admin'
        ? const AdminPage()
        : const MainScreen();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => home));
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
            _buildField(
              label: 'Email',
              hint: 'Email',
              controller: _usernameCtrl,
              icon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter your username'
                  : null,
            ),
            _buildField(
              label: 'Password',
              hint: 'Your password',
              controller: _passwordCtrl,
              icon: Icons.lock_outline,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
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
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'New to UniSwap? ',
                    style: TextStyle(fontSize: 14, color: _C.muted),
                  ),
                  GestureDetector(
                    onTap: _goRegister,
                    child: const Text(
                      'Create account',
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

  // ===== ส่วนที่ถูกปรับแต่งความสวยงาม (Polish) =====
  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _C.ink,
            ),
          ),
        ),
        // ใช้ Container หุ้มเพื่อใส่ Effect แสงและเงา
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              // เงาตกกระทบด้านล่าง (Depth) ช่วยให้ฟอร์มดูลอยขึ้นมานิดๆ
              BoxShadow(
                color: _C.ink.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              // แสงสะท้อนด้านบนซ้าย (Glossy Highlight) ทำให้ดูวาว
              BoxShadow(
                color: const Color.fromARGB(
                  255,
                  240,
                  240,
                  240,
                ).withValues(alpha: 0.9),
                blurRadius: 8,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: validator,
            textInputAction: textInputAction,
            onFieldSubmitted: onSubmitted,
            style: const TextStyle(fontSize: 15, color: _C.ink),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _C.hint),
              prefixIcon: Icon(icon, size: 20, color: _C.muted),
              suffixIcon: suffix,
              filled: true,
              // ปรับสีพื้นหลังให้เป็นขาวกึ่งโปร่งแสง ช่วยรับกับแสงสะท้อน
              fillColor: Colors.white.withValues(alpha: 0.85),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              // ปรับสีกรอบตอนยังไม่โฟกัสให้เป็นสีขาวจางๆ เพื่อไม่ให้ดูแข็งเกินไป
              border: border(Colors.transparent),
              enabledBorder: border(Colors.white.withValues(alpha: 0.6)),
              focusedBorder: border(_C.ink, 1.2),
              errorBorder: border(Colors.red.shade300),
              focusedErrorBorder: border(Colors.red.shade400, 1.2),
            ),
          ),
        ),
      ],
    );
  }
}
