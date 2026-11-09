import 'package:flutter/material.dart';
import 'admin_categories_page.dart';
import 'admin_items_page.dart';
import 'admin_locations_page.dart';
import 'admin_reports_page.dart';
import 'admin_users_page.dart';
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
const _cRedBg = Color(0xFFF8DADA);
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // Header
            Row(
              children: [
                const SizedBox(width: 40),
                const Expanded(
                  child: _PageHeader(
                    title: 'Admin',
                    subtitle: 'Marketplace overview',
                  ),
                ),
                Container(
                  width: 40,
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.circle, size: 10, color: _cSageDark),
                ),
              ],
            ),

            const SizedBox(height: 26),

            // Greeting
            Text(
              _formatDate(DateTime.now()),
              style: const TextStyle(fontSize: 11, color: _cMuted),
            ),
            const SizedBox(height: 8),

            Text(
              '$_greeting, $displayName',
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: _cInk,
              ),
            ),

            const SizedBox(height: 12),

            const Align(
              alignment: Alignment.centerLeft,
              child: _StatusBadge(
                label: 'All systems normal',
                bg: _cSage,
                fg: _cSageDark,
              ),
            ),

            const SizedBox(height: 28),

            // Overview
            const Text(
              'Overview',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _cInk,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'A quick look at your marketplace',
              style: TextStyle(fontSize: 11, color: _cMuted),
            ),
            const SizedBox(height: 16),

            // Statistics
            // TODO: ตัวเลขทั้งหมดในหน้านี้เป็นข้อมูลจำลอง ให้เพื่อนทำ API สรุปตัวเลข (users, items, reports ที่ pending)
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 140,
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

            const SizedBox(height: 12),

            // Pending approval - highlighted card
            _PendingApprovalCard(
              count: '4',
              onTap: () => _open(context, const AdminItemsPage()),
            ),

            const SizedBox(height: 30),

            // Needs attention
            _sectionHeader('Needs attention', 'View all'),
            const SizedBox(height: 14),

           
            const SizedBox(height: 12),

            _AppCard(
              onTap: () => _open(context, const AdminItemsPage()),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: _cAmberBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fact_check_outlined,
                      color: _cAmberFg,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '4 items awaiting review',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _cInk,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Approve new items before they go live',
                          style: TextStyle(fontSize: 11, color: _cMuted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: _cMuted),
                ],
              ),
            ),

            const SizedBox(height: 12),

            _AppCard(
              onTap: () => _open(context, const AdminReportsPage()),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 23,
                    backgroundColor: _cRedBg,
                    child: Icon(Icons.flag_outlined, color: _cRedFg, size: 22),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reports to review',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _cInk,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Check problems reported by buyers and sellers',
                          style: TextStyle(fontSize: 11, color: _cMuted),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: _cMuted),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Recent activity
            // ไม่มีตาราง log ใน DB: ดึงจาก timestamp ที่มี (users.created_at, products.reviewed_at, location_requests.resolved_at) หรือตัดส่วนนี้
            _sectionHeader('Recent activity', ''),
            const SizedBox(height: 8),

            const _ActivityRow(
              title: 'New location approved',
              subtitle: 'Westwood Condos · 12 min ago',
              icon: Icons.check,
              bg: _cSage,
              fg: _cSageDark,
            ),
            const _ActivityRow(
              title: '14 new users joined',
              subtitle: 'North Campus · 1 hour ago',
              icon: Icons.group_outlined,
              bg: _cBlueBg,
              fg: _cBlueFg,
            ),
            const _ActivityRow(
              title: 'Category updated',
              subtitle: 'Electronics · 3 hours ago',
              icon: Icons.sell_outlined,
              bg: _cAmberBg,
              fg: _cAmberFg,
            ),

            const SizedBox(height: 28),

            // Logout
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

    // TODO: Remove stored token
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  // Navigation
  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  // Section header
  Widget _sectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _cInk,
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            fontSize: 12,
            decoration: TextDecoration.underline,
            color: _cInk,
          ),
        ),
      ],
    );
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
                width: 46,
                height: 46,
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
                    const SizedBox(height: 4),
                    const Text(
                      'Items waiting for your review',
                      style: TextStyle(fontSize: 11, color: _cAmberFg),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$count submissions need approval',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _cInk,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Text(
                    count,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: _cInk,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: _cAmberFg),
                ],
              ),
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
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBox(icon: icon, size: 40),
          const Spacer(),
          Text(label, style: const TextStyle(fontSize: 11, color: _cMuted)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: _cInk,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Text(
                  note,
                  style: const TextStyle(fontSize: 10, color: _cMuted),
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

  const _ActivityRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _cBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: fg),
          ),
          const SizedBox(width: 14),
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
                const SizedBox(height: 3),
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: size * 0.45, color: _cInk),
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
            fontSize: 20,
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

// ---- Status badge ----

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _StatusBadge({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
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

void _showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _cInk,
      ),
    );
}
