import 'package:flutter/material.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/model/format.dart';
import 'package:uni_swap/model/product.dart';
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _tabs = ['Same place', 'Same zone', 'Explore all'];

  int _tab = 0;

  CampusLocation _place = locationsIn(CampusZone.onCampus).first;

  List<Product> _products = [];

  bool _isLoading = true;
  String? _errorMessage;

  CampusZone get _zone => _place.zone;
  String get _building => _place.name;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // ===== Load products from API =====

  Future<void> _loadProducts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await productController.browse(page: 1, limit: 100);

      if (response['success'] != true) {
        throw Exception(
          response['message']?.toString() ?? 'Could not load products.',
        );
      }

      final rows = (response['data'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

      final products = rows.map((json) {
        // GET /api/products returns available products only,
        // but the current SQL query does not include the status field.
        // Set it explicitly so Product.fromJson does not use pendingReview.
        json.putIfAbsent('status', () => 'available');

        return Product.fromJson(json);
      }).toList();

      if (!mounted) return;

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ===== Filter products =====

  List<Product> get _visible {
    switch (_tab) {
      case 0:
        return _products.where((p) {
          if (p.locationId != null) {
            return p.locationId == _place.id;
          }

          return p.locationName.trim().toLowerCase() ==
              _place.name.trim().toLowerCase();
        }).toList();

      case 1:
        return _products.where((p) => p.zone.name == _zone.name).toList();

      default:
        return _products;
    }
  }

  String get _subtitle => switch (_tab) {
    0 => 'Items in $_building',
    1 => 'Items in ${_zone.label}',
    _ => 'Items across campus',
  };

  String get _greeting {
    final h = DateTime.now().hour;
    final part = h < 12 ? 'morning' : (h < 17 ? 'afternoon' : 'evening');
    return 'Good $part';
  }

  // ===== Location picker =====

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

            // ===== Loading =====
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    color: _C.ink,
                    strokeWidth: 2,
                  ),
                ),
              )
            // ===== Error =====
            else if (_errorMessage != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorState(
                  message: _errorMessage!,
                  onRetry: _loadProducts,
                ),
              )
            // ===== Empty =====
            else if (items.isEmpty)
              const SliverToBoxAdapter(child: _EmptyState())
            // ===== Products =====
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

  // ===== Top bar =====

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

  // ===== Location bar =====

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
            const Icon(Icons.chevron_right, color: _C.muted),
          ],
        ),
      ),
    );
  }

  // ===== Tabs =====

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _C.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < _tabs.length; i++) Expanded(child: _buildTab(i)),
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
              textAlign: TextAlign.center,
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

  // ===== Section header =====

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

  // ===== Product card =====

  Widget _buildProductCard(Product p) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ProductDetailPage(product: ProductDetail.fromProduct(p)),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
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
                    child: _buildImage(p.primaryImageUrl),
                  ),
                ),

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
          Row(
            children: [
              const Icon(Icons.location_on, size: 12, color: _C.muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  p.locationName,
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

  // ===== Product image =====

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
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}

// ===== Empty state =====

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

// ===== Error state =====

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40, color: _C.faint),
          const SizedBox(height: 12),
          const Text(
            'Could not load products',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _C.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _C.muted),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _C.ink,
              side: const BorderSide(color: _C.border),
            ),
          ),
        ],
      ),
    );
  }
}
