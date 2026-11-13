import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/model/format.dart';
import 'package:uni_swap/model/product.dart';
import 'package:uni_swap/model/category.dart';
import 'package:uni_swap/model/enums.dart';
import 'package:uni_swap/model/location.dart';
import 'package:uni_swap/view/user/location_picker.dart';
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

enum _Sort {
  priceLow('Price: low to high'),
  priceHigh('Price: high to low');

  const _Sort(this.label);
  final String label;
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchCtrl = TextEditingController();

  String _category = 'All';
  double _priceMin = 0;
  double? _priceMax;
  final Set<int> _locations = {};
  ResidenceZone _locationZone = ResidenceZone.onCampus;
  _Sort _sort = _Sort.priceLow;

  List<Product> _products = [];
  List<Category> _categories = [];
  List<Location> _availableLocations = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Load available products from the backend.
  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final responses = await Future.wait<Object>([
        productController.browse(),
        productController.categories(),
        productController.locations(),
      ]);
      final response = responses[0] as Map<String, dynamic>;

      if (response['success'] != true || response['data'] is! List) {
        throw const ApiException(
          'The server returned an invalid product response.',
        );
      }

      final rows = response['data'] as List;

      final products = rows.whereType<Map>().map((row) {
        final json = Map<String, dynamic>.from(row);

        // Browse API already filters available products,
        // but does not include the status field in its SELECT.
        json['status'] ??= 'available';

        return Product.fromJson(json);
      }).toList();
      final categories = (responses[1] as List<Map<String, dynamic>>)
          .map(Category.fromJson)
          .toList(growable: false);
      final locations = (responses[2] as List<Map<String, dynamic>>)
          .map(Location.fromJson)
          .toList(growable: false);

      if (!mounted) return;

      setState(() {
        _products = products;
        _categories = categories;
        _availableLocations = locations;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _loadError = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadError = 'Could not load products. Please try again.';
        _isLoading = false;
      });
    }
  }

  // Filter and sort products locally.
  List<Product> get _results {
    final q = _searchCtrl.text.trim().toLowerCase();

    final list = _products.where((p) {
      if (q.isNotEmpty && !p.title.toLowerCase().contains(q)) {
        return false;
      }

      if (_category != 'All' && p.categoryLabel != _category) {
        return false;
      }

      if (p.price < _priceMin) {
        return false;
      }

      if (_priceMax != null && p.price > _priceMax!) {
        return false;
      }

      if (_locations.isNotEmpty &&
          (p.locationId == null || !_locations.contains(p.locationId))) {
        return false;
      }

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
    if (_priceMin == 0 && _priceMax == null) {
      return 'Any price';
    }

    if (_priceMax == null) {
      return 'From ${_priceMin.round()} THB';
    }

    return '${_priceMin.round()} – ${_priceMax!.round()} THB';
  }

  String get _locationLabel {
    if (_locations.isEmpty) return 'All campus';

    final matches = _availableLocations.where(
      (location) => location.id == _locations.first,
    );
    final firstName = matches.isEmpty
        ? 'Selected location'
        : matches.first.name;

    return _locations.length == 1
        ? firstName
        : '$firstName +${_locations.length - 1}';
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
    var zone = _locationZone;

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

                Row(
                  children: [
                    for (final z in ResidenceZone.values)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Container(
                              width: double.infinity,
                              alignment: Alignment.center,
                              child: Text(locationZoneLabel(z)),
                            ),
                            selected: zone == z,
                            onSelected: (_) {
                              setSheet(() => zone = z);
                            },
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
                      for (final l in _availableLocations.where(
                        (location) => location.zone == zone,
                      ))
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          activeColor: _C.ink,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(l.name),
                          value: temp.contains(l.id),
                          onChanged: (on) {
                            setSheet(() {
                              if (on == true) {
                                temp.add(l.id);
                              } else {
                                temp.remove(l.id);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context, <int>{});
                        },
                        child: const Text('Any location'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(context, temp);
                        },
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
        _locationZone = zone;
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

    if (picked != null) {
      setState(() => _sort = picked);
    }
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                                  _sort.label,
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

            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadError != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          size: 40,
                          color: _C.faint,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Could not load products',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _C.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: _C.muted),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _loadProducts,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
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
                onPressed: () {
                  setState(_searchCtrl.clear);
                },
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
          _buildChip('All', null),
          const SizedBox(width: 10),
          for (final category in _categories) ...[
            _buildChip(category.name, categoryIcon(category.name)),
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
            const SizedBox(width: 16),
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
        mainAxisAlignment: MainAxisAlignment.center,
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

  Widget _buildProductCard(Product p) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ProductDetailPage(product: ProductDetail.fromProduct(p)),
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
                  _buildImage(p.primaryImageUrl),

                  if (p.isUrgent)
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
            p.locationName.isEmpty ? 'Location not specified' : p.locationName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

    if (url == null || url.isEmpty) {
      return placeholder;
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}

/// ช่องกรอกราคาต่ำสุด-สูงสุด
/// เว้นว่างช่องสูงสุด = ไม่จำกัด
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

  Widget _field(TextEditingController c, String label, String hint) {
    return Expanded(
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
  }

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
                    onPressed: () {
                      Navigator.pop(context, (0.0, null));
                    },
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
