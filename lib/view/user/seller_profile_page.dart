import 'package:flutter/material.dart';
import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/model/format.dart';
import 'package:uni_swap/model/json_utils.dart';
import 'package:uni_swap/model/product.dart';

class _C {
  static const bg = Color(0xFFFAF9F6);
  static const ink = Color(0xFF2F2F2B);
  static const muted = Color(0xFF7A7973);
  static const faint = Color(0xFFA9A8A2);
  static const surface = Color(0xFFF3F2EE);
}

class SellerProfilePage extends StatefulWidget {
  const SellerProfilePage({super.key, required this.sellerId});

  /// users.user_id ของผู้ขาย (SellerInfo.id)
  final int sellerId;

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  static const _pageSize = 20;

  SellerProfile? _seller;
  List<Product> _items = [];
  int _page = 1;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  ({SellerProfile seller, List<Product> items, bool hasMore}) _parse(
    Map<String, dynamic> response,
  ) {
    if (response['success'] != true || response['data'] is! Map) {
      throw const ApiException('The server returned an invalid seller profile.');
    }
    final data = jsonObject(response['data']);
    final seller = SellerProfile.fromJson(jsonObject(data['seller']));
    if (seller.id <= 0) {
      throw const ApiException('The server returned an invalid seller profile.');
    }
    return (
      seller: seller,
      items: jsonParseList(data['items'], Product.fromJson),
      hasMore: jsonBool(response['has_more']) ?? false,
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = _parse(
        await productController.seller(widget.sellerId, limit: _pageSize),
      );
      if (mounted) {
        setState(() {
          _seller = result.seller;
          _items = result.items;
          _page = 1;
          _hasMore = result.hasMore;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load this seller.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final result = _parse(
        await productController.seller(
          widget.sellerId,
          page: _page + 1,
          limit: _pageSize,
        ),
      );
      if (mounted) {
        setState(() {
          _items = [..._items, ...result.items];
          _page += 1;
          _hasMore = result.hasMore;
        });
      }
    } on ApiException catch (error) {
      _toast(error.message);
    } catch (_) {
      _toast('Could not load more items.');
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              )
            else ...[
              _buildIdentity(_seller!),
              const SizedBox(height: 24),
              const Text(
                'Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _C.ink,
                ),
              ),
              const SizedBox(height: 18),
              _buildItems(),
              if (_hasMore)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: _loadingMore
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton(
                            onPressed: _loadMore,
                            child: const Text('Load more'),
                          ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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

  String _memberSince(DateTime? date) {
    if (date == null) return 'Member since —';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Member since ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildIdentity(SellerProfile seller) {
    final location = seller.locationName.trim();
    return Column(
      children: [
        CircleAvatar(
          radius: 38,
          backgroundColor: const Color(0xFFE9E1D9),
          child: Text(
            seller.initials,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 26,
              color: Color(0xFF5B534B),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          seller.name,
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 24,
            color: _C.ink,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.location_on_outlined,
                size: 14,
                color: _C.muted,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    if (location.isNotEmpty) TextSpan(text: '$location · '),
                    TextSpan(text: _memberSince(seller.memberSince)),
                  ],
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: _C.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${seller.completedSales} completed sales',
          style: const TextStyle(fontSize: 12, color: _C.muted),
        ),
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
        final item = _items[i];
        final imageUrl = item.primaryImageUrl;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox.expand(
                  child: imageUrl == null
                      ? Container(
                          color: _C.surface,
                          child: const Icon(
                            Icons.image_outlined,
                            size: 30,
                            color: _C.faint,
                          ),
                        )
                      : Image.network(
                          imageUrl,
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
              item.title,
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
              formatPriceTHB(item.price),
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
