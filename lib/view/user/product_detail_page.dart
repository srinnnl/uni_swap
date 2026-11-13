import 'package:flutter/material.dart';
import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/model/format.dart';
import 'package:uni_swap/model/order_status.dart';
import 'package:uni_swap/model/product.dart';
import 'package:uni_swap/view/user/arrange_meetup_page.dart';
import 'package:uni_swap/view/user/product_categories.dart';
import 'package:uni_swap/view/user/seller_profile_page.dart';

class _C {
  static const bg = Color(0xFFFAF9F6);
  static const ink = Color(0xFF2F2F2B);
  static const muted = Color(0xFF7A7973);
  static const faint = Color(0xFFA9A8A2);
  static const border = Color(0xFFE6E4DD);
  static const surface = Color(0xFFF3F2EE);
}

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.product});

  final ProductDetail product;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final _pageCtrl = PageController();
  int _imageIndex = 0;
  ProductDetail? _loadedProduct;
  bool _ordered = false;
  bool _isOrdering = false;

  ProductDetail get _p => _loadedProduct ?? widget.product;

  @override
  void initState() {
    super.initState();
    if (widget.product.product != null &&
        widget.product.imageUrls.length <= 1) {
      _loadFullProduct();
    }
  }

  // ซื้อได้เฉพาะสินค้า available ที่ไม่ใช่ของตัวเอง และยังไม่ได้สั่งในหน้านี้
  bool get _canBuy =>
      _p.status == ProductStatus.available &&
      !_p.isOwnItem &&
      !_ordered &&
      !_isOrdering;

  String get _buttonLabel {
    if (_p.isOwnItem) return 'Your item';
    if (_ordered) return 'Order placed';
    if (_isOrdering) return 'Placing order…';
    return switch (_p.status) {
      ProductStatus.available => 'Buy now',
      ProductStatus.reserved => 'Reserved',
      ProductStatus.sold => 'Sold',
      ProductStatus.hidden ||
      ProductStatus.pendingReview ||
      ProductStatus.changesRequested ||
      ProductStatus.rejected => 'Unavailable',
    };
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadFullProduct() async {
    try {
      final response = await productController.detail(widget.product.id);
      if (response['success'] != true || response['data'] is! Map) {
        throw const ApiException(
          'The server returned invalid product details.',
        );
      }

      final product = ProductDetail.fromJson(
        Map<String, dynamic>.from(response['data'] as Map),
      );
      if (mounted) setState(() => _loadedProduct = product);
    } on ApiException catch (error) {
      if (mounted) {
        _toast('Could not load all product photos: ${error.message}');
      }
    }
  }

  // Buy now: use the seller's listed location and selected time to create an order.
  Future<void> _buyNow() async {
    final sellerName = _p.seller?.name ?? 'the seller';
    final confirmed = await Navigator.push<MeetupChoice>(
      context,
      MaterialPageRoute(
        builder: (_) => ArrangeMeetupPage(
          productTitle: _p.title,
          price: _p.price,
          sellerName: sellerName,
          sellerLocation: _p.place,
        ),
      ),
    );

    if (confirmed == null || !mounted) return;

    setState(() => _isOrdering = true);
    try {
      final response = await orderController.create(
        productId: _p.id,
        meetupLocation: _p.place,
        meetupDateTime: confirmed.when,
      );
      if (response['success'] != true) {
        throw ApiException(
          response['message']?.toString() ?? 'Could not place the order.',
        );
      }

      final orderId = int.tryParse(response['order_id']?.toString() ?? '');
      if (orderId == null) {
        throw const ApiException('The server did not return an order ID.');
      }
      if (!mounted) return;

      setState(() => _ordered = true);
      _toast('Order #US-$orderId placed with $sellerName');
    } on ApiException catch (error) {
      if (mounted) _toast(error.message);
    } catch (_) {
      if (mounted) {
        _toast('Could not place the order. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isOrdering = false);
    }
  }

  void _openSeller() {
    final s = _p.seller;
    if (s == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SellerProfilePage(name: s.name, location: _p.place, sales: s.sales),
      ),
    );
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
                    errorBuilder: (_, _, _) => _imagePlaceholder(),
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

  Widget _buildContent() {
    final seller = _p.seller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_p.category != null) ...[
              Icon(categoryIcon(_p.category), size: 16, color: _C.muted),
              const SizedBox(width: 6),
              Text(
                _p.category!,
                style: const TextStyle(fontSize: 12, color: _C.muted),
              ),
            ],
            const Spacer(),
            if (_p.urgent) _urgentBadge(),
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
        Text(
          formatPriceTHB(_p.price),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: _C.ink,
          ),
        ),

        if (_p.product?.itemCondition != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 16, color: _C.muted),
                const SizedBox(width: 6),
                Text(
                  'Condition: ${_p.product!.itemCondition!.name.replaceAll('_', ' ').toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _C.muted,
                  ),
                ),
              ],
            ),
          ),
        ],

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

  Widget _buildSeller(SellerInfo s) {
    return InkWell(
      onTap: _openSeller,
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
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 16,
                      color: _C.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${s.sales} sales',
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
                    formatPriceTHB(_p.price),
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
                  onPressed: _canBuy ? _buyNow : null,
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
                    _buttonLabel,
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
