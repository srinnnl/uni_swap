import 'package:flutter/material.dart';
import 'package:uni_swap/model/format.dart';

class _C {
  static const bg = Color(0xFFFAF9F6);
  static const ink = Color(0xFF2F2F2B);
  static const muted = Color(0xFF7A7973);
  static const faint = Color(0xFFA9A8A2);
  static const border = Color(0xFFE6E4DD);
  static const surface = Color(0xFFF3F2EE);
  static const star = Color(0xFFD9A21B);
}

class _Item {
  const _Item(this.title, this.price, {this.imageUrl});
  final String title;
  final double price;
  final String? imageUrl;
}

// reviews JOIN users (ผู้รีวิว) JOIN orders/products (สินค้าที่ซื้อ)
class _Review {
  const _Review({
    required this.reviewer,
    required this.rating,
    required this.product,
    required this.date,
    this.comment,
  });
  final String reviewer; // users.display_name
  final int rating; // reviews.rating (1-5)
  final String product;
  final String date; // reviews.created_at
  final String? comment; // reviews.comment (ไม่บังคับ)
}

class SellerProfilePage extends StatefulWidget {
  const SellerProfilePage({
    super.key,
    required this.name,
    required this.location,
    required this.rating,
    required this.sales,
    this.memberSince = 2024,
  });

  final String name;
  final String location;
  final double rating;
  final int sales;
  final int memberSince;

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  static const _items = [
    _Item('Oak study desk', 45),
    _Item('Desk lamp', 12),
    _Item('Bookshelf', 30),
    _Item('Mini fridge', 60),
  ];

  static const _reviews = [
    _Review(
      reviewer: 'Noah P.',
      rating: 5,
      product: 'Acoustic guitar',
      date: 'May 18',
      comment: 'Great condition, easy to meet up!',
    ),
    _Review(
      reviewer: 'Alex S.',
      rating: 5,
      product: 'City bike',
      date: 'May 10',
      comment: 'Smooth handover, would buy again.',
    ),
    _Review(
      reviewer: 'Priya N.',
      rating: 4,
      product: 'Calculus textbook',
      date: 'Apr 28',
    ),
  ];

  int _tab = 0;

  String get _initials {
    final parts = widget.name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  String get _building => widget.location.split(' · ').last;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildIdentity(),
            const SizedBox(height: 22),
            _buildStats(),
            const SizedBox(height: 24),
            _buildTabs(),
            const SizedBox(height: 18),
            if (_tab == 0) _buildItems() else _buildReviews(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
          widget.name,
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
              '$_building · Member since ${widget.memberSince}',
              style: const TextStyle(fontSize: 12, color: _C.muted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats() {
    Widget stat(String value, String label) => Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _C.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: _C.muted)),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            stat('${widget.sales}', 'Sold'),
            const VerticalDivider(color: _C.border, width: 1),
            stat(widget.rating.toStringAsFixed(1), 'Rating'),
            const VerticalDivider(color: _C.border, width: 1),
            stat('${_reviews.length}', 'Reviews'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    Widget tab(int i, String label, int count) {
      final selected = _tab == i;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _tab = i),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? _C.ink : _C.border,
                  width: selected ? 2 : 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? _C.ink : _C.muted,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab(0, 'Items', _items.length),
        tab(1, 'Reviews', _reviews.length),
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

  Widget _buildReviews() {
    if (_reviews.isEmpty) return const _Empty('No reviews yet');

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.border),
          ),
          child: Row(
            children: [
              Text(
                widget.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 34,
                  color: _C.ink,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Stars(widget.rating.round(), size: 18),
                    const SizedBox(height: 4),
                    Text(
                      'From ${widget.sales} completed sales',
                      style: const TextStyle(fontSize: 12, color: _C.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final r in _reviews) _buildReview(r),
      ],
    );
  }

  Widget _buildReview(_Review r) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _C.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.reviewer,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.ink,
                  ),
                ),
              ),
              Text(
                r.date,
                style: const TextStyle(fontSize: 11, color: _C.faint),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _Stars(r.rating),
          const SizedBox(height: 8),
          if (r.comment != null && r.comment!.isNotEmpty) ...[
            Text(
              r.comment!,
              style: const TextStyle(fontSize: 13, height: 1.4, color: _C.ink),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            'Bought: ${r.product}',
            style: const TextStyle(fontSize: 11, color: _C.muted),
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars(this.count, {this.size = 15});
  final int count;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 1; i <= 5; i++)
        Icon(
          i <= count ? Icons.star : Icons.star_border,
          size: size,
          color: _C.star,
        ),
    ],
  );
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
