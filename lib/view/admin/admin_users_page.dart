import 'package:flutter/material.dart';

// ---- colors (local to this file) ----
const _cBg = Color(0xFFFAF9F6);
const _cCard = Color(0xFFFFFFFF);
const _cInk = Color(0xFF2B2B26);
const _cMuted = Color(0xFF8A8A82);
const _cBorder = Color(0xFFE6E4DE);
const _cSage = Color(0xFFD8E4DC);
const _cSageDark = Color(0xFF3F6B52);
const _cBlueBg = Color(0xFFE3ECF7);
const _cBlueFg = Color(0xFF3B5E8C);
const _cAmberBg = Color(0xFFFBEBC2);
const _cAmberFg = Color(0xFF8A6410);
const _cRedBg = Color(0xFFF8DADA);
const _cRedFg = Color(0xFFB3402F);

// users.status ใน DB (ส่วน role = 'admin' แยกเป็น isAdmin)
enum _UStatus { pending, active, suspended, rejected }

class _User {
  final int id; // users.user_id
  final String name; // users.display_name
  final String handle; // users.username
  final String studentId; // users.student_id (เก็บเป็นข้อความ รักษาเลข 0 นำหน้า)
  final String email;
  final bool isAdmin; // users.role == 'admin'
  _UStatus status;
  _User(
    this.id,
    this.name,
    this.handle,
    this.studentId,
    this.email,
    this.status, {
    this.isAdmin = false,
  });
}

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  static const _filters = [
    'All',
    'Admin',
    'Active',
    'Pending',
    'Suspended',
    'Rejected',
  ];

  // Mock data (UI only)
  // TODO: โหลดจาก API (users) ผู้สมัครใหม่เป็น pending รอ admin อนุมัติ (ไม่มี OTP)
  final List<_User> _users = [
    _User(1, 'Maya Kim', 'mayakim', '6731501001', 'admin@lamduan.mfu.ac.th',
        _UStatus.active,
        isAdmin: true),
    _User(2, 'Jamie Lee', 'jamielee', '6731501002', 'jamie@lamduan.mfu.ac.th',
        _UStatus.active),
    _User(3, 'Noah Park', 'noahp', '6731501003', 'noah@lamduan.mfu.ac.th',
        _UStatus.active),
    _User(4, 'Alex Smith', 'alexs', '6731501004', 'alex@lamduan.mfu.ac.th',
        _UStatus.pending),
    _User(5, 'Pim Chai', 'pimc', '6731501005', 'pim@lamduan.mfu.ac.th',
        _UStatus.rejected),
  ];

  String _query = '';
  String _filter = 'All';

  // แอดมินแสดงเป็น Admin เสมอ นอกนั้นแสดงตาม users.status
  String _label(_User u) {
    if (u.isAdmin) return 'Admin';
    return switch (u.status) {
      _UStatus.pending => 'Pending',
      _UStatus.active => 'Active',
      _UStatus.suspended => 'Suspended',
      _UStatus.rejected => 'Rejected',
    };
  }

  (Color, Color) _colors(_User u) {
    if (u.isAdmin) return (_cBlueBg, _cBlueFg);
    return switch (u.status) {
      _UStatus.pending => (_cAmberBg, _cAmberFg),
      _UStatus.active => (_cSage, _cSageDark),
      _UStatus.suspended || _UStatus.rejected => (_cRedBg, _cRedFg),
    };
  }

  List<_User> get _visible {
    final q = _query.trim().toLowerCase();
    return _users.where((u) {
      final matchQ =
          q.isEmpty ||
          u.name.toLowerCase().contains(q) ||
          u.handle.toLowerCase().contains(q) ||
          u.studentId.contains(q) ||
          u.email.toLowerCase().contains(q);
      final matchF = _filter == 'All' || _label(u) == _filter;
      return matchQ && matchF;
    }).toList();
  }

  Future<void> _openFilter() async {
    final r = await _pickFilter(context, _filter, _filters);
    if (r != null) setState(() => _filter = r);
  }

  // เปลี่ยนสถานะผู้ใช้ แล้วปิดชีต + แจ้งผล
  // TODO: เรียก API แทน setState
  //   approve: status='active', verified_by=admin, verified_at=now
  //   reject:  status='rejected'
  //   suspend / restore: status='suspended' / 'active'
  //   กฎ suspend: login ไม่ได้, API ซ่อนสินค้าของผู้ใช้ที่ status != active ตอนอ่าน (ไม่แก้ products.status)
  //   ออเดอร์ที่ค้างอยู่ดำเนินต่อได้ แต่สร้างออเดอร์ใหม่ไม่ได้
  void _setStatus(BuildContext ctx, _User u, _UStatus next, String message) {
    setState(() => u.status = next);
    Navigator.pop(ctx);
    _snack(context, '${u.name} $message (mock)');
  }

  void _openUser(_User u) {
    final (bg, fg) = _colors(u);
    _showSheet(context, (ctx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBox(
                icon: Icons.group_outlined,
                bg: _cSage,
                fg: _cSageDark,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '@${u.handle}',
                      style: const TextStyle(fontSize: 12, color: _cMuted),
                    ),
                  ],
                ),
              ),
              _Badge(label: _label(u), bg: bg, fg: fg),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow('Student ID', u.studentId),
          const Divider(height: 1, color: _cBorder),
          _InfoRow('Email', u.email),
          const Divider(height: 1, color: _cBorder),
          const SizedBox(height: 20),
          // ผู้สมัครใหม่ (pending) หรือถูกปฏิเสธไปแล้ว: อนุมัติได้
          if (!u.isAdmin &&
              (u.status == _UStatus.pending ||
                  u.status == _UStatus.rejected)) ...[
            _ActionButton(
              label: 'Approve user',
              onPressed: () =>
                  _setStatus(ctx, u, _UStatus.active, 'approved'),
            ),
            const SizedBox(height: 10),
          ],
          if (!u.isAdmin && u.status == _UStatus.pending)
            _ActionButton(
              filled: false,
              danger: true,
              label: 'Reject user',
              onPressed: () =>
                  _setStatus(ctx, u, _UStatus.rejected, 'rejected'),
            ),
          if (!u.isAdmin && u.status == _UStatus.active)
            _ActionButton(
              filled: false,
              danger: true,
              label: 'Suspend user',
              onPressed: () =>
                  _setStatus(ctx, u, _UStatus.suspended, 'suspended'),
            ),
          if (!u.isAdmin && u.status == _UStatus.suspended)
            _ActionButton(
              filled: false,
              label: 'Restore user',
              onPressed: () => _setStatus(ctx, u, _UStatus.active, 'restored'),
            ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _visible;
    return Scaffold(
      backgroundColor: _cBg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'Users',
              subtitle: '${_users.length} registered students', // TODO: นับจาก API
            ),
            _SearchRow(
              hint: 'Search users',
              filterActive: _filter != 'All',
              onChanged: (v) => setState(() => _query = v),
              onFilter: _openFilter,
            ),
            _SectionRow(label: 'All records', shown: list.length),
            Expanded(
              child: list.isEmpty
                  ? const _Empty('No users found')
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        for (final u in list)
                          _ListRow(
                            icon: Icons.group_outlined,
                            iconBg: _cSage,
                            iconFg: _cSageDark,
                            title: u.name,
                            subtitle: '@${u.handle} · ${u.studentId}',
                            badge: _label(u),
                            badgeBg: _colors(u).$1,
                            badgeFg: _colors(u).$2,
                            onTap: () => _openUser(u),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- small shared widgets (local to this file) ----
void _snack(BuildContext context, String msg) {
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

Future<T?> _showSheet<T>(
  BuildContext context,
  Widget Function(BuildContext) builder,
) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _cBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(ctx).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(child: builder(ctx)),
    ),
  );
}

Future<String?> _pickFilter(
  BuildContext context,
  String current,
  List<String> options,
) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: _cBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final o in options)
                  ChoiceChip(
                    label: Text(o),
                    selected: o == current,
                    showCheckmark: false,
                    selectedColor: _cInk,
                    backgroundColor: _cCard,
                    side: const BorderSide(color: _cBorder),
                    labelStyle: TextStyle(
                      color: o == current ? Colors.white : _cInk,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => Navigator.pop(ctx, o),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _cInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: _cMuted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () => _snack(context, 'More options (coming soon)'),
          ),
        ],
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  final String hint;
  final bool filterActive;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;
  const _SearchRow({
    required this.hint,
    required this.filterActive,
    required this.onChanged,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder b(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFFB0AFA8),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search, size: 20, color: _cInk),
                filled: true,
                fillColor: _cCard,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                border: b(_cBorder),
                enabledBorder: b(_cBorder),
                focusedBorder: b(_cInk),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: _cCard,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onFilter,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: filterActive ? _cInk : _cBorder),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.tune, size: 20),
                    if (filterActive)
                      const Positioned(
                        top: 12,
                        right: 12,
                        child: CircleAvatar(
                          radius: 4,
                          backgroundColor: _cRedFg,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  final String label;
  final int shown;
  const _SectionRow({required this.label, required this.shown});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(
            '$shown shown',
            style: const TextStyle(fontSize: 11, color: _cMuted),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Badge({required this.label, required this.bg, required this.fg});

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

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;
  const _IconBox({
    required this.icon,
    required this.bg,
    required this.fg,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, size: size * 0.42, color: fg),
  );
}

class _ListRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeBg;
  final Color badgeFg;
  final VoidCallback onTap;
  const _ListRow({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeBg,
    required this.badgeFg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _cBorder)),
        ),
        child: Row(
          children: [
            _IconBox(icon: icon, bg: iconBg, fg: iconFg),
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: _cMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _Badge(label: badge, bg: badgeBg, fg: badgeFg),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final bool danger;
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? _cRedFg : _cInk;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final text = Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    );
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: filled
          ? FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: color,
                shape: shape,
              ),
              onPressed: onPressed,
              child: text,
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: danger ? _cRedFg : _cBorder),
                shape: shape,
              ),
              onPressed: onPressed,
              child: text,
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: _cMuted)),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);

  @override
  Widget build(BuildContext context) => Center(
    child: Text(text, style: const TextStyle(color: _cMuted)),
  );
}
