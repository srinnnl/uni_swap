import 'package:flutter/material.dart';
import 'package:uni_swap/view/user/product_detail_page.dart';

class _C {
  static const bg = Color(0xFFFAF9F6);
  static const ink = Color(0xFF2F2F2B);
  static const muted = Color(0xFF7A7973);
  static const faint = Color(0xFFA9A8A2);
  static const border = Color(0xFFE6E4DD);
  static const surface = Color(0xFFF3F2EE);
}

// โมเดลสินค้า (ตัด oldPrice และ minutes ออกแล้ว)
class _Product {
  const _Product({
    required this.id,
    required this.title,
    required this.price,
    required this.place,
    this.imageUrl,
    this.urgent = false,
  });

  final String id;
  final String title;
  final int price;
  final String place;
  final String? imageUrl;
  final bool urgent;

  String get building => place.split(' · ').last;
}

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  // ข้อมูลจำลองสำหรับแสดง UI
  // TODO: เชื่อมกับ FavoriteStore หรือ API จริง
  final List<_Product> _favoriteItems = [
    const _Product(
      id: '1',
      title: 'Oak study desk',
      price: 45,
      place: 'North Campus · Maple Hall',
      urgent: true,
    ),
    const _Product(
      id: '2',
      title: 'Acoustic guitar',
      price: 80,
      place: 'North Campus · Maple Hall',
    ),
  ];

  void _unfavorite(String id) {
    setState(() {
      _favoriteItems.removeWhere((p) => p.id == id);
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Removed from favorites'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.bg,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              'Favorites',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _C.ink,
              ),
            ),
            Text(
              '${_favoriteItems.length} saved items',
              style: const TextStyle(fontSize: 12, color: _C.muted),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _C.ink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _favoriteItems.isEmpty ? _buildEmptyState() : _buildGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: _C.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 48,
                color: _C.faint,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _C.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Items you heart will be saved here so you can easily find them later.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _C.muted, height: 1.4),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: _C.ink,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Explore items',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio: 0.66,
      ),
      itemCount: _favoriteItems.length,
      itemBuilder: (context, i) => _buildProductCard(_favoriteItems[i]),
    );
  }

  Widget _buildProductCard(_Product p) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailPage(
            // ส่งแค่ข้อมูลที่จำเป็นไปให้ ProductDetail
            product: ProductDetail.mock(
              id: p.id,
              title: p.title,
              price: p.price,
              place: p.place,
              urgent: p.urgent,
            ),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(p.imageUrl),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _unfavorite(p.id),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.favorite,
                          size: 20,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                  ),
                  if (p.urgent)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE5E5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Urgent',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFC62828),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            p.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _C.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${p.price} THB',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _C.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            p.building,
            style: const TextStyle(fontSize: 12, color: _C.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String? url) {
    final placeholder = Container(
      color: _C.surface,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, size: 32, color: _C.faint),
    );
    if (url == null) return placeholder;
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}
