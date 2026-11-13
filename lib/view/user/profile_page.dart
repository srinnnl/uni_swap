import 'package:flutter/material.dart';
import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/model/enums.dart';
import 'package:uni_swap/model/location.dart';
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

  const ProfilePage({super.key, this.isAdmin = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Location? _selectedLocation;
  List<Location> _locations = [];

  bool _isLoading = true;
  bool _savingLocation = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
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

        // Mock statistics - unchanged for now
        _AppCard(
          child: IntrinsicHeight(
            child: Row(
              children: [
                _stat('12', 'Items'),
                const VerticalDivider(color: _cBorder, width: 1),
                _stat('8', 'Sold'),
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

        // Mock location - unchanged for now
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RequestLocationPage()),
      );
      return;
    }

    setState(() => _savingLocation = true);
    try {
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
