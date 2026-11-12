import 'package:flutter/material.dart';
import 'package:uni_swap/model/format.dart';
import 'package:uni_swap/view/user/campus_locations.dart';
import 'package:uni_swap/view/user/product_detail_page.dart';

class _C {
  static const bg = Color(0xFFFAF9F6);
  static const ink = Color(0xFF2F2F2B);
  static const muted = Color(0xFF7A7973);
  static const faint = Color(0xFFA9A8A2);
  static const border = Color(0xFFE6E4DD);
  static const surface = Color(0xFFF3F2EE);
}

class _Product {
  const _Product({
    required this.id,
    required this.title,
    required this.price,
    required this.location,
    required this.imageUrl,
    this.urgent = false,
  });

  final int id; // products.product_id
  final String title;
  final double price; // products.price DECIMAL(10,2)
  final CampusLocation location;
  final String imageUrl; // ถ้าเป็น null จะแสดงรูปแทนที่ชั่วคราว
  final bool urgent;

  CampusZone get zone => location.zone;
  String get place => location.place;
  String get building => location.name;
}

// ===== ข้อมูลตัวอย่าง: TODO แทนด้วยข้อมูลจาก API =====
final _products = [
  _Product(
    id: 1,
    title: 'Oak study desk',
    price: 45,
    location: locationById(12),
    urgent: true,
    imageUrl:
        'https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExcnY2MWllbDFpNnU1bjNtc2Rwbzl5Y2VxemlnbTVtNW5mMWE3b2VrNyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/gKHGnB1ml0moQdjhEJ/giphy.gif',
  ),
  _Product(
    id: 2,
    title: 'Acoustic guitar',
    price: 80,
    location: locationById(12),
    imageUrl:
        'https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExcnY2MWllbDFpNnU1bjNtc2Rwbzl5Y2VxemlnbTVtNW5mMWE3b2VrNyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/gKHGnB1ml0moQdjhEJ/giphy.gif',
  ),
  _Product(
    id: 3,
    title: 'Desk lamp',
    price: 12,
    location: locationById(13),
    imageUrl:
        'https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExcnY2MWllbDFpNnU1bjNtc2Rwbzl5Y2VxemlnbTVtNW5mMWE3b2VrNyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/gKHGnB1ml0moQdjhEJ/giphy.gif',
  ),
  _Product(
    id: 4,
    title: 'City bike',
    price: 120,
    location: locationById(7),
    imageUrl:
        'https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExcnY2MWllbDFpNnU1bjNtc2Rwbzl5Y2VxemlnbTVtNW5mMWE3b2VrNyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/gKHGnB1ml0moQdjhEJ/giphy.gif',
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _tabs = ['Same place', 'Same zone', 'Explore all'];

  // TODO: ดึงจากข้อมูลผู้ใช้หลัง login
  final String _userName = 'Maya';
  final bool _residencePending = false; // true = ที่พักรอ admin ตรวจสอบ

  int _tab = 0;
  CampusLocation _place = locationsIn(CampusZone.onCampus).first;

  CampusZone get _zone => _place.zone;
  String get _building => _place.name;

  List<_Product> get _visible => switch (_tab) {
    0 => _products.where((p) => p.location.id == _place.id).toList(),
    1 => _products.where((p) => p.zone == _zone).toList(),
    _ => _products,
  };

  String get _subtitle => switch (_tab) {
    0 => 'Items in $_building',
    1 => 'Items in ${_zone.label}',
    _ => 'Items across campus',
  };

  String get _greeting {
    final h = DateTime.now().hour;
    final part = h < 12 ? 'morning' : (h < 17 ? 'afternoon' : 'evening');
    return 'Good $part, $_userName';
  }

  Future<void> _pickPlace() async {
    final picked = await showCampusLocationPicker(
      context,
      zone: _place.zone,
      selected: _place,
    );
    if (picked?.location != null) {
      setState(() {
        _place = picked!.location!;
        _tab = 0;
      });
    }
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
                _place.place,
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
        // ✨ ใช้ mainAxisAlignment ช่วยกระจายพื้นที่ (เผื่อไว้)
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < _tabs.length; i++)
            // ✨ ใช้ Expanded หุ้ม Tab ไว้ เพื่อให้แบ่งพื้นที่เท่าๆ กันจนเต็มจอ
            Expanded(child: _buildTab(i)),
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
              textAlign: TextAlign.center, // ✨ จัดตัวหนังสือให้อยู่กึ่งกลาง Tab
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tab == 0
              ? 'Around your place'
              : (_tab == 1 ? 'In your zone' : 'Everywhere'),
          style: const TextStyle(
            fontSize: 20,
            color: _C.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(_subtitle, style: const TextStyle(fontSize: 13, color: _C.muted)),
      ],
    );
  }

  Widget _buildProductCard(_Product p) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailPage(
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ✨ 1. คงเงาบางๆ ไว้ให้รูปดูลอยขึ้นมา
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _C.ink.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildImage(p.imageUrl),
                  ),
                ),

                // ป้าย Urgent เหมือนเดิม
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
            formatPriceTHB(p.price),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _C.ink,
            ),
          ),
          const SizedBox(height: 4),
          // ✨ 2. คงไอคอน Location เล็กๆ ไว้ ช่วยนำสายตาและดูน่ารักขึ้น
          Row(
            children: [
              const Icon(Icons.location_on, size: 12, color: _C.muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  p.building,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _C.muted),
                ),
              ),
            ],
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
