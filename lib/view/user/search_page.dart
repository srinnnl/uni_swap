import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uni_swap/model/format.dart';
import 'package:uni_swap/model/product.dart';
import 'package:uni_swap/view/user/campus_locations.dart';
import 'package:uni_swap/view/user/product_categories.dart';
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
    required this.category,
    required this.location,
    required this.imageUrl,
    this.urgent = false,
  });

  final int id; // products.product_id
  final String title;
  final double price; // products.price DECIMAL(10,2)
  final String category;
  final CampusLocation location;
  final String imageUrl;
  final bool urgent;

  String get place => location.place;
  String get building => location.name;
}

enum _Sort {
  priceLow('Price: low to high'),
  priceHigh('Price: high to low');

  const _Sort(this.label);
  final String label;
}

final _categories = <(String, IconData?)>[
  ('All', null),
  for (final c in kProductCategories) (c.name, c.icon),
];

final _products = [
  _Product(
    id: 1,
    title: 'Oak study desk',
    price: 45,
    category: 'Furniture',
    location: locationById(12),
    urgent: true,
    imageUrl:
        'https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExcnY2MWllbDFpNnU1bjNtc2Rwbzl5Y2VxemlnbTVtNW5mMWE3b2VrNyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/gKHGnB1ml0moQdjhEJ/giphy.gif',
  ),
  _Product(
    id: 2,
    title: 'Acoustic guitar',
    price: 80,
    category: 'Music',
    location: locationById(12),
    imageUrl:
        'https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExcnY2MWllbDFpNnU1bjNtc2Rwbzl5Y2VxemlnbTVtNW5mMWE3b2VrNyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/gKHGnB1ml0moQdjhEJ/giphy.gif',
  ),
  _Product(
    id: 3,
    title: 'Calculus textbook',
    price: 20,
    category: 'Books',
    location: locationById(12),
    imageUrl:
        'https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExcnY2MWllbDFpNnU1bjNtc2Rwbzl5Y2VxemlnbTVtNW5mMWE3b2VrNyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/gKHGnB1ml0moQdjhEJ/giphy.gif',
  ),
  _Product(
    id: 4,
    title: 'Desk lamp',
    price: 12,
    category: 'Furniture',
    location: locationById(13),
    imageUrl:
        'https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExcnY2MWllbDFpNnU1bjNtc2Rwbzl5Y2VxemlnbTVtNW5mMWE3b2VrNyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/gKHGnB1ml0moQdjhEJ/giphy.gif',
  ),
  _Product(
    id: 5,
    title: 'Laptop stand',
    price: 18,
    category: 'Technology',
    location: locationById(13),
    imageUrl:
        'https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExcnY2MWllbDFpNnU1bjNtc2Rwbzl5Y2VxemlnbTVtNW5mMWE3b2VrNyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/gKHGnB1ml0moQdjhEJ/giphy.gif',
  ),
  _Product(
    id: 6,
    title: 'City bike',
    price: 120,
    category: 'Transport',
    location: locationById(7),
    imageUrl:
        'https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExcnY2MWllbDFpNnU1bjNtc2Rwbzl5Y2VxemlnbTVtNW5mMWE3b2VrNyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/gKHGnB1ml0moQdjhEJ/giphy.gif',
  ),
];

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchCtrl = TextEditingController();
  String _category = 'All';
  double _priceMin = 0;
  double? _priceMax; // null = ไม่จำกัดราคาสูงสุด
  final Set<int> _locations = {};
  _Sort _sort = _Sort.priceLow;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Product> get _results {
    final q = _searchCtrl.text.trim().toLowerCase();
    final list = _products.where((p) {
      if (q.isNotEmpty && !p.title.toLowerCase().contains(q)) return false;
      if (_category != 'All' && p.category != _category) return false;
      if (p.price < _priceMin) return false;
      if (_priceMax != null && p.price > _priceMax!) {
        return false;
      }
      if (_locations.isNotEmpty && !_locations.contains(p.location.id))
        return false;
      return true;
    }).toList();

    switch (_sort) {
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
      _priceMin > 0 ||
      _priceMax != null;

  String get _priceLabel {
    if (_priceMin == 0 && _priceMax == null) return 'Any price';
    if (_priceMax == null) return 'From ${_priceMin.round()} THB';
    return '${_priceMin.round()} – ${_priceMax!.round()} THB';
  }

  String get _locationLabel {
    if (_locations.isEmpty) return 'All campus';
    final first = locationById(_locations.first).name;
    return _locations.length == 1 ? first : '$first +${_locations.length - 1}';
  }

  void _clearAll() {
    setState(() {
      _searchCtrl.clear();
      _category = 'All';
      _priceMin = 0;
      _priceMax = null;
      _locations.clear();
    });
  }

  Future<void> _pickPrice() async {
    final result = await showModalBottomSheet<(double, double?)>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _PriceSheet(min: _priceMin, max: _priceMax),
    );
    if (result != null) {
      setState(() {
        _priceMin = result.$1;
        _priceMax = result.$2;
      });
    }
  }

  Future<void> _pickLocations() async {
    final temp = {..._locations};
    var zone = CampusZone.onCampus; // เลือกหอใน/หอนอกก่อน แล้วค่อยติ๊กหอ
    final result = await showModalBottomSheet<Set<int>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
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
                const SizedBox(height: 12),
                // ✨ เปลี่ยนจาก Wrap เป็น Row แล้วใช้ Expanded ช่วยดันให้เต็มจอ
                Row(
                  children: [
                    for (final z in CampusZone.values)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Container(
                              width: double.infinity,
                              alignment: Alignment.center,
                              child: Text(z.label),
                            ),
                            selected: zone == z,
                            onSelected: (_) => setSheet(() => zone = z),
                            showCheckmark: false,
                            backgroundColor: Colors.white,
                            selectedColor: _C.ink,
                            side: const BorderSide(color: _C.border),
                            labelStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: zone == z ? Colors.white : _C.ink,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      for (final l in locationsIn(zone))
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          activeColor: _C.ink,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(l.name),
                          value: temp.contains(l.id),
                          onChanged: (on) => setSheet(() {
                            on == true ? temp.add(l.id) : temp.remove(l.id);
                          }),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, <int>{}),
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

  @override
  Widget build(BuildContext context) {
    final items = _results;

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: _C.ink,
                          ),
                        ),
                        InkWell(
                          onTap: _pickSort,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.sort, size: 18, color: _C.ink),
                                const SizedBox(width: 6),
                                Text(
                                  _sort
                                      .label, // โชว์คำว่า Price: low to high ตรงนี้เลย
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _C.ink,
                                  ),
                                ),
                              ],
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
              SliverFillRemaining(
                hasScrollBody: false, // บอกว่าข้างในไม่ต้องซ้อน Scroll อีกชั้น
                child: _buildEmptyState(),
              )
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
            const SizedBox(
              width: 16,
            ), // เว้นระยะเผื่อกรณีที่ชื่อยาวจะได้ไม่ชนกัน
            // ✨ เปลี่ยนจาก Spacer() + Flexible มาใช้ Expanded แล้วดัน Text ชิดขวา
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
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
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment
            .center, // ✨ จัดให้อยู่กึ่งกลางพื้นที่ที่มองเห็นได้
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
            formatPriceTHB(p.price),
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

