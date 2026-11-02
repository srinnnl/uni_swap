import 'package:flutter/material.dart';
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

class SellPage extends StatefulWidget {
  const SellPage({super.key});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  static const _maxPhotos = 6;
  static const _categories = <(String, IconData)>[
    ('Furniture', Icons.chair_alt_outlined),
    ('Electronics', Icons.devices_other_outlined),
    ('Books', Icons.menu_book_outlined),
    ('Clothing', Icons.checkroom_outlined),
    ('Kitchen', Icons.kitchen_outlined),
    ('Bikes', Icons.pedal_bike_outlined),
    ('Music', Icons.music_note_outlined),
    ('Other', Icons.category_outlined),
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _picker = ImagePicker();

  final List<XFile> _photos = [];
  int _categoryIndex = 0;
  bool _isFree = false;
  DateTime? _deadline;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final remaining = _maxPhotos - _photos.length;
    if (remaining <= 0) return;
    final picked = await _picker.pickMultiImage();
    setState(() => _photos.addAll(picked.take(remaining)));
  }

  void _toggleFree(bool v) {
    setState(() {
      _isFree = v;
      if (v) {
        _priceCtrl.text = '0';
      } else if (_priceCtrl.text == '0') {
        _priceCtrl.clear();
      }
    });
  }

  void _publish() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnack(context, 'Please fix the errors');
      return;
    }
    // TODO: call controller / API here later.
    setState(() {
      _titleCtrl.clear();
      _priceCtrl.clear();
      _descCtrl.clear();
      _photos.clear();
      _isFree = false;
      _deadline = null;
      _categoryIndex = 0;
    });
    _formKey.currentState?.reset();
    _showSnack(context, 'Listing published (mock)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cBg,
      body: SafeArea(bottom: false, child: _buildForm()),
    );
  }

  Widget _buildForm() {
    final cat = _categories[_categoryIndex];

    return Form(
      key: _formKey,
      child: ListView(
        // ท้ายหน้าเว้น 120 ให้พ้นแถบเมนูล่าง
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: [
          const _PageHeader(
            title: 'Sell an item',
            subtitle: 'Takes less than 2 minutes',
          ),
          const SizedBox(height: 28),

          const _FieldLabel('Photos'),
          _buildPhotos(),
          const SizedBox(height: 24),

          const _FieldLabel('Item title'),
          TextFormField(
            controller: _titleCtrl,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec('e.g. Oak study desk'),
          ),
          const SizedBox(height: 24),

          const _FieldLabel('Category'),
          _TapField(
            onTap: _pickCategory,
            child: Row(
              children: [
                Icon(cat.$2, size: 18, color: const Color(0xFF8B4A3C)),
                const SizedBox(width: 10),
                Text(
                  cat.$1,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

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
                  activeColor: Colors.white,
                  activeTrackColor: _cSageDark,
                ),
              ],
            ),
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
              return null;
            },
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _dec(
              '0.00',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 16, right: 8),
                child: Text(
                  '\$',
                  style: TextStyle(fontWeight: FontWeight.w700, color: _cMuted),
                ),
              ),
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
                    onPressed: () => setState(() => _deadline = null),
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
            'Adding a deadline marks your listing as Urgent.',
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

          _DarkButton(label: 'Publish listing', onPressed: _publish),
        ],
      ),
    );
  }

  Future<void> _pickCategory() async {
    await showModalBottomSheet(
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
            for (var i = 0; i < _categories.length; i++)
              ListTile(
                leading: Icon(_categories[i].$2),
                title: Text(_categories[i].$1),
                trailing: i == _categoryIndex
                    ? const Icon(Icons.check, color: _cSageDark)
                    : null,
                onTap: () {
                  setState(() => _categoryIndex = i);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _deadline = d);
  }

  Widget _buildPhotos() {
    if (_photos.isEmpty) {
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

    final hasAddButton = _photos.length < _maxPhotos;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _photos.length + (hasAddButton ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          if (i == _photos.length) {
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
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FutureBuilder(
                  future: _photos[i].readAsBytes(),
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
              if (i == 0)
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
                  onTap: () => setState(() => _photos.removeAt(i)),
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
    borderRadius: BorderRadius.circular(12),
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

class _DarkButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _DarkButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: _cInk,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
  );
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

class _PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _PageHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _cInk,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: const TextStyle(fontSize: 13, color: _cMuted)),
        ],
      ],
    );
  }
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
