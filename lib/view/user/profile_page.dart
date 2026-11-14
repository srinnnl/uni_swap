import 'package:flutter/material.dart';
import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/model/dashboard.dart';
import 'package:uni_swap/model/enums.dart';
import 'package:uni_swap/model/format.dart';
import 'package:uni_swap/model/json_utils.dart';
import 'package:uni_swap/model/location.dart';
import 'package:uni_swap/model/order.dart';
import 'package:uni_swap/model/order_status.dart';
import 'package:uni_swap/model/product.dart';
import 'package:uni_swap/view/user/location_picker.dart';
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

class ProfilePage extends StatefulWidget {
  /// Show the "Admin dashboard" menu item (role = admin).
  final bool isAdmin;

  /// true เมื่อกำลังอยู่แท็บ Profile (MainScreen ใช้ IndexedStack จึงต้องสั่งโหลดใหม่เอง)
  final bool isActive;

  /// ให้แถบ "Needs your attention" สลับไปแท็บอื่นของ MainScreen (2 = My items, 3 = Orders)
  final ValueChanged<int>? onOpenTab;

  const ProfilePage({
    super.key,
    this.isAdmin = false,
    this.isActive = false,
    this.onOpenTab,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Location? _selectedLocation;
  List<Location> _locations = [];

  bool _isLoading = true;
  bool _savingLocation = false;
  String? _loadError;

  // ข้อมูลจาก GET /api/dashboard — null = ยังไม่รู้/โหลดไม่ได้ -> สถิติแสดง "–" และซ่อนแถบ
  DashboardCounts? _counts;
  List<Order> _orders = [];
  PendingLocationRequest? _pendingRequest;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // กลับมาที่แท็บ Profile -> รีเฟรชสถิติและแถบ (ข้อมูลอาจเปลี่ยนจากแท็บอื่น)
    if (widget.isActive && !oldWidget.isActive) _loadStats();
  }

  // ---- Profile data from AuthController ----

  String get _username {
    final user = authController.user;

    final username = user?['username']?.toString().trim() ?? '';
    if (username.isNotEmpty) return username;

    final displayName = user?['display_name']?.toString().trim() ?? '';
    if (displayName.isNotEmpty) return displayName;

    final email = user?['email']?.toString().trim() ?? '';
    if (email.isNotEmpty) return email.split('@').first;

    return 'User';
  }

  String get _memberSince {
    final createdAt = authController.user?['created_at'];

    if (createdAt == null) return 'Member since —';

    final date = DateTime.tryParse(createdAt.toString());
    if (date == null) return 'Member since —';

    const months = [
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

    return 'Member since ${months[date.month - 1]} ${date.year}';
  }

  String get _residenceLabel {
    final location = _selectedLocation;
    if (location != null) {
      return '${locationZoneLabel(location.zone)} · ${location.name}';
    }
    return authController.user?['residence_name']?.toString() ??
        'Choose a listed residence';
  }

  Future<void> _loadProfile() async {
    if (!authController.isAuthenticated) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    _loadStats(); // แยกจากโปรไฟล์ ถ้าพังก็แค่โชว์ "–"

    try {
      await authController.loadProfile();
      final locationRows = await productController.locations();
      final locations = locationRows.map(Location.fromJson).toList();
      final locationId = int.tryParse(
        authController.user?['residence_location_id']?.toString() ?? '',
      );
      final matches = locations.where((location) => location.id == locationId);

      if (!mounted) return;

      setState(() {
        _locations = locations;
        _selectedLocation = matches.isEmpty ? null : matches.first;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = 'Unable to load profile. Please try again.';
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final response = await productController.myDashboard();
      final data = jsonObject(response['data']);
      if (response['success'] != true || data['counts'] is! Map) {
        throw const ApiException('The server returned invalid statistics.');
      }
      final counts = DashboardCounts.fromJson(jsonObject(data['counts']));
      final orders = jsonParseList(data['recent_orders'], Order.fromJson);
      final pending = data['pending_location_request'];
      if (mounted) {
        setState(() {
          _counts = counts;
          _orders = orders;
          _pendingRequest = pending is Map
              ? PendingLocationRequest.fromJson(
                  Map<String, dynamic>.from(pending),
                )
              : null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _counts = null;
          _orders = [];
          _pendingRequest = null;
        });
      }
    }
  }

  /// แถบ "Needs your attention": (icon, title, subtitle, onTap) เฉพาะเรื่องที่มีจริง
  List<(IconData, String, String, VoidCallback?)> _attentionItems() {
    final counts = _counts;
    if (counts == null) return const [];
    void openTab(int index) => widget.onOpenTab?.call(index);
    final items = <(IconData, String, String, VoidCallback?)>[];

    if (counts.listingsToFix > 0) {
      final n = counts.listingsToFix;
      items.add((
        Icons.error_outline,
        n == 1 ? '1 item needs changes' : '$n items need changes',
        'Fix it and send it for review again',
        () => openTab(2),
      ));
    }

    for (final order in _orders.where((o) => o.isActive)) {
      final buying = order.isBuying;
      final title =
          '${buying ? 'Buying' : 'Selling'} · ${order.productTitle ?? 'Item'}';
      final String subtitle;
      if (order.shownStatus == OrderStatus.pendingPayment) {
        final due = order.paymentDeadline;
        subtitle = buying
            ? (due != null
                  ? 'Pay before ${formatClock(due)}'
                  : 'Waiting for your payment')
            : 'Waiting for the buyer to pay';
      } else {
        final place = order.meetupLocation.trim().isEmpty
            ? 'the pickup place'
            : order.meetupLocation.trim();
        final at = order.meetupDatetime;
        subtitle =
            'Meet at $place · ${at == null ? 'time not set yet' : formatWhen(at)}';
      }
      items.add((
        buying ? Icons.shopping_bag_outlined : Icons.sell_outlined,
        title,
        subtitle,
        () => openTab(3),
      ));
    }

    if (counts.listingsToReview > 0) {
      final n = counts.listingsToReview;
      items.add((
        Icons.hourglass_empty,
        n == 1
            ? '1 item is waiting for review'
            : '$n items are waiting for review',
        'An admin will check it soon',
        () => openTab(2),
      ));
    }

    final request = _pendingRequest;
    if (request != null) {
      items.add((
        Icons.location_on_outlined,
        'Residence request: ${request.name}',
        request.status == LocationRequestStatus.reviewing
            ? 'An admin is reviewing it'
            : 'Waiting for an admin to review',
        null,
      ));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cBg,
      body: SafeArea(bottom: false, child: _buildList()),
    );
  }

  Widget _buildList() {
    return ListView(
      // Leave space at the bottom for the navigation bar.
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        Row(
          children: [
            const SizedBox(width: 48),
            const Expanded(
              child: Center(child: _PageHeader(title: 'Profile')),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 20),

        // Profile avatar
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

        // Username from AuthController
        Center(
          child: Text(
            '@$_username',
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Account creation date from API
        Center(
          child: Text(
            _memberSince,
            style: const TextStyle(fontSize: 12, color: _cMuted),
          ),
        ),

        // Loading / retry message
        if (_isLoading) ...[
          const SizedBox(height: 8),
          const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _cSageDark,
              ),
            ),
          ),
        ],

        if (_loadError != null) ...[
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: _loadProfile,
              child: const Text(
                'Unable to load profile. Tap to retry.',
                style: TextStyle(fontSize: 11, color: _cRedFg),
              ),
            ),
          ),
        ],

        const SizedBox(height: 22),

        // Statistics (Items = ทุกสินค้าที่ลง, Sold = ขายแล้ว)
        _AppCard(
          child: IntrinsicHeight(
            child: Row(
              children: [
                _stat(_counts?.myListings.toString() ?? '–', 'Items'),
                const VerticalDivider(color: _cBorder, width: 1),
                _stat(_counts?.soldListings.toString() ?? '–', 'Sold'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Needs your attention (ซ่อนทั้งแถบถ้าไม่มีอะไรรอ)
        ...(() {
          final attention = _attentionItems();
          if (attention.isEmpty) return <Widget>[];
          return <Widget>[
            const Text(
              'Needs your attention',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _cInk,
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < attention.length; i++)
              _menuTile(
                attention[i].$1,
                attention[i].$2,
                attention[i].$3,
                attention[i].$4,
                last: i == attention.length - 1,
              ),
            const SizedBox(height: 24),
          ];
        })(),

        const Text(
          'My account',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _cInk,
          ),
        ),
        const SizedBox(height: 8),

        // Residence (เปลี่ยนได้ / ขอเพิ่มที่พักใหม่)
        _menuTile(
          Icons.location_on_outlined,
          'My location',
          _residenceLabel,
          _pickLocation,
        ),

        const SizedBox(height: 22),

        // Log out
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
    VoidCallback? onTap, {
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
            if (onTap != null) const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLocation() async {
    if (_savingLocation || _locations.isEmpty) return;
    final result = await showLocationPicker(
      context,
      locations: _locations,
      zone:
          _selectedLocation?.zone ??
          ResidenceZone.tryParse(authController.user?['residence_zone']),
      selectedLocationId: _selectedLocation?.id,
      otherLabel: 'Request a location',
    );

    if (!mounted || result == null) return;

    // Request a location
    if (result.location == null) {
      final hasResidence =
          _selectedLocation != null ||
          (authController.user?['residence_name']?.toString().isNotEmpty ??
              false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RequestLocationPage(
            currentLocation: hasResidence ? _residenceLabel : null,
          ),
        ),
      );
      return;
    }

    setState(() => _savingLocation = true);
    try {
      // ย้ายที่พัก: เตือนถ้ายังมีสินค้าที่นัดรับอยู่ที่หอเดิม
      if (_selectedLocation?.id != result.location!.id) {
        final stale = await _listingsAtOtherPlace(result.location!.id);
        if (!mounted) return;
        if (stale > 0 && !await _confirmMove(stale)) return;
        if (!mounted) return;
      }
      await authController.updateProfile({
        'residence_zone': result.zone.apiValue,
        'residence_location_id': result.location!.id,
      });
      if (!mounted) return;
      setState(() => _selectedLocation = result.location);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Residence updated')));
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _savingLocation = false);
    }
  }

  /// จำนวนสินค้าที่ยังขายอยู่/รอตรวจ แต่นัดรับที่หออื่นที่ไม่ใช่ [newLocationId]
  /// (reserved ไม่นับ เพราะมีออเดอร์ค้างอยู่) ถ้าโหลดไม่ได้ให้คืน 0 แล้วไปต่อ
  Future<int> _listingsAtOtherPlace(int newLocationId) async {
    try {
      final response = await productController.myListings(limit: 100);
      final rows = jsonParseList(response['data'], Product.fromJson);
      const active = {
        ProductStatus.available,
        ProductStatus.pendingReview,
        ProductStatus.changesRequested,
      };
      return rows
          .where(
            (p) =>
                active.contains(p.status) &&
                p.locationId != null &&
                p.locationId != newLocationId,
          )
          .length;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> _confirmMove(int count) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cBg,
        title: const Text('Change residence?'),
        content: Text(
          count == 1
              ? 'You have 1 item still listed for pickup at your current '
                    'place. It will stay there until you edit it, and an '
                    'edited item goes back to admin review.'
              : 'You have $count items still listed for pickup at your '
                    'current place. They will stay there until you edit '
                    'them, and edited items go back to admin review.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Change anyway'),
          ),
        ],
      ),
    );
    return ok == true;
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

              // Clear the current session.
              authController.signOut();

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
