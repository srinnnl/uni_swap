import 'package:flutter/material.dart';
import 'admin_categories_page.dart';
import 'admin_items_page.dart';
import 'admin_locations_page.dart';
import 'admin_transactions_page.dart';
import 'admin_users_page.dart';
import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/model/dashboard.dart';
import 'package:uni_swap/model/format.dart';
import 'package:uni_swap/model/json_utils.dart';
import 'package:uni_swap/model/location.dart';
import 'package:uni_swap/model/product.dart';
import 'package:uni_swap/view/login.dart';
import 'package:uni_swap/view/user/location_picker.dart';

// ---- colors ----
const _cBg = Color(0xFFFAF9F6);
const _cCard = Color(0xFFFFFFFF);
const _cInk = Color(0xFF2B2B26);
const _cMuted = Color(0xFF8A8A82);
const _cBorder = Color(0xFFE6E4DE);
const _cChip = Color(0xFFF0EEE9);
const _cBlueBg = Color(0xFFE3ECF7);
const _cBlueFg = Color(0xFF3B5E8C);
const _cAmberBg = Color(0xFFFBEBC2);
const _cAmberFg = Color(0xFF8A6410);
const _cRedFg = Color(0xFFB3402F);

class AdminPage extends StatefulWidget {
  final String displayName;

  const AdminPage({super.key, this.displayName = 'Admin'});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  AdminDashboard? _data;
  // จำนวนที่พักที่เปิดใช้งาน (overview ไม่มีค่านี้ จึงนับจาก GET /admin/locations)
  // null = ยังไม่รู้/โหลดไม่ได้ -> แสดง "–"
  int? _locationsActive;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  Future<AdminDashboard> _fetchDashboard() async {
    final response = await adminController.dashboard();
    if (response['success'] == false) {
      throw ApiException(
        response['message']?.toString() ?? 'Could not load the dashboard.',
      );
    }
    // รองรับทั้ง { success, data: {overview,...} } และ { success, overview,... }
    final payload = response['data'] is Map
        ? jsonObject(response['data'])
        : response;
    if (payload['overview'] is! Map) {
      throw const ApiException('The server returned an invalid dashboard.');
    }
    return AdminDashboard.fromJson(payload);
  }

  Future<int?> _fetchActiveLocationCount() async {
    try {
      final response = await adminController.locations();
      if (response['data'] is! List) return null;
      return jsonParseList(
        response['data'],
        Location.fromJson,
      ).where((location) => location.isActive).length;
    } catch (_) {
      return null; // ตัวเลขรองเท่านั้น ไม่ให้ทั้งหน้า error
    }
  }

