import 'package:flutter/material.dart';
import 'package:uni_swap/view/user/product_detail_page.dart';

// ไฟล์นี้ใช้งานได้ด้วยตัวเอง

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
    required this.category,
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
  final String category;
  final String place;
  final int minutes;
  final String? imageUrl;
  final bool urgent;

  String get building => place.split(' · ').last;
}

enum _Sort {
  closest('Closest first'),
  priceLow('Price: low to high'),
  priceHigh('Price: high to low');

  const _Sort(this.label);
  final String label;
}

// ===== ข้อมูลตัวอย่าง: TODO แทนด้วยข้อมูลจาก API =====
const _categories = <(String, IconData?)>[
  ('All', null),
  ('Furniture', Icons.chair_alt_outlined),
  ('Books', Icons.menu_book_outlined),
  ('Tech', Icons.computer_outlined),
  ('Music', Icons.music_note_outlined),
  ('Transport', Icons.pedal_bike_outlined),
];

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
    category: 'Furniture',
    place: 'North Campus · Maple Hall',
    minutes: 2,
    urgent: true,
  ),
  _Product(
    id: '2',
    title: 'Acoustic guitar',
    price: 80,
    category: 'Music',
    place: 'North Campus · Maple Hall',
    minutes: 4,
  ),
  _Product(
    id: '3',
    title: 'Calculus textbook',
    price: 20,
    category: 'Books',
    place: 'North Campus · Maple Hall',
    minutes: 3,
  ),
  _Product(
    id: '4',
    title: 'Desk lamp',
    price: 12,
    category: 'Furniture',
    place: 'North Campus · Oak Hall',
    minutes: 6,
  ),
  _Product(
    id: '5',
    title: 'Laptop stand',
    price: 18,
    category: 'Tech',
    place: 'North Campus · Oak Hall',
    minutes: 7,
  ),
  _Product(
    id: '6',
    title: 'City bike',
    price: 120,
    oldPrice: 150,
    category: 'Transport',
    place: 'South Campus · Cedar Hall',
    minutes: 12,
  ),
];

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const double _maxPrice = 200;

  final _searchCtrl = TextEditingController();
  String _category = 'All';
  RangeValues _price = const RangeValues(0, _maxPrice);
  final Set<String> _locations = {}; // ว่าง = ทุกที่
  _Sort _sort = _Sort.closest;
  final Set<String> _favorites = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ===== ตรรกะค้นหา/กรอง/เรียง (ให้เพื่อนย้ายไปทำที่ backend ได้ภายหลัง) =====
  List<_Product> get _results {
    final q = _searchCtrl.text.trim().toLowerCase();
    final list = _products.where((p) {
      if (q.isNotEmpty && !p.title.toLowerCase().contains(q)) return false;
      if (_category != 'All' && p.category != _category) return false;
      if (p.price < _price.start || p.price > _price.end) return false;
      if (_locations.isNotEmpty && !_locations.contains(p.place)) return false;
      return true;
    }).toList();

    switch (_sort) {
      case _Sort.closest:
        list.sort((a, b) => a.minutes.compareTo(b.minutes));
      case _Sort.priceLow:
        list.sort((a, b) => a.price.compareTo(b.price));
      case _Sort.priceHigh:
        list.sort((a, b) => b.price.compareTo(a.price));
    }
    return list;
  }

  bool get _hasFilters =>
      _searchCtrl.text.isNotEmpty ||
      _category != 'All' ||
      _locations.isNotEmpty ||
      _price.start > 0 ||
      _price.end < _maxPrice;

  String get _priceLabel => (_price.start == 0 && _price.end == _maxPrice)
      ? 'Any price'
      : '${_price.start.round()} THB – ${_price.end.round()} THB';

  String get _locationLabel {
    if (_locations.isEmpty) return 'All campus';
    final first = _locations.first.split(' · ').last;
    return _locations.length == 1 ? first : '$first +${_locations.length - 1}';
  }

  void _clearAll() {
    setState(() {
      _searchCtrl.clear();
      _category = 'All';
      _price = const RangeValues(0, _maxPrice);
      _locations.clear();
    });
  }

  // ===== หน้าต่างเลือกตัวกรอง =====
  Future<void> _pickPrice() async {
    var temp = _price;
    final result = await showModalBottomSheet<RangeValues>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Price range',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '${temp.start.round()} THB – ${temp.end.round()} THB',
                  style: const TextStyle(fontSize: 15, color: _C.muted),
                ),
                RangeSlider(
                  values: temp,
                  min: 0,
                  max: _maxPrice,
                  divisions: 40,
                  activeColor: _C.ink,
                  inactiveColor: _C.border,
                  onChanged: (v) => setSheet(() => temp = v),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, temp),
                    style: FilledButton.styleFrom(backgroundColor: _C.ink),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null) setState(() => _price = result);
  }

  Future<void> _pickLocations() async {
    final temp = {..._locations};
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                for (final p in _places)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: _C.ink,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(p),
                    value: temp.contains(p),
                    onChanged: (on) => setSheet(() {
                      on == true ? temp.add(p) : temp.remove(p);
                    }),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, <String>{}),
                        child: const Text('Any location'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, temp),
                        style: FilledButton.styleFrom(backgroundColor: _C.ink),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _locations
          ..clear()
          ..addAll(result);
      });
    }
  }

  Future<void> _pickSort() async {
    final picked = await showModalBottomSheet<_Sort>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in _Sort.values)
              ListTile(
                title: Text(s.label),
                trailing: s == _sort
                    ? const Icon(Icons.check, color: _C.ink)
                    : null,
                onTap: () => Navigator.pop(context, s),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _sort = picked);
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final items = _results;

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Search',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _C.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSearchBar(),
                    const SizedBox(height: 24),
                    _buildCategoryHeader(),
                    const SizedBox(height: 14),
                    _buildCategoryChips(),
                    const SizedBox(height: 24),
                    _buildFilterBox(),
                    const SizedBox(height: 28),
                    Text(
                      '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                      style: const TextStyle(fontSize: 20, color: _C.ink),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _sort.label,
                          style: const TextStyle(fontSize: 13, color: _C.muted),
                        ),
                        GestureDetector(
                          onTap: _pickSort,
                          child: const Text(
                            'Sort by',
                            style: TextStyle(
                              fontSize: 13,
                              color: _C.muted,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (items.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState())
            else
              SliverPadding(
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

  Widget _buildSearchBar() {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );

    return TextField(
      controller: _searchCtrl,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 15, color: _C.ink),
      decoration: InputDecoration(
        hintText: 'Search desks, books, bikes...',
        hintStyle: const TextStyle(color: _C.faint),
        prefixIcon: const Icon(Icons.search, color: _C.muted),
        suffixIcon: _searchCtrl.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 20, color: _C.muted),
                onPressed: () => setState(_searchCtrl.clear),
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        filled: true,
        fillColor: Colors.white,
        border: border(_C.border),
        enabledBorder: border(_C.border),
        focusedBorder: border(_C.ink, 1.5),
      ),
    );
  }

  Widget _buildCategoryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _C.ink,
          ),
        ),
        // แสดงเฉพาะตอนมีตัวกรองอยู่
        if (_hasFilters)
          GestureDetector(
            onTap: _clearAll,
            child: const Text(
              'Clear all',
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

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (label, icon) in _categories) ...[
            _buildChip(label, icon),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData? icon) {
    final selected = _category == label;
    return GestureDetector(
      onTap: () => setState(() => _category = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _C.ink : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _C.ink : _C.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? Colors.white : _C.muted),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? Colors.white : _C.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBox() {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _C.border),
      ),
      child: Column(
        children: [
          _buildFilterRow(
            icon: Icons.sell_outlined,
            title: 'Price range',
            value: _priceLabel,
            onTap: _pickPrice,
          ),
          const Divider(height: 1, color: _C.border),
          _buildFilterRow(
            icon: Icons.map_outlined,
            title: 'Location',
            value: _locationLabel,
            onTap: _pickLocations,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 20, color: _C.muted),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 14, color: _C.ink)),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: _C.muted),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 20, color: _C.muted),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 40, color: _C.faint),
          const SizedBox(height: 12),
          const Text(
            'No items found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _C.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try a different keyword or loosen your filters.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _C.muted),
          ),
          if (_hasFilters) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _clearAll,
              child: const Text('Clear all'),
            ),
          ],
        ],
      ),
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
              category: p.category,
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
