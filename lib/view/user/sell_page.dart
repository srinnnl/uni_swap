import 'package:flutter/material.dart';
import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/model/category.dart';
import 'package:uni_swap/model/location.dart';
import 'package:uni_swap/view/user/product_categories.dart';
import 'package:image_picker/image_picker.dart';

// ---- colors (local to this file) ----
const _cBg = Color(0xFFFAF9F6);
const _cCard = Color(0xFFFFFFFF);
const _cInk = Color(0xFF2B2B26);
const _cMuted = Color(0xFF8A8A82);
const _cBorder = Color(0xFFE6E4DE);
const _cChip = Color(0xFFF0EEE9);
const _cSageDark = Color(0xFF3F6B52);
const _cRedBg = Color(0xFFF8DADA);
const _cRedFg = Color(0xFFB3402F);

// ข้อมูลสินค้าเดิมสำหรับโหมดแก้ไข (แถวใน products)
class SellDraft {
  const SellDraft({
    required this.productId,
    required this.title,
    required this.price,
    required this.categoryId,
    this.description = '',
    this.pickupNote = '',
    this.condition,
    this.deadline,
    this.imageUrl,
    this.imageUrls = const <String>[],
    this.imageCount = 0,
  });

  final int productId; // products.product_id
  final String title;
  final double price;
  final int categoryId; // products.category_id
  final String description;
  final String pickupNote;
  final String? condition; // products.item_condition (null = ไม่ระบุ)
  final DateTime? deadline; // products.clearance_deadline
  final String? imageUrl; // cover (fallback when imageUrls is empty)
  final List<String> imageUrls; // all saved photos, in display order
  final int imageCount;
}

class SellResult {
  const SellResult({required this.message, this.isError = false});

  final String message;
  final bool isError;
}

class SellPage extends StatefulWidget {
  // existing != null = โหมดแก้ไข (เปิดจาก My items > Edit item / Fix item)
  const SellPage({super.key, this.existing});

  final SellDraft? existing;

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  static const _maxPhotos = 6;

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _pickupNoteCtrl = TextEditingController();
  final _picker = ImagePicker();

