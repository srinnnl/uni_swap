import 'package:flutter/material.dart';
import 'package:uni_swap/model/format.dart';

class _C {
  static const bg = Color(0xFFFAF9F6);
  static const ink = Color(0xFF2F2F2B);
  static const muted = Color(0xFF7A7973);
  static const faint = Color(0xFFA9A8A2);
  static const surface = Color(0xFFF3F2EE);
}

class _Item {
  const _Item(this.title, this.price, {this.imageUrl});
  final String title;
  final double price;
  final String? imageUrl;
}

class SellerProfilePage extends StatelessWidget {
  const SellerProfilePage({
    super.key,
    required this.name,
    required this.location,
    required this.sales,
    this.memberSince = 2024,
  });

  final String name;
  final String location;
  final int sales;
  final int memberSince;

  static const _items = [
    _Item('Oak study desk', 45),
    _Item('Desk lamp', 12),
    _Item('Bookshelf', 30),
    _Item('Mini fridge', 60),
  ];

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  String get _building => location.split(' · ').last;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            _buildIdentity(),
            const SizedBox(height: 24),
            const Text(
              'Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _C.ink,
              ),
            ),
            const SizedBox(height: 18),
            _buildItems(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'Seller',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _C.ink,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentity() {
    return Column(
      children: [
        CircleAvatar(
          radius: 38,
          backgroundColor: const Color(0xFFE9E1D9),
          child: Text(
            _initials,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 26,
              color: Color(0xFF5B534B),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          name,
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 24,
            color: _C.ink,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on_outlined, size: 14, color: _C.muted),
            const SizedBox(width: 4),
            Text(
              '$_building · Member since $memberSince',
              style: const TextStyle(fontSize: 12, color: _C.muted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '$sales completed sales',
          style: const TextStyle(fontSize: 12, color: _C.muted),
        ),
      ],
    );
  }

  Widget _buildItems() {
    if (_items.isEmpty) return const _Empty('No active items');

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 18,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (_, i) {
        final l = _items[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox.expand(
                  child: l.imageUrl == null
                      ? Container(
                          color: _C.surface,
                          child: const Icon(
                            Icons.image_outlined,
                            size: 30,
                            color: _C.faint,
                          ),
                        )
                      : Image.network(
                          l.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: _C.surface,
                            child: const Icon(
                              Icons.image_outlined,
                              size: 30,
                              color: _C.faint,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _C.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatPriceTHB(l.price),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _C.ink,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Center(
      child: Text(text, style: const TextStyle(color: _C.muted)),
    ),
  );
}
