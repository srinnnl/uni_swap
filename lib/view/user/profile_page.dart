import 'package:flutter/material.dart';
import 'package:uni_swap/view/user/campus_locations.dart';
import 'bank_account_page.dart';
import 'package:uni_swap/view/login.dart';
import 'package:uni_swap/view/user/request_location_page.dart';

// ---- colors (local to this file) ----
const _cBg = Color(0xFFFAF9F6);
const _cCard = Color(0xFFFFFFFF);
const _cInk = Color(0xFF2B2B26);
const _cMuted = Color(0xFF8A8A82);
const _cBorder = Color(0xFFE6E4DE);
const _cChip = Color(0xFFF0EEE9);
const _cSage = Color(0xFFD8E4DC);
const _cSageDark = Color(0xFF3F6B52);
const _cRedFg = Color(0xFFB3402F);
const _cLink = Color(0xFF4A5C8F);

class ProfilePage extends StatefulWidget {
  /// Show the "Admin dashboard" menu item (role = admin).
  final bool isAdmin;
  const ProfilePage({super.key, this.isAdmin = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Mock data (UI only)
  static const _username = 'mayakim';
  // static const _displayName = 'Maya';

  // 2 โซนตาม DB (location_zones) รายการหอมาจาก campus_locations.dart
  static final _zones = <String, List<String>>{
    for (final z in CampusZone.values)
      z.label: [for (final l in locationsIn(z)) l.name],
  };

  // TODO: โหลดที่พักปัจจุบันของผู้ใช้จาก API (users.residence_location_id)
  String _location = locationsIn(CampusZone.onCampus).first.name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cBg,
      body: SafeArea(bottom: false, child: _buildList()),
    );
  }

  Widget _buildList() {
    return ListView(
      // ท้ายหน้าเว้น 120 ให้พ้นแถบเมนูล่าง
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        Row(
          children: [
            const SizedBox(width: 48),
            const Expanded(
              child: Center(child: _PageHeader(title: 'Profile')),
            ),
            IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: () => _showSnack(context, 'Settings (coming soon)'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Center(
          child: CircleAvatar(
            radius: 36,
            backgroundColor: _cSage,
            child: Text(
              _username[0].toUpperCase(),
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 26,
                color: _cSageDark,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Center(
          child: Text(
            '@$_username',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Center(
          child: Text(
            'Member since 2024',
            style: TextStyle(fontSize: 12, color: _cMuted),
          ),
        ),
        const SizedBox(height: 22),

        _AppCard(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: IntrinsicHeight(
            child: Row(
              children: [
                _stat('12', 'Listings'),
                const VerticalDivider(color: _cBorder, width: 1),
                _stat('8', 'Sold'),
                const VerticalDivider(color: _cBorder, width: 1),
                _stat('4.8', 'Rating'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'My account',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _cInk,
          ),
        ),
        const SizedBox(height: 8),

        _menuTile(
          Icons.location_on_outlined,
          'My location',
          _location,
          _pickLocation,
        ),

        const SizedBox(height: 22),

        _AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  const _IconBox(icon: Icons.credit_card_outlined),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bank account',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'For receiving marketplace payments',
                          style: TextStyle(fontSize: 11, color: _cMuted),
                        ),
                      ],
                    ),
                  ),
                  const _StatusBadge(
                    label: 'Verified',
                    bg: _cSage,
                    fg: _cSageDark,
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: _cBorder),
              ),
              Row(
                children: [
                  const SizedBox(width: 58),
                  const Expanded(
                    child: Text(
                      'Kasikornbank',
                      style: TextStyle(fontSize: 12, color: _cMuted),
                    ),
                  ),
                  const Text(
                    '•••• 4821',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BankAccountPage(),
                      ),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        color: _cLink,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        InkWell(
          onTap: _confirmLogout,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.logout, size: 18, color: _cRedFg),
                SizedBox(width: 10),
                Text(
                  'Log out',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _cInk,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stat(String value, String label) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: _cMuted)),
      ],
    ),
  );

  Widget _menuTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool last = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: _cBorder)),
        ),
        child: Row(
          children: [
            _IconBox(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }

  void _pickLocation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65, // ปรับให้สูงขึ้นนิดนึงเพื่อรองรับเมนูที่เพิ่มมา
        maxChildSize: 0.9,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            const Text(
              'Select your location',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            for (final zone in _zones.entries) ...[
              const SizedBox(height: 18),
              Text(
                zone.key,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _cMuted,
                ),
              ),
              for (final loc in zone.value)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(loc),
                  trailing: loc == _location
                      ? const Icon(Icons.check, color: _cSageDark)
                      : null,
                  onTap: () {
                    setState(() => _location = loc);
                    Navigator.pop(ctx);
                  },
                ),
            ],

            // --- ส่วนที่เพิ่มเข้ามาใหม่: ปุ่ม Request a location ---
            const SizedBox(height: 8),
            const Divider(color: _cBorder),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _cChip,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add_location_alt_outlined,
                  color: _cInk,
                  size: 20,
                ),
              ),
              title: const Text(
                'Request a location',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _cInk,
                ),
              ),
              subtitle: const Text(
                "Can't find where you live?",
                style: TextStyle(fontSize: 12, color: _cMuted),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                size: 20,
                color: _cMuted,
              ),
              onTap: () {
                Navigator.pop(ctx); // ปิด BottomSheet ก่อน
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const RequestLocationPage(), // ลิงก์ไปยังหน้าที่สร้างไว้
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cBg,
        surfaceTintColor: Colors.transparent,
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _cRedFg),
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: ลบ token ที่เก็บไว้
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

// ---- small shared widgets (local to this file) ----
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

class _IconBox extends StatelessWidget {
  final IconData icon;
  final double size;
  const _IconBox({super.key, required this.icon, this.size = 44});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: _cChip,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, size: size * 0.45, color: _cInk),
  );
}

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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
    ),
  );
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
