import 'package:flutter/material.dart';

// ---- colors (local to this file) ----
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: _PageHeader(
                    title: 'Admin', subtitle: 'Marketplace overview'),
              ),
              const SizedBox(
                width: 48,
                child: Icon(Icons.circle, size: 10, color: _cSageDark),
              ),
            ]),
            const SizedBox(height: 22),

            Text(_formatDate(DateTime.now()),
                style: const TextStyle(fontSize: 11, color: _cMuted)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Text('$_greeting, $displayName',
                    style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 26,
                        fontWeight: FontWeight.w500)),
              ),
              const _StatusBadge(
                  label: 'All systems normal',
                  bg: _cSage,
                  fg: _cSageDark),
            ]),
            const SizedBox(height: 20),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.35,
              children: [
                _StatCard(
                    icon: Icons.group_outlined,
                    label: 'Users',
                    value: '2,418',
                    note: '+12%',
                    onTap: () => _showSnack(context, 'Manage users (later)')),
                _StatCard(
                    icon: Icons.flag_outlined,
                    label: 'Reports',
                    value: '3',
                    note: 'Review',
                    onTap: () => _showSnack(context, 'Reports (later)')),
                _StatCard(
                    icon: Icons.location_on_outlined,
                    label: 'Locations',
                    value: '28',
                    note: '4 pending',
                    onTap: () => _showSnack(context, 'Locations (later)')),
                _StatCard(
                    icon: Icons.sell_outlined,
                    label: 'Categories',
                    value: '12',
                    note: 'Updated',
                    onTap: () => _showSnack(context, 'Categories (later)')),
              ],
            ),
            const SizedBox(height: 26),

            _sectionHeader('Needs attention', 'View all'),
            const SizedBox(height: 12),
            _AppCard(
              onTap: () => _showSnack(context, 'Reported products (later)'),
              child: Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                      color: _cRedBg, shape: BoxShape.circle),
                  child: const Icon(Icons.priority_high,
                      color: _cRedFg, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('3 reported products',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      SizedBox(height: 3),
                      Text('Review community reports',
                          style: TextStyle(
                              fontSize: 11, color: _cMuted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ]),
            ),
            const SizedBox(height: 26),

            _sectionHeader('Recent activity', 'See log'),
            const SizedBox(height: 4),
            const _ActivityRow(
                title: 'New location approved',
                subtitle: 'Westwood Condos · 12 min ago',
                icon: Icons.check,
                bg: _cSage,
                fg: _cSageDark),
            const _ActivityRow(
                title: '14 new users joined',
                subtitle: 'North Campus · 1 hour ago',
                icon: Icons.group_outlined,
                bg: _cBlueBg,
                fg: _cBlueFg),
            const _ActivityRow(
                title: 'Category updated',
                subtitle: 'Electronics · 3 hours ago',
                icon: Icons.sell_outlined,
                bg: _cAmberBg,
                fg: _cAmberFg),
            const SizedBox(height: 22),

            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: _cCard,
                side: const BorderSide(color: _cBorder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Open marketplace',
                  style: TextStyle(
                      color: _cInk, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String action) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          Text(action,
              style: const TextStyle(
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                  color: _cInk)),
        ],
      );
}

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
          Text(label,
              style: const TextStyle(fontSize: 11, color: _cMuted)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 26,
                      fontWeight: FontWeight.w600)),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(note,
                    style: const TextStyle(
                        fontSize: 10, color: _cMuted)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
          border: Border(bottom: BorderSide(color: _cBorder))),
      child: Row(children: [
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
              Text(title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style:
                      const TextStyle(fontSize: 11, color: _cMuted)),
            ],
          ),
        ),
      ]),
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
            color: _cChip, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: size * 0.45, color: _cInk),
      );
}

class _PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _PageHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(title,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700, color: _cInk)),
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        Text(subtitle!,
            style: const TextStyle(fontSize: 13, color: _cMuted)),
      ],
    ]);
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _StatusBadge(
      {super.key, required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
      );
}

String _formatDate(DateTime d) {
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${m[d.month - 1]} ${d.day}, ${d.year}';
}

void _showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _cInk,
    ));
}
