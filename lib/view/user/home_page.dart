import 'package:flutter/material.dart';
import 'package:uni_swap/view/user/product_detail_page.dart';

// ไฟล์นี้ใช้งานได้ด้วยตัวเอง (แถบเมนูด้านล่างให้ MainScreen จัดการ)

class _C {
  static const bg = Color(0xFFFAF9F6);
  static const ink = Color(0xFF2F2F2B);
  static const muted = Color(0xFF7A7973);
  static const faint = Color(0xFFA9A8A2);
  static const border = Color(0xFFE6E4DD);
  static const surface = Color(0xFFF3F2EE);
}

/// รูปแบบข้อมูลสินค้า: ให้เพื่อน backend ใช้เป็นแบบสำหรับ JSON ได้เลย
class _Product {
  const _Product({
    required this.id,
    required this.title,
    required this.price,
    required this.place,
    required this.minutes,
    this.oldPrice,
    this.imageUrl,
    this.urgent = false,
  });

  final String id;
  final String title;
  final int price;
  final int? oldPrice;
  final String place; // เช่น 'North Campus · Maple Hall'
  final int minutes; // เวลาเดินทางโดยประมาณ
  final String? imageUrl; // ถ้าเป็น null จะแสดงรูปแทนที่ชั่วคราว
  final bool urgent;

  String get zone => place.split(' · ').first;
  String get building => place.split(' · ').last;
}

// ===== ข้อมูลตัวอย่าง: TODO แทนด้วยข้อมูลจาก API =====
const _places = [
  'North Campus · Maple Hall',
  'North Campus · Oak Hall',
  'South Campus · Cedar Hall',
  'Off campus',
];

const _products = [
  _Product(
    id: '1',
    title: 'Oak study desk',
    price: 45,
    oldPrice: 70,
    place: 'North Campus · Maple Hall',
    minutes: 2,
    urgent: true,
  ),
  _Product(
    id: '2',
    title: 'Acoustic guitar',
    price: 80,
    place: 'North Campus · Maple Hall',
    minutes: 4,
  ),
  _Product(
    id: '3',
    title: 'Desk lamp',
    price: 12,
    place: 'North Campus · Oak Hall',
    minutes: 6,
  ),
  _Product(
    id: '4',
    title: 'City bike',
    price: 120,
    oldPrice: 150,
    place: 'South Campus · Cedar Hall',
    minutes: 12,
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _tabs = ['Same place', 'Same zone', 'All campus'];

  // TODO: ดึงจากข้อมูลผู้ใช้หลัง login
  final String _userName = 'Maya';
  final bool _residencePending = false; // true = ที่พักรอ admin ตรวจสอบ

  int _tab = 0;
  String _place = _places.first;
  final Set<String> _favorites = {};

  String get _zone => _place.split(' · ').first;
  String get _building => _place.split(' · ').last;

  List<_Product> get _visible => switch (_tab) {
    0 => _products.where((p) => p.place == _place).toList(),
    1 => _products.where((p) => p.zone == _zone).toList(),
    _ => _products,
  };

  String get _subtitle => switch (_tab) {
    0 => 'Items in $_building',
    1 => 'Items in $_zone',
    _ => 'Items across campus',
  };

  String get _greeting {
    final h = DateTime.now().hour;
    final part = h < 12 ? 'morning' : (h < 17 ? 'afternoon' : 'evening');
    return 'Good $part, $_userName';
  }

  Future<void> _pickPlace() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in _places)
              ListTile(
                title: Text(p),
                trailing: p == _place
                    ? const Icon(Icons.check, color: _C.ink)
                    : null,
                onTap: () => Navigator.pop(context, p),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _place = picked);
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 20),
                    _buildLocationBar(),
                    const SizedBox(height: 28),
                    Text(
                      _greeting,
                      style: const TextStyle(fontSize: 15, color: _C.muted),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Find something nearby.',
                      style: TextStyle(
                        fontSize: 34,
                        height: 1.15,
                        color: _C.ink,
                        fontFamily: 'serif',
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTabs(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (items.isEmpty)
              const SliverToBoxAdapter(child: _EmptyState())
            else
              SliverPadding(
                // เว้นล่างให้พ้นแถบเมนู/ปุ่ม Sell
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.66,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _buildProductCard(items[i]),
                    childCount: items.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _C.ink,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'U',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'serif',
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'UniSwap',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _C.ink,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none, color: _C.ink),
          onPressed: () {
            // TODO: เปิดหน้าแจ้งเตือน
          },
        ),
      ],
    );
  }

  Widget _buildLocationBar() {
    return InkWell(
      onTap: _pickPlace,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 20, color: _C.ink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _place,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _C.ink,
                ),
              ),
            ),
            if (_residencePending) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Pending review',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A6100),
                  ),
                ),
              ),
            ],
            const Icon(Icons.chevron_right, color: _C.muted),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _C.border)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++) ...[
            _buildTab(i),
            const SizedBox(width: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildTab(int index) {
    final active = index == _tab;
    return InkWell(
      onTap: () => setState(() => _tab = index),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _tabs[index],
              style: TextStyle(
                fontSize: 15,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? _C.ink : _C.muted,
              ),
            ),
            const SizedBox(height: 10),
            Container(height: 2, color: active ? _C.ink : Colors.transparent),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Near you',
              style: TextStyle(fontSize: 20, color: _C.ink),
            ),
            const SizedBox(height: 4),
            Text(
              _subtitle,
              style: const TextStyle(fontSize: 13, color: _C.muted),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            // TODO: เปิดหน้ารายการสินค้าทั้งหมด
          },
          child: const Text(
            'See all',
            style: TextStyle(
              fontSize: 13,
              color: _C.muted,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(_Product p) {
    final isFav = _favorites.contains(p.id);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailPage(
            // TODO: ส่งแค่ id แล้วให้หน้ารายละเอียดดึงข้อมูลจาก API เอง
            product: ProductDetail.mock(
              id: p.id,
              title: p.title,
              price: p.price,
              oldPrice: p.oldPrice,
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
                      onTap: () => setState(() {
                        isFav ? _favorites.remove(p.id) : _favorites.add(p.id);
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: isFav ? Colors.red.shade400 : _C.ink,
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
          Row(
            children: [
              Text(
                '${p.price} THB', 
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _C.ink,
                ),
              ),
              if (p.oldPrice != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${p.oldPrice} THB',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _C.faint,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${p.building} · ${p.minutes} min',
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 40, color: _C.faint),
          SizedBox(height: 12),
          Text(
            'Nothing here yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _C.ink,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Try "Same zone" or "All campus" to see more.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _C.muted),
          ),
        ],
      ),
    );
  }
}
