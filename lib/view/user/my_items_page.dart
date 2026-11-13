import 'package:flutter/material.dart';
import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/model/json_utils.dart';
import 'package:uni_swap/model/order_status.dart';
import 'package:uni_swap/model/product.dart';
import 'package:uni_swap/view/user/sell_page.dart';

const _cBg = Color(0xFFFAF9F6);
const _cInk = Color(0xFF2B2B26);
const _cMuted = Color(0xFF8A8A82);
const _cBorder = Color(0xFFE6E4DE);
const _cAmberBg = Color(0xFFFBEBC2);
const _cAmberFg = Color(0xFF8A6410);
const _cRedBg = Color(0xFFF8DADA);
const _cRedFg = Color(0xFFB3402F);
const _cSageBg = Color(0xFFD8E4DC);
const _cSageFg = Color(0xFF3F6B52);

enum ItemStatus {
  active,
  urgent,
  pending,
  actionRequired,
  rejected,
  reserved,
  sold,
  hidden,
}

class MyItemsPage extends StatefulWidget {
  const MyItemsPage({super.key});

  @override
  State<MyItemsPage> createState() => _MyItemsPageState();
}

class _MyItemsPageState extends State<MyItemsPage> {
  List<Product> _products = [];
  final Set<int> _busyProductIds = {};
  bool _loading = true;
  String? _error;