  /// [silent] = ไม่โชว์ spinner เต็มหน้า (pull-to-refresh / กลับจากหน้าย่อย)
  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait<Object?>([
        _fetchDashboard(),
        _fetchActiveLocationCount(),
      ]);
      if (mounted) {
        setState(() {
          _data = results[0] as AdminDashboard;
          _locationsActive = results[1] as int?;
          _error = null;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load the dashboard.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final overview = data?.overview;
    return Scaffold(
      backgroundColor: _cBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _load(silent: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              // 1. Header แบบคลีนๆ กึ่งกลาง พร้อมเส้นคั่นด้านล่าง
              const _PageHeader(
                title: 'Admin',
                subtitle: 'Marketplace overview',
              ),

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
                '$_greeting, ${widget.displayName}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _cInk,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 20),

              if (data == null && _loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (data == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Text(
                        _error ?? 'Could not load the dashboard.',
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                )
              else ...[
                // ถ้า refresh ไม่สำเร็จแต่ยังมีข้อมูลเดิม ให้โชว์ error เล็ก ๆ
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: _cRedFg, fontSize: 12),
                    ),
                  ),

                // 3. Pending approval
                _PendingApprovalCard(
                  count: overview!.itemsPending,
                  onTap: () => _open(const AdminItemsPage()),
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
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 108,
                      ),
                  children: [
                    _StatCard(
                      icon: Icons.group_outlined,
                      label: 'Users',
                      value: _formatCount(overview.usersTotal),
                      note: '${overview.usersPending} pending',
                      highlightNote: overview.usersPending > 0,
                      onTap: () => _open(const AdminUsersPage()),
                    ),
                    _StatCard(
                      icon: Icons.location_on_outlined,
                      label: 'Locations',
                      value: _locationsActive == null
                          ? '–'
                          : _formatCount(_locationsActive!),
                      note: '${overview.locationsPending} pending',
                      highlightNote: overview.locationsPending > 0,
                      onTap: () => _open(const AdminLocationsPage()),
                    ),
                    _StatCard(
                      icon: Icons.inventory_2_outlined,
                      label: 'Items',
                      value: _formatCount(overview.itemsLive),
                      note: 'Live',
                      onTap: () => _open(const AdminItemsPage()),
                    ),
                    _StatCard(
                      icon: Icons.sell_outlined,
                      label: 'Categories',
                      value: _formatCount(overview.categoriesActive),
                      note: 'Manage',
                      onTap: () => _open(const AdminCategoriesPage()),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                _AppCard(
                  onTap: () => _open(const AdminTransactionsPage()),
                  child: const Row(
                    children: [
                      _IconBox(icon: Icons.receipt_long_outlined, size: 38),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Completed sales & seller payouts',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _cInk,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Review sales history and record manual payouts',
                              style: TextStyle(fontSize: 11, color: _cMuted),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: _cMuted),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 5. Recent activity (คิวที่รอ admin: รายการสินค้า + คำขอที่พัก)
                const Text(
                  'Recent activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _cInk,
                  ),
                ),
                const SizedBox(height: 12),

                _buildActivity(data),
              ],

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
      ),
    );
  }

  /// รายการจริงจาก pendingListings / pendingLocationRequests (อย่างละไม่เกิน 5)
  /// เรียงใหม่สุดก่อน; ไม่มีอะไรรอ = ข้อความ empty
  Widget _buildActivity(AdminDashboard data) {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final entries = <({DateTime? at, _ActivityRow row})>[
      for (final Product p in data.pendingListings.take(5))
        (
          at: p.createdAt,
          row: _ActivityRow(
            title: p.title.isEmpty ? 'Untitled listing' : p.title,
            subtitle: _join([
              'Listing awaiting review',
              p.sellerName,
              timeAgo(p.createdAt),
            ]),
            icon: Icons.inventory_2_outlined,
            bg: _cAmberBg,
            fg: _cAmberFg,
            onTap: () => _open(const AdminItemsPage()),
          ),
        ),
      for (final LocationRequest r in data.pendingLocationRequests.take(5))
        (
          at: r.createdAt,
          row: _ActivityRow(
            title: r.name.isEmpty ? 'Location request' : r.name,
            subtitle: _join([
              'Location request',
              locationZoneLabel(r.zone),
              r.requesterName ?? r.requesterUsername,
              timeAgo(r.createdAt),
            ]),
            icon: Icons.location_on_outlined,
            bg: _cBlueBg,
            fg: _cBlueFg,
            onTap: () => _open(const AdminLocationsPage()),
          ),
        ),
    ]..sort((a, b) => (b.at ?? epoch).compareTo(a.at ?? epoch));

    if (entries.isEmpty) {
      return const _AppCard(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: Text(
            'Nothing is waiting for review',
            style: TextStyle(fontSize: 13, color: _cMuted),
          ),
        ),
      );
    }
    return _AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            entries[i].row.copyWith(isLast: i == entries.length - 1),
        ],
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

  // Navigation: กลับมาจากหน้าย่อยแล้วโหลดตัวเลขใหม่
  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) await _load(silent: true);
  }
}

// ---- Pending approval card ----

class _PendingApprovalCard extends StatelessWidget {
  final int count;
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
                      count == 1
                          ? '1 item waiting for your review'
                          : '$count items waiting for your review',
                      style: const TextStyle(fontSize: 12, color: _cAmberFg),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count',
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
  final VoidCallback? onTap;

  const _ActivityRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bg,
    required this.fg,
    this.isLast = false,
    this.onTap,
  });

  _ActivityRow copyWith({bool? isLast}) => _ActivityRow(
    title: title,
    subtitle: subtitle,
    icon: icon,
    bg: bg,
    fg: fg,
    isLast: isLast ?? this.isLast,
    onTap: onTap,
  );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _cInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: _cMuted),
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

/// 2418 -> "2,418"
String _formatCount(int n) {
  final digits = n.abs().toString();
  final buffer = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// ต่อข้อความด้วย " · " โดยข้ามค่าที่ว่าง/null
String _join(List<String?> parts) => [
  for (final part in parts)
    if (part != null && part.trim().isNotEmpty) part.trim(),
].join(' · ');
