import 'package:flutter/material.dart';

class _C {
  static const bg = Color(0xFFFAF9F6);
  static const ink = Color(0xFF2F2F2B);
  static const muted = Color(0xFF7A7973);
  static const faint = Color(0xFFA9A8A2);
  static const border = Color(0xFFE6E4DD);
  static const surface = Color(0xFFF3F2EE);
}

/// ข้อมูลผู้ขาย
class SellerInfo {
  const SellerInfo({
    required this.name,
    required this.rating,
    required this.sales,
    required this.location,
  });

  final String name;
  final double rating;
  final int sales;
  final String location;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

/// ข้อมูลสินค้าสำหรับหน้ารายละเอียด: ให้เพื่อน backend ใช้เป็นแบบ JSON ได้เลย
class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.title,
    required this.price,
    required this.place,
    this.oldPrice,
    this.category,
    this.condition,
    this.description,
    this.urgent = false,
    this.daysLeft,
    this.imageUrls = const [],
    this.seller,
  });

  final String id;
  final String title;
  final int price;
  final int? oldPrice;
  final String place;
  final String? category;
  final String? condition;
  final String? description;
  final bool urgent;
  final int? daysLeft;
  final List<String> imageUrls;
  final SellerInfo? seller;

  /// ข้อมูลจำลองสำหรับเดโม
  /// TODO: ลบทิ้งเมื่อมี API แล้ว และดึงข้อมูลจริงด้วย id แทน
  factory ProductDetail.mock({
    required String id,
    required String title,
    required int price,
    required String place,
    int? oldPrice,
    String? category,
    bool urgent = false,
  }) {
    return ProductDetail(
      id: id,
      title: title,
      price: price,
      oldPrice: oldPrice,
      place: place,
      category: category,
      condition: 'Good condition',
      description:
          'Solid ${title.toLowerCase()} in great condition. A few small marks, '
          'but sturdy and ready for a new home. Must go soon.',
      urgent: urgent,
      daysLeft: urgent ? 3 : null,
      seller: SellerInfo(
        name: 'Jamie Lee',
        rating: 4.9,
        sales: 18,
        location: place.split(' · ').last,
      ),
    );
  }
}

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.product});

  final ProductDetail product;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final _pageCtrl = PageController();
  final _noteCtrl = TextEditingController();
  int _imageIndex = 0;
  bool _isFavorite = false; // TODO: เชื่อมกับรายการโปรดจริง
  bool _requested = false;

  ProductDetail get _p => widget.product;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ===== จุดเชื่อมต่อ API: ให้เพื่อนแก้ฟังก์ชันนี้ =====
  Future<void> _requestToBuy() async {
    final sellerName = _p.seller?.name ?? 'the seller';
    _noteCtrl.clear();

    final send = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Request to buy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send a request to $sellerName for \$${_p.price}?'),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Add a note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: _C.ink),
            child: const Text('Send request'),
          ),
        ],
      ),
    );

    if (send != true || !mounted) return;

    // TODO: ส่งคำขอซื้อไปที่ API (productId: _p.id, note: _noteCtrl.text)
    setState(() => _requested = true);
    _toast('Request sent to $sellerName');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGallery(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: _buildContent(),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ===== รูปสินค้า =====
  Widget _buildGallery() {
    final topInset = MediaQuery.of(context).padding.top;
    final count = _p.imageUrls.length;

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1.1,
          child: count == 0
              ? _imagePlaceholder()
              : PageView.builder(
                  controller: _pageCtrl,
                  itemCount: count,
                  onPageChanged: (i) => setState(() => _imageIndex = i),
                  itemBuilder: (_, i) => Image.network(
                    _p.imageUrls[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    loadingBuilder: (_, child, progress) =>
                        progress == null ? child : _imagePlaceholder(),
                  ),
                ),
        ),
        Positioned(
          top: topInset + 12,
          left: 20,
          child: _circleButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.maybePop(context),
          ),
        ),
        Positioned(
          top: topInset + 12,
          right: 20,
          child: _circleButton(
            icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
            iconColor: _isFavorite ? Colors.red.shade400 : _C.ink,
            onTap: () => setState(() => _isFavorite = !_isFavorite),
          ),
        ),
        if (count > 1)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < count; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _imageIndex ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: i == _imageIndex ? 1 : 0.6,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _imagePlaceholder() => Container(
    color: _C.surface,
    alignment: Alignment.center,
    child: const Icon(Icons.image_outlined, size: 48, color: _C.faint),
  );

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = _C.ink,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 22, color: iconColor),
        ),
      ),
    );
  }

  // ===== เนื้อหา =====
  Widget _buildContent() {
    final seller = _p.seller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_p.urgent) _urgentBadge() else const SizedBox(height: 28),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: _C.ink),
              padding: EdgeInsets.zero,
              color: Colors.white,
              onSelected: (v) {
                // TODO: เชื่อมฟังก์ชันแชร์/รายงานจริง
                _toast(v == 'share' ? 'Share coming soon' : 'Report sent');
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'share', child: Text('Share')),
                PopupMenuItem(value: 'report', child: Text('Report listing')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _p.title,
          style: const TextStyle(
            fontSize: 32,
            height: 1.15,
            color: _C.ink,
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '\$${_p.price}',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: _C.ink,
              ),
            ),
            if (_p.oldPrice != null) ...[
              const SizedBox(width: 10),
              Text(
                '\$${_p.oldPrice}',
                style: const TextStyle(
                  fontSize: 14,
                  color: _C.faint,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        _buildMeta(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Divider(height: 1, color: _C.border),
        ),
        if (_p.description != null) ...[
          const Text(
            'About this item',
            style: TextStyle(fontSize: 17, color: _C.ink),
          ),
          const SizedBox(height: 8),
          Text(
            _p.description!,
            style: const TextStyle(fontSize: 14, height: 1.55, color: _C.muted),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: _C.border),
          ),
        ],
        if (seller != null) _buildSeller(seller),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: เปิดห้องแชทกับผู้ขาย
                    _toast('Chat coming soon');
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Chat with seller'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _C.ink,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: _C.border),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                // TODO: ส่งรายงานประกาศนี้
                _toast('Report sent');
              },
              icon: const Icon(Icons.outlined_flag, size: 18),
              label: const Text('Report'),
              style: TextButton.styleFrom(
                foregroundColor: _C.muted,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _urgentBadge() {
    final days = _p.daysLeft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        days == null ? 'Urgent' : 'Urgent · $days days left',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFFC62828),
        ),
      ),
    );
  }

  IconData _categoryIcon(String? category) => switch (category) {
    'Furniture' => Icons.chair_alt_outlined,
    'Books' => Icons.menu_book_outlined,
    'Tech' => Icons.computer_outlined,
    'Music' => Icons.music_note_outlined,
    'Transport' => Icons.pedal_bike_outlined,
    _ => Icons.sell_outlined,
  };

  Widget _buildMeta() {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        if (_p.category != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_categoryIcon(_p.category), size: 16, color: _C.muted),
              const SizedBox(width: 6),
              Text(
                _p.category!,
                style: const TextStyle(fontSize: 13, color: _C.muted),
              ),
            ],
          ),
        if (_p.condition != null)
          Text(
            _p.condition!,
            style: const TextStyle(fontSize: 13, color: _C.muted),
          ),
      ],
    );
  }

  Widget _buildSeller(SellerInfo s) {
    return InkWell(
      onTap: () {
        // TODO: เปิดหน้าโปรไฟล์ผู้ขาย
        _toast('Seller profile coming soon');
      },
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFFE9E1D9),
            child: Text(
              s.initials,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF5B534B),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _C.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_border, size: 16, color: _C.muted),
                    const SizedBox(width: 4),
                    Text(
                      '${s.rating} · ${s.sales} sales',
                      style: const TextStyle(fontSize: 12, color: _C.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: _C.muted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        s.location,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: _C.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: _C.ink),
        ],
      ),
    );
  }

  // ===== แถบด้านล่าง (ราคา + ปุ่มขอซื้อ) =====
  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: _C.bg,
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Price',
                    style: TextStyle(fontSize: 12, color: _C.muted),
                  ),
                  Text(
                    '\$${_p.price}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _C.ink,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _requested ? null : _requestToBuy,
                  style: FilledButton.styleFrom(
                    backgroundColor: _C.ink,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _C.border,
                    disabledForegroundColor: _C.muted,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _requested ? 'Request sent' : 'Request to buy',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
