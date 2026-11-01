import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uni_swap/view/user/home_page.dart';
import 'package:uni_swap/view/user/search_page.dart';

class _C {
  static const bg = Color(0xFFFAF9F6);
  static const ink = Color(0xFF2F2F2B);
  static const muted = Color(0xFF8C8B84);
  static const border = Color(0xFFE6E4DD);
}

// ===== ค่าปรับแต่งหน้าตาแถบเมนู =====
const _blurAmount = 30.0; // เพิ่มความเบลอให้พื้นหลังฟุ้งละมุนขึ้น
const _barOpacity = 0.1; // ลดความขาวทึบลง (ค่ายิ่งน้อยยิ่งใส 0.3 คือทึบ 30%)
const _barTop = 16.0;
const _areaHeight = 80.0;
const _btnTop = 1.0;
const _btnRadius = 26.0;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final int _ordersBadge = 0;

  final List<Widget> _pages = const [
    HomePage(),
    SearchPage(),
    Center(child: Text('Sell Page')),
    Center(child: Text('Orders Page')),
    Center(child: Text('Profile Page')),
  ];

  void _onTap(int index) {
    if (index == _selectedIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _BottomBar(
        currentIndex: _selectedIndex,
        ordersBadge: _ordersBadge,
        onTap: _onTap,
      ),
    );
  }
}

class _BarBackground extends StatelessWidget {
  const _BarBackground();

  @override
  Widget build(BuildContext context) {
    // ใช้พื้นหลังเรียบๆ ตัดเส้นขอบบางๆ ให้ดูคลีนที่สุด (ไม่มีรอยเว้าให้รก)
    return Positioned.fill(
      top: _barTop,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurAmount, sigmaY: _blurAmount),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: _barOpacity),
              border: const Border(
                top: BorderSide(color: _C.border, width: 1.0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentIndex,
    required this.ordersBadge,
    required this.onTap,
  });

  final int currentIndex;
  final int ordersBadge;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: _areaHeight + inset,
      child: Stack(
        children: [
          const _BarBackground(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _areaHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _NavItem(
                  label: 'Home',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  active: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  label: 'Search',
                  icon: Icons.search,
                  activeIcon: Icons.search,
                  active: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                _SellButton(active: currentIndex == 2, onTap: () => onTap(2)),
                _NavItem(
                  label: 'Orders',
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  active: currentIndex == 3,
                  badge: ordersBadge,
                  onTap: () => onTap(3),
                ),
                _NavItem(
                  label: 'Profile',
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  active: currentIndex == 4,
                  onTap: () => onTap(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.onTap,
    this.badge = 0,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // กลับมาใช้โทน ขาว-ดำ-เทา แบบต้นฉบับ
    final color = active ? _C.ink : _C.muted;

    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: _areaHeight - _barTop,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      width: active ? 56 : 32,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active
                            ? _C.ink.withValues(
                                alpha: 0.06,
                              ) // ไฮไลท์ตอน Active สีเทาอ่อนๆ
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        active ? activeIcon : icon,
                        size: 24,
                        color: color,
                      ),
                    ),
                    if (badge > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 16),
                          height: 16,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            badge > 9 ? '9+' : '$badge',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: color,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SellButton extends StatefulWidget {
  const _SellButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  State<_SellButton> createState() => _SellButtonState();
}

class _SellButtonState extends State<_SellButton> {
  bool _pressed = false;

  void _setPressed(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: widget.active,
        label: 'Sell',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.onTap,
          child: SizedBox(
            height: _areaHeight,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: _btnTop,
                  child: AnimatedScale(
                    scale: _pressed ? 0.9 : 1,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    child: Container(
                      width: _btnRadius * 2,
                      height: _btnRadius * 2,
                      decoration: BoxDecoration(
                        color: _C.ink,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _C.ink.withValues(
                              alpha: 0.20,
                            ), // เงาปุ่มนุ่มๆ
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 9,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: widget.active
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: widget.active ? _C.ink : _C.muted,
                    ),
                    child: const Text('Sell'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
