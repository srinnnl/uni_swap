import 'package:flutter/material.dart';
import 'admin_categories_page.dart';
import 'admin_items_page.dart';
import 'admin_locations_page.dart';
import 'admin_users_page.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/view/login.dart';

// ---- colors ----
const _cBg = Color(0xFFFAF9F6);
const _cCard = Color(0xFFFFFFFF);
const _cInk = Color(0xFF2B2B26);
const _cMuted = Color(0xFF8A8A82);
const _cBorder = Color(0xFFE6E4DE);
const _cChip = Color(0xFFF0EEE9);
const _cSage = Color(0xFFD8E4DC);
const _cSageDark = Color(0xFF3F6B52);
const _cBlueBg = Color(0xFFE3ECF7);
const _cBlueFg = Color(0xFF3B5E8C);
const _cAmberBg = Color(0xFFFBEBC2);
const _cAmberFg = Color(0xFF8A6410);
const _cRedFg = Color(0xFFB3402F);

class AdminPage extends StatelessWidget {
  final String displayName;

  const AdminPage({super.key, this.displayName = 'Admin'});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            // 1. Header แบบคลีนๆ กึ่งกลาง พร้อมเส้นคั่นด้านล่าง
            const _PageHeader(title: 'Admin', subtitle: 'Marketplace overview'),

            const SizedBox(height: 18),
            const Divider(height: 1, thickness: 1, color: _cBorder),
            const SizedBox(height: 20),

            // 2. Greeting
            Text(
              _formatDate(DateTime.now()),
              style: const TextStyle(fontSize: 12, color: _cMuted),
            ),
            const SizedBox(height: 4),
            Text(
              '$_greeting, $displayName',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _cInk,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 20),

            // 3. Pending approval
            _PendingApprovalCard(
              count: '4',
              onTap: () => _open(context, const AdminItemsPage()),
            ),

            const SizedBox(height: 26),

            // 4. Overview Section
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _cInk,
              ),
            ),
            const SizedBox(height: 12),

            // Statistics Grid
            // TODO: ตัวเลขทั้งหมดในหน้านี้เป็นข้อมูลจำลอง ให้เพื่อนทำ API สรุปตัวเลข (users, items)
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 108,
              ),
              children: [
                _StatCard(
                  icon: Icons.group_outlined,
                  label: 'Users',
                  value: '2,418',
                  note: '+12%',
                  onTap: () => _open(context, const AdminUsersPage()),
                ),
                _StatCard(
                  icon: Icons.location_on_outlined,
                  label: 'Locations',
                  value: '28',
                  note: '4 pending',
                  highlightNote: true,
                  onTap: () => _open(context, const AdminLocationsPage()),
                ),
                _StatCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Items',
                  value: '4',
                  note: 'All items',
                  onTap: () => _open(context, const AdminItemsPage()),
                ),
                _StatCard(
                  icon: Icons.sell_outlined,
                  label: 'Categories',
                  value: '11',
                  note: 'Manage',
                  onTap: () => _open(context, const AdminCategoriesPage()),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // 5. Recent activity
            // ไม่มีตาราง log ใน DB: ดึงจาก timestamp ที่มี (users.created_at, products.reviewed_at, location_requests.resolved_at) หรือตัดส่วนนี้
            const Text(
              'Recent activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _cInk,
              ),
            ),
            const SizedBox(height: 12),

            const _AppCard(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  _ActivityRow(
                    title: 'New location approved',
                    subtitle: 'Westwood Condos · 12 min ago',
                    icon: Icons.check,
                    bg: _cSage,
                    fg: _cSageDark,
                  ),
                  _ActivityRow(
                    title: '14 new users joined',
                    subtitle: 'North Campus · 1 hour ago',
                    icon: Icons.group_outlined,
                    bg: _cBlueBg,
                    fg: _cBlueFg,
                  ),
                  _ActivityRow(
                    title: 'Category updated',
                    subtitle: 'Electronics · 3 hours ago',
                    icon: Icons.sell_outlined,
                    bg: _cAmberBg,
                    fg: _cAmberFg,
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 6. Logout (ย้ายกลับมาไว้ด้านล่างเหมือนเดิม)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: _cCard,
                side: const BorderSide(color: _cBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _confirmLogout(context),
              child: const Text(
                'Log out',
                style: TextStyle(color: _cInk, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Logout confirmation
  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cBg,
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _cRedFg),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    authController.signOut(); // ล้าง token + user ในหน่วยความจำ
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  // Navigation
  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

// ---- Pending approval card ----

class _PendingApprovalCard extends StatelessWidget {
  final String count;
  final VoidCallback onTap;

  const _PendingApprovalCard({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cAmberBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEDDAF)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF5D9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pending_actions_outlined,
                  color: _cAmberFg,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pending Approval',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _cInk,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$count items waiting for your review',
                      style: const TextStyle(fontSize: 12, color: _cAmberFg),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _cInk,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: _cAmberFg),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Stat card ----

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String note;
  final bool highlightNote;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
    this.highlightNote = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _IconBox(icon: icon, size: 30),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _cMuted,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: _cMuted),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _cInk,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                note,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: highlightNote ? FontWeight.w600 : FontWeight.w500,
                  color: highlightNote ? _cAmberFg : _cMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- Activity row ----

class _ActivityRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color bg;
  final Color fg;
  final bool isLast;

  const _ActivityRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bg,
    required this.fg,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: _cBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _cInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: _cMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---- App card ----

class _AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const _AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ---- Icon box ----

class _IconBox extends StatelessWidget {
  final IconData icon;
  final double size;

  const _IconBox({super.key, required this.icon, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _cChip,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: size * 0.55, color: _cInk),
    );
  }
}

// ---- Page header ----

class _PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _PageHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _cInk,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: const TextStyle(fontSize: 13, color: _cMuted)),
        ],
      ],
    );
  }
}

// ---- Helpers ----

String _formatDate(DateTime d) {
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${m[d.month - 1]} ${d.day}, ${d.year}';
}
