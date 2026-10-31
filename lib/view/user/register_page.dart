import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _obscurePassword = true; // สำหรับเปิด-ปิดตาช่องรหัสผ่าน

  // วิดเจ็ตตัวช่วยสำหรับสร้าง Label บนช่องกรอกข้อมูล
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 20.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  // วิดเจ็ตตัวช่วยสำหรับสร้าง TextField
  Widget _buildTextField({
    required String hintText,
    bool isPassword = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      obscureText: isPassword ? _obscurePassword : false,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Colors.black38,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black54),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3), // สีพื้นหลังเทาอ่อน
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // ป้องกัน overflow เมื่อคีย์บอร์ดขึ้น
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // โลโก้ 'U'
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'U',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'serif',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ชื่อแอป "UniSwap"
                  const Text(
                    'UniSwap',
                    style: TextStyle(
                      fontSize: 32,
                      color: Color(0xFF333333),
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 8),

                  // สโลแกน
                  const Text(
                    'Good things, closer than you think.',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 32),

                  // การ์ดฟอร์มสมัครสมาชิก
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create your account',
                          style: TextStyle(
                            fontSize: 22,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Join your campus marketplace.',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),

                        // ฟอร์มกรอกข้อมูล
                        _buildLabel('Student ID'),
                        _buildTextField(hintText: 'Student ID'),

                        _buildLabel('Email'),
                        _buildTextField(hintText: 'Email'),

                        _buildLabel('Username'),
                        _buildTextField(hintText: 'Username'),
                        // คำอธิบายใต้ Username
                        const Padding(
                          padding: EdgeInsets.only(top: 6.0),
                          child: Text(
                            'This is how others will see you, e.g. @yourname',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),
                        ),

                        _buildLabel('Password'),
                        _buildTextField(
                          hintText: 'Password',
                          isPassword: true,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.black45,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),

                        _buildLabel('Where do you live?'),
                        // กล่องเลือกที่อยู่ (จำลองเป็นปุ่มกด Dropdown)
                        InkWell(
                          onTap: () {
                            // ใส่ Action เมื่อกดเลือกที่อยู่
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.black54,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'North Campus · Maple Hall',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ปุ่ม Create account
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF333333),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Create account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ลิงก์กลับไปหน้า Sign in (กดเพื่อกลับไปหน้า Login)
                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Already have an account? ',
                                ),
                                TextSpan(
                                  text: 'Sign in',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                  // เพิ่ม Event การกดตรงนี้เพื่อกลับไปหน้า Login
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.pop(
                                        context,
                                      ); // ปิดหน้าต่างนี้กลับไปหน้าก่อนหน้า
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ข้อความเงื่อนไขด้านล่างสุด
                  const Text(
                    'By continuing, you agree to our Terms & Community Guidelines.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