  int get _activeCount => _products.where((product) {
    return product.status == ProductStatus.available;
  }).length;
  int get _soldCount =>
      _products.where((product) => product.status == ProductStatus.sold).length;
  int get _totalViews =>
      _products.fold(0, (total, product) => total + product.viewCount);

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await productController.myListings(limit: 100);
      if (response['success'] != true || response['data'] is! List) {
        throw const ApiException('The server returned invalid listings.');
      }
      final products = jsonParseList(response['data'], Product.fromJson);
      if (products.any((product) => product.id <= 0)) {
        throw const ApiException('The server returned invalid listing data.');
      }
      if (mounted) setState(() => _products = products);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load your listings.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openSell([Product? product]) async {
    final result = await Navigator.push<SellResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SellPage(existing: product == null ? null : _draft(product)),
      ),
    );
    if (!mounted || result == null) return;
    await _loadItems();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.isError ? _cRedFg : _cInk,
        ),
      );
  }

  Future<bool> _confirmItemAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: _cRedFg),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _deleteUnreviewed(Product product) async {
    if (_busyProductIds.contains(product.id)) return;
    final confirmed = await _confirmItemAction(
      title: 'Delete listing?',
      message:
          'This unreviewed listing and its photos will be permanently deleted.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return;

    setState(() => _busyProductIds.add(product.id));
    try {
      final response = await productController.deleteUnreviewed(product.id);
      if (response['success'] != true) {
        throw ApiException(
          response['message']?.toString() ?? 'Could not delete this listing.',
        );
      }
      await _loadItems();
      if (mounted) _showActionMessage('Listing deleted.');
    } on ApiException catch (error) {
      if (mounted) _showActionMessage(error.message, isError: true);
    } catch (_) {
      if (mounted) {
        _showActionMessage(
          'Could not delete this listing. Please retry.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busyProductIds.remove(product.id));
    }
  }

  Future<void> _hideAvailable(Product product) async {
    if (_busyProductIds.contains(product.id)) return;
    final confirmed = await _confirmItemAction(
      title: 'Take listing off the marketplace?',
      message:
          'Buyers will no longer see this item. Its listing and order history will be kept.',
      confirmLabel: 'Take off marketplace',
    );
    if (!confirmed || !mounted) return;

    setState(() => _busyProductIds.add(product.id));
    try {
      final response = await productController.hideAvailable(product.id);
      if (response['success'] != true) {
        throw ApiException(
          response['message']?.toString() ??
              'Could not take this listing off the marketplace.',
        );
      }
      await _loadItems();
      if (mounted) _showActionMessage('Listing taken off the marketplace.');
    } on ApiException catch (error) {
      if (mounted) _showActionMessage(error.message, isError: true);
    } catch (_) {
      if (mounted) {
        _showActionMessage(
          'Could not take this listing off the marketplace. Please retry.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busyProductIds.remove(product.id));
    }
  }

  void _showActionMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? _cRedFg : _cInk,
        ),
      );
  }

  SellDraft? _draft(Product product) {
    final locationId = product.locationId;
    if (locationId == null ||
        product.status == ProductStatus.reserved ||
        product.status == ProductStatus.sold ||
        product.status == ProductStatus.hidden) {
      return null;
    }
    return SellDraft(
      productId: product.id,
      title: product.title,
      price: product.price,
      description: product.description ?? '',
      pickupNote: product.locationDetail ?? '',
      categoryId: product.categoryId ?? 0,
      condition: product.itemCondition?.apiValue,
      deadline: product.clearanceDeadline,
      imageUrl: product.imageUrl,
      imageUrls: product.images
          .map((image) => image.url)
          .where((url) => url.isNotEmpty)
          .toList(growable: false),
      imageCount: product.imageCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cBg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadItems,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              Center(
                child: Column(
                  children: [
                    const Text(
                      'My items',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _cInk,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_activeCount active items',
                      style: const TextStyle(fontSize: 13, color: _cMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildStats(),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: () => _openSell(),
                  icon: const Icon(Icons.add),
                  label: const Text('Sell a new item'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _cInk,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Recent items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _cInk,
                ),
              ),
              const SizedBox(height: 12),
              if (_loading && _products.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null && _products.isEmpty)
                Column(
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: _loadItems,
                      child: const Text('Try again'),
                    ),
                  ],
                )
              else if (_products.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('You have not listed any items yet.'),
                  ),
                ),
              if (_error != null && _products.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: const TextStyle(color: _cRedFg)),
                ),
              for (final product in _products)
                _ItemCard(
                  product: product,
                  onEdit:
                      _busyProductIds.contains(product.id) ||
                          _draft(product) == null
                      ? null
                      : () => _openSell(product),
                  onDelete:
                      _busyProductIds.contains(product.id) ||
                          !{
                            ProductStatus.pendingReview,
                            ProductStatus.changesRequested,
                            ProductStatus.rejected,
                          }.contains(product.status)
                      ? null
                      : () => _deleteUnreviewed(product),
                  onHide:
                      _busyProductIds.contains(product.id) ||
                          product.status != ProductStatus.available
                      ? null
                      : () => _hideAvailable(product),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats() => Container(
    padding: const EdgeInsets.symmetric(vertical: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _cBorder),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _stat('$_activeCount', 'Active'),
        Container(width: 1, height: 40, color: _cBorder),
        _stat('$_soldCount', 'Sold'),
        Container(width: 1, height: 40, color: _cBorder),
        _stat('$_totalViews', 'Views'),
      ],
    ),
  );

  Widget _stat(String value, String label) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: _cInk,
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: _cMuted)),
    ],
  );
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onHide,
  });

  final Product product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onHide;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (product.status) {
      ProductStatus.pendingReview => ('Pending review', _cAmberBg, _cAmberFg),
      ProductStatus.changesRequested => ('Action required', _cRedBg, _cRedFg),
      ProductStatus.rejected => ('Rejected', _cRedBg, _cRedFg),
      ProductStatus.available when product.isUrgent => (
        'Urgent',
        _cRedBg,
        _cRedFg,
      ),
      ProductStatus.available => ('Active', _cSageBg, _cSageFg),
      ProductStatus.reserved => ('Reserved', _cAmberBg, _cAmberFg),
      ProductStatus.sold => ('Sold', _cSageBg, _cSageFg),
      ProductStatus.hidden => ('Hidden', const Color(0xFFF0EEE9), _cMuted),
    };
    final price = product.price == 0 ? 'Free' : '${product.price} THB';
    final placeholder = Container(
      width: 80,
      height: 94,
      color: const Color(0xFFF0EEE9),
      child: const Icon(Icons.image_outlined, color: _cMuted),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: product.primaryImageUrl == null
                ? placeholder
                : Image.network(
                    product.primaryImageUrl!,
                    width: 80,
                    height: 94,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => placeholder,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Badge(
                      label: label,
                      background: background,
                      foreground: foreground,
                    ),
                    if (product.status == ProductStatus.available ||
                        product.status == ProductStatus.pendingReview)
                      Text(
                        '${product.viewCount} views',
                        style: const TextStyle(fontSize: 11, color: _cMuted),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _cInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$price · ${product.locationName}',
                  style: const TextStyle(fontSize: 12, color: _cMuted),
                ),
                if (product.reviewNote?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    product.reviewNote!,
                    style: const TextStyle(fontSize: 12, color: _cRedFg),
                  ),
                ],
                if (onEdit != null || onDelete != null || onHide != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 4,
                    runSpacing: 0,
                    children: [
                      if (onEdit != null)
                        TextButton(
                          onPressed: onEdit,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            product.status == ProductStatus.changesRequested ||
                                    product.status == ProductStatus.rejected
                                ? 'Fix item'
                                : 'Edit item',
                          ),
                        ),
                      if (onDelete != null)
                        TextButton.icon(
                          onPressed: onDelete,
                          style: TextButton.styleFrom(
                            foregroundColor: _cRedFg,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Delete listing'),
                        ),
                      if (onHide != null)
                        TextButton.icon(
                          onPressed: onHide,
                          style: TextButton.styleFrom(
                            foregroundColor: _cMuted,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(
                            Icons.visibility_off_outlined,
                            size: 16,
                          ),
                          label: const Text('Take off marketplace'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: foreground,
      ),
    ),
  );
}