/// ช่องกรอกราคาต่ำสุด-สูงสุด (เว้นว่างช่องสูงสุด = ไม่จำกัด)
class _PriceSheet extends StatefulWidget {
  const _PriceSheet({required this.min, required this.max});
  final double min;
  final double? max;

  @override
  State<_PriceSheet> createState() => _PriceSheetState();
}

class _PriceSheetState extends State<_PriceSheet> {
  late final _minCtrl = TextEditingController(
    text: widget.min > 0 ? widget.min.round().toString() : '',
  );
  late final _maxCtrl = TextEditingController(
    text: widget.max == null ? '' : widget.max!.round().toString(),
  );

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    suffixText: 'THB',
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.ink, width: 1.5),
    ),
  );

  Widget _field(TextEditingController c, String label, String hint) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: _C.muted)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _dec(hint),
        ),
      ],
    ),
  );

  void _apply() {
    var lo = double.tryParse(_minCtrl.text) ?? 0;
    var hi = double.tryParse(_maxCtrl.text);
    if (hi != null && hi < lo) {
      final t = lo;
      lo = hi;
      hi = t;
    }
    Navigator.pop(context, (lo, hi));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom + 40,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price range',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _field(_minCtrl, 'Min', '0'),
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 24, 12, 0),
                  child: Text('–'),
                ),
                _field(_maxCtrl, 'Max', 'No limit'),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, (0.0, null)),
                    child: const Text('Any price'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _apply,
                    style: FilledButton.styleFrom(backgroundColor: _C.ink),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