  final List<XFile> _photos = [];
  List<Category> _categories = [];
  Category? _selectedCategory;
  Location? _pickup;
  String? _optionsError;
  bool _loadingOptions = true;
  bool _isSubmitting = false;
  bool _isDirty = false;
  bool _showingDiscardDialog = false;
  // products.item_condition: new / like_new / good / fair (ไม่เลือก = NULL)
  static const _conditions = <(String, String)>[
    ('new', 'New'),
    ('like_new', 'Like new'),
    ('good', 'Good'),
    ('fair', 'Fair'),
  ];
  int? _conditionIndex;
  bool _isFree = false;
  DateTime? _deadline;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _descCtrl.text = e.description;
      _pickupNoteCtrl.text = e.pickupNote;
      _isFree = e.price == 0;
      _priceCtrl.text = e.price == e.price.roundToDouble()
          ? e.price.toInt().toString()
          : e.price.toString();
      final ki = _conditions.indexWhere((c) => c.$1 == e.condition);
      _conditionIndex = ki >= 0 ? ki : null;
      _deadline = e.deadline;
    }
    _titleCtrl.addListener(_markDirty);
    _priceCtrl.addListener(_markDirty);
    _descCtrl.addListener(_markDirty);
    _pickupNoteCtrl.addListener(_markDirty);
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final responses = await Future.wait<Object>([
        productController.categories(),
        productController.locations(),
        authController.loadProfile(),
      ]);
      final categories = (responses[0] as List<Map<String, dynamic>>)
          .map(Category.fromJson)
          .toList(growable: false);
      final locations = (responses[1] as List<Map<String, dynamic>>)
          .map(Location.fromJson)
          .toList(growable: false);
      final residenceId = int.tryParse(
        authController.user?['residence_location_id']?.toString() ?? '',
      );
      final residenceMatches = locations.where(
        (location) => location.id == residenceId,
      );
      if (categories.isEmpty) {
        throw const ApiException('Categories are not available.');
      }
      if (residenceMatches.isEmpty) {
        throw const ApiException(
          'Set an approved residence in your profile before listing an item.',
        );
      }
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _pickup = residenceMatches.first;
        _selectedCategory = categories.cast<Category?>().firstWhere(
          (category) => category!.id == widget.existing?.categoryId,
          orElse: () => categories.first,
        );
        _loadingOptions = false;
        _optionsError = null;
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _loadingOptions = false;
          _optionsError = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingOptions = false;
          _optionsError = 'Could not load categories and locations.';
        });
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_markDirty);
    _priceCtrl.removeListener(_markDirty);
    _descCtrl.removeListener(_markDirty);
    _pickupNoteCtrl.removeListener(_markDirty);
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _pickupNoteCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!mounted || _isDirty) return;
    setState(() => _isDirty = true);
  }

  Future<void> _confirmDiscard() async {
    if (_isSubmitting || _showingDiscardDialog) return;
    _showingDiscardDialog = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_isEdit ? 'Discard changes?' : 'Discard this listing?'),
        content: Text(
          _isEdit
              ? 'Your existing listing will stay unchanged.'
              : 'Your listing has not been submitted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: _cRedFg),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    _showingDiscardDialog = false;
    if (discard != true || !mounted) return;
    setState(() => _isDirty = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  void _handleBack() {
    if (_isDirty) {
      _confirmDiscard();
    } else {
      Navigator.maybePop(context);
    }
  }

  void _popAfterSave(SellResult result) {
    if (!mounted) return;
    setState(() => _isDirty = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, result);
    });
  }

  Future<void> _pickPhotos() async {
    final remaining =
        _maxPhotos - (widget.existing?.imageCount ?? 0) - _photos.length;
    if (remaining <= 0) return;
    final picked = await _picker.pickMultiImage();
    if (!mounted) return;
    final additions = picked.take(remaining).toList();
    if (additions.isEmpty) return;
    setState(() {
      _photos.addAll(additions);
      _isDirty = true;
    });
  }

  void _toggleFree(bool v) {
    setState(() {
      _isFree = v;
      _isDirty = true;
      if (v) {
        _priceCtrl.text = '0';
      } else if (_priceCtrl.text == '0') {
        _priceCtrl.clear();
      }
    });
  }

  Future<void> _publish() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnack(context, 'Please fix the errors');
      return;
    }
    final category = _selectedCategory;
    final pickup = _pickup;
    if (category == null || pickup == null) {
      _showSnack(context, 'Choose an available category and pickup location.');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final listing = <String, Object?>{
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': _isFree ? 0 : double.parse(_priceCtrl.text.trim()),
        'category_id': category.id,
        'item_condition': _conditionIndex == null
            ? null
            : _conditions[_conditionIndex!].$1,
        'urgency_level': _deadline == null ? 'normal' : 'urgent',
        'zone': pickup.zone.apiValue,
        'location_id': pickup.id,
        'location_detail': _pickupNoteCtrl.text.trim().isEmpty
            ? null
            : _pickupNoteCtrl.text.trim(),
        'clearance_deadline': _deadline == null ? null : _dateOnly(_deadline!),
      };
      final response = _isEdit
          ? await productController.update(widget.existing!.productId, listing)
          : await productController.create(listing);
      if (response['success'] != true) {
        throw ApiException(
          response['message']?.toString() ?? 'Could not save your listing.',
        );
      }
      final productId = _isEdit
          ? widget.existing!.productId
          : int.tryParse(response['product_id']?.toString() ?? '');
      if (productId == null) {
        throw const ApiException('The server did not return a product ID.');
      }

      try {
        var imageOrder = widget.existing?.imageCount ?? 0;
        for (final photo in _photos) {
          imageOrder++;
          await productController.uploadImage(
            productId,
            bytes: await photo.readAsBytes(),
            fileName: photo.name,
            mimeType: photo.mimeType,
            displayOrder: imageOrder,
          );
        }
      } catch (error, stack) {
        // The listing row already exists at this point, so never report the
        // whole save as failed (a retry would create a duplicate).
        debugPrint('photo upload failed: $error\n$stack');
        final reason = error is ApiException ? error.message : '$error';
        _popAfterSave(
          SellResult(
            message:
                'Listing saved for review, but a photo could not be uploaded: $reason. You can edit it and retry.',
            isError: true,
          ),
        );
        return;
      }

      _popAfterSave(
        SellResult(
          message: _isEdit
              ? 'Changes submitted for admin review.'
              : 'Listing submitted for admin review.',
        ),
      );
    } on ApiException catch (error) {
      if (mounted) _showSnack(context, error.message);
    } catch (error, stack) {
      debugPrint('publish failed: $error\n$stack');
      if (mounted) _showSnack(context, 'Could not save listing. Please retry.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return PopScope<SellResult>(
      canPop: !_isDirty && !_isSubmitting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isDirty && !_isSubmitting) _confirmDiscard();
      },
      child: Scaffold(
        backgroundColor: _cBg,
        body: SafeArea(child: _buildForm()),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.arrow_back), onPressed: _handleBack),
        Expanded(
          child: Column(
            children: [
              Text(
                _isEdit ? 'Edit item' : 'Sell an item',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _cInk,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isEdit
                    ? 'Saving sends it for review again'
                    : 'Takes less than 2 minutes',
                style: const TextStyle(fontSize: 13, color: _cMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48), // ถ่วงให้หัวข้ออยู่กลางพอดี
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          if (_loadingOptions)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_optionsError != null) ...[
            Text(
              _optionsError!,
              style: const TextStyle(color: _cRedFg),
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: _loadOptions,
              child: const Text('Retry loading options'),
            ),
          ],

          const _FieldLabel('Photos'),
          _buildPhotos(),
          const SizedBox(height: 24),

          const _FieldLabel('Item title'),
          TextFormField(
            controller: _titleCtrl,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter a title'
                : (v.trim().length > 100
                      ? 'Too long (max 100 characters)'
                      : null),
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec('e.g. Oak study desk'),
          ),
          const SizedBox(height: 24),

          const _FieldLabel('Category'),
          _TapField(
            onTap: _categories.isEmpty ? () {} : _pickCategory,
            child: Row(
              children: [
                Icon(
                  categoryIcon(_selectedCategory?.name),
                  size: 18,
                  color: const Color(0xFF8B4A3C),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedCategory?.name ?? 'Loading categories…',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const _FieldLabel('Condition'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _conditions.length; i++)
                ChoiceChip(
                  label: Text(_conditions[i].$2),
                  selected: _conditionIndex == i,
                  // กดซ้ำเพื่อยกเลิก (ส่ง null)
                  onSelected: (on) => setState(() {
                    _conditionIndex = on ? i : null;
                    _isDirty = true;
                  }),
                  showCheckmark: false,
                  backgroundColor: Colors.white,
                  selectedColor: _cInk,
                  side: const BorderSide(color: _cBorder),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _conditionIndex == i ? Colors.white : _cInk,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          const _FieldLabel('Price'),
          TextFormField(
            controller: _priceCtrl,
            enabled: !_isFree,
            validator: (v) {
              if (_isFree) return null;
              final p = double.tryParse(v ?? '');
              if (p == null) return 'Please enter a price';
              if (p < 0) return 'Price cannot be negative';
              if (p > 99999999) return 'Price is too high';
              return null;
            },
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _dec(
              '0.00',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 16, right: 8),
                child: Text(
                  'THB',
                  style: TextStyle(fontWeight: FontWeight.w700, color: _cMuted),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          _AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Give away for free',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Set the price to 0 THB',
                        style: TextStyle(fontSize: 12, color: _cMuted),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isFree,
                  onChanged: _toggleFree,
                  activeThumbColor: Colors.white,
                  activeTrackColor: _cSageDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const _FieldLabel('Pickup location'),
          _AppCard(
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Color(0xFF8B4A3C),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    _pickup == null
                        ? 'Loading your residence…'
                        : '${_pickup!.zone.apiValue == 'on_campus' ? 'On-campus' : 'Off-campus'} · ${_pickup!.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Pickup is set to the residence saved in your profile.',
              style: TextStyle(fontSize: 12, color: _cMuted),
            ),
          ),
          const SizedBox(height: 16),

          const _FieldLabel('Pickup detail (optional)'),
          TextFormField(
            controller: _pickupNoteCtrl,
            maxLength: 255,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec('e.g. Meet at the main entrance'),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Visible to buyers. Do not include your room number or private contact details.',
              style: TextStyle(fontSize: 12, color: _cMuted),
            ),
          ),
          const SizedBox(height: 24),

          const _FieldLabel('Move-out deadline'),
          _TapField(
            onTap: _pickDeadline,
            trailing: _deadline == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _deadline = null;
                      _isDirty = true;
                    }),
                  ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18),
                const SizedBox(width: 10),
                Text(
                  _deadline == null ? 'Select a date' : _formatDate(_deadline!),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_deadline != null) ...[
                  const SizedBox(width: 10),
                  const _StatusBadge(label: 'Urgent', bg: _cRedBg, fg: _cRedFg),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Adding a deadline marks your item as Urgent.',
            style: TextStyle(fontSize: 12, color: _cMuted),
          ),
          const SizedBox(height: 24),

          const _FieldLabel('Description'),
          TextFormField(
            controller: _descCtrl,
            maxLines: 4,
            minLines: 4,
            decoration: _dec('Condition, size, pickup details...'),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed:
                  _isSubmitting || _loadingOptions || _optionsError != null
                  ? null
                  : _publish,
              style: FilledButton.styleFrom(
                backgroundColor: _cInk,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _isSubmitting
                    ? 'Saving listing…'
                    : _isEdit
                    ? 'Save and resubmit'
                    : 'Publish item',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCategory() async {
    final selected = await showModalBottomSheet<Category>(
      context: context,
      backgroundColor: _cBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            for (final category in _categories)
              ListTile(
                leading: Icon(categoryIcon(category.name)),
                title: Text(category.name),
                trailing: category.id == _selectedCategory?.id
                    ? const Icon(Icons.check, color: _cSageDark)
                    : null,
                onTap: () {
                  Navigator.pop(ctx, category);
                },
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedCategory = selected;
        _isDirty = true;
      });
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) {
      setState(() {
        _deadline = d;
        _isDirty = true;
      });
    }
  }

  Widget _buildPhotos() {
    final existing = widget.existing;
    final existingUrls = <String>[
      if (existing != null && existing.imageUrls.isNotEmpty)
        ...existing.imageUrls
      else if (existing?.imageUrl != null && existing!.imageUrl!.isNotEmpty)
        existing.imageUrl!,
    ];
    final existingCount = existing?.imageCount ?? 0;
    final hasExistingPhoto = existingUrls.isNotEmpty;
    if (_photos.isEmpty && !hasExistingPhoto) {
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _pickPhotos,
        child: CustomPaint(
          painter: _DashedBorderPainter(),
          child: Container(
            height: 110,
            alignment: Alignment.center,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_camera_outlined, size: 26),
                SizedBox(height: 8),
                Text(
                  'Add up to 6 photos',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'First photo will be the cover',
                  style: TextStyle(fontSize: 11, color: _cMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final hasAddButton = existingCount + _photos.length < _maxPhotos;
    final localOffset = existingUrls.length;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: localOffset + _photos.length + (hasAddButton ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          if (hasAddButton && i == localOffset + _photos.length) {
            return InkWell(
              onTap: _pickPhotos,
              child: Container(
                width: 96,
                decoration: BoxDecoration(
                  color: _cChip,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_a_photo_outlined),
              ),
            );
          }
          if (i < localOffset) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                existingUrls[i],
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 96,
                  height: 96,
                  color: _cChip,
                  child: const Icon(Icons.image_outlined),
                ),
              ),
            );
          }
          final photoIndex = i - localOffset;
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FutureBuilder(
                  future: _photos[photoIndex].readAsBytes(),
                  builder: (_, snap) => Container(
                    width: 96,
                    height: 96,
                    color: _cChip,
                    child: snap.hasData
                        ? Image.memory(snap.data!, fit: BoxFit.cover)
                        : null,
                  ),
                ),
              ),
              if (!hasExistingPhoto && photoIndex == 0)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _cInk,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Cover',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              Positioned(
                right: 4,
                top: 4,
                child: GestureDetector(
                  onTap: () => setState(() {
                    _photos.removeAt(photoIndex);
                    _isDirty = true;
                  }),
                  child: const CircleAvatar(
                    radius: 10,
                    backgroundColor: _cInk,
                    child: Icon(Icons.close, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TapField extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final Widget? trailing;
  const _TapField({required this.child, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return _AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(child: child),
          trailing ?? const Icon(Icons.chevron_right, size: 20, color: _cInk),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC9C7BF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)),
      );
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

InputDecoration _dec(String hint, {Widget? prefix}) {
  OutlineInputBorder b(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: c),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFB0AFA8), fontSize: 14),
    filled: true,
    fillColor: _cCard,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    prefixIcon: prefix,
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    border: b(_cBorder),
    enabledBorder: b(_cBorder),
    disabledBorder: b(_cBorder),
    focusedBorder: b(_cInk),
    errorBorder: b(_cRedFg),
    focusedErrorBorder: b(_cRedFg),
  );
}

// ---- small shared widgets (local to this file) ----
class _AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const _AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _cInk,
      ),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _StatusBadge({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
    ),
  );
}

String _formatDate(DateTime d) {
  const m = [
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
  return '${m[d.month - 1]} ${d.day}, ${d.year}';
}

void _showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _cInk,
      ),
    );
}
