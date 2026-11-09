import 'package:flutter/material.dart';

// ---- colors (local to this file) ----
const _cBg = Color(0xFFFAF9F6);
const _cCard = Color(0xFFFFFFFF);
const _cInk = Color(0xFF2B2B26);
const _cMuted = Color(0xFF8A8A82);
const _cBorder = Color(0xFFE6E4DE);
const _cChip = Color(0xFFF0EEE9);
const _cSage = Color(0xFFD8E4DC);
const _cSageDark = Color(0xFF3F6B52);
const _cBlueBg = Color(0xFFE3ECF7);
const _cBlueFg = Color(0xFF3B5E8C);
const _cAmberBg = Color(0xFFFBEBC2);
const _cAmberFg = Color(0xFF8A6410);
const _cRedBg = Color(0xFFF8DADA);
const _cRedFg = Color(0xFFB3402F);

enum _LStatus { pending, changes }

class _Item {
  final String title;
  final String seller;
  final int price;
  final String category;
  final String place;
  final String submitted;
  final String description;
  final bool urgent;
  final String? flag; // ข้อสังเกตให้แอดมินดูเพิ่ม (ไม่มีคอลัมน์ใน DB ให้ API คำนวณ เช่น ราคาสูงกว่าค่าเฉลี่ยในหมวด หรือตัดทิ้ง)
  // รูปสินค้าทั้งหมดที่ผู้ขายอัปโหลด เรียงตาม product_images.display_order (รูปแรก = ปก)
  // null = ยังไม่มี URL จริง จะแสดงกรอบเทาแทน
  // TODO: ใส่ URL รูปจริงจาก API (ตาราง product_images)
  final List<String?> photos;
  _LStatus status;
  String? note; // ข้อความที่ส่งกลับให้ผู้ขายแก้ไข
  _Item(
    this.title,
    this.seller,
    this.price,
    this.category,
    this.place,
    this.submitted,
    this.description, {
    this.urgent = false,
    this.flag,
    this.photos = const [null],
    this.status = _LStatus.pending,
  });
}

class AdminItemsPage extends StatefulWidget {
  const AdminItemsPage({super.key});

  @override
  State<AdminItemsPage> createState() => _AdminItemsPageState();
}

class _AdminItemsPageState extends State<AdminItemsPage> {
  static const _filters = ['All', 'Pending', 'Changes requested'];
  // (ค่าที่ส่ง API, ข้อความที่แสดง) ตรงกับ products.reject_reason ใน DB
  static const _rejectReasons = <(String, String)>[
    ('prohibited_item', 'Prohibited item'),
    ('misleading', 'Misleading information'),
    ('poor_photos', 'Poor quality photos'),
    ('duplicate', 'Duplicate item'),
    ('other', 'Other'),
  ];

  // Mock data (UI only)
  // TODO: ดึงจาก API (สินค้าที่รอตรวจสอบ) และอัปเดตสถานะสินค้าเมื่อแอดมินตัดสิน
  final List<_Item> _items = [
    _Item(
      'Mini fridge',
      'Sam K.',
      60,
      'Appliances',
      'North Campus · Oak Hall',
      '10 min ago',
      'Works great, small dent on the side. Pickup only.',
      photos: const [null, null, null],
    ),
    _Item(
      'Calculus textbook',
      'Priya N.',
      20,
      'Books',
      'North Campus · Maple Hall',
      '1 hour ago',
      'Latest edition, a few highlighted pages.',
      urgent: true,
    ),
    _Item(
      'iPad Air (2021)',
      'Lee W.',
      320,
      'Tech',
      'South Campus · Cedar Hall',
      '3 hours ago',
      '64GB, includes case. Battery health 91%.',
      flag: 'Price is higher than most items in this category',
      photos: const [null, null, null, null],
    ),
    _Item(
      'Bean bag chair',
      'Mika T.',
      15,
      'Furniture',
      'North Campus · Oak Hall',
      'Yesterday',
      'Comfy, lightly used.',
      status: _LStatus.changes,
    ),
  ];

  String _query = '';
  String _filter = 'All';

  String _label(_LStatus s) =>
      s == _LStatus.pending ? 'Pending' : 'Changes requested';

  (Color, Color) _colors(_LStatus s) =>
      s == _LStatus.pending ? (_cAmberBg, _cAmberFg) : (_cBlueBg, _cBlueFg);

  List<_Item> get _visible {
    final q = _query.trim().toLowerCase();
    return _items.where((i) {
      final matchQ =
          q.isEmpty ||
          i.title.toLowerCase().contains(q) ||
          i.seller.toLowerCase().contains(q) ||
          i.category.toLowerCase().contains(q);
      final matchF = _filter == 'All' || _label(i.status) == _filter;
      return matchQ && matchF;
    }).toList();
  }

  Future<void> _openFilter() async {
    final r = await _pickFilter(context, _filter, _filters);
    if (r != null) setState(() => _filter = r);
  }

  void _openItem(_Item item) {
    final (bg, fg) = _colors(item.status);
    _showSheet(context, (ctx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBox(
                icon: Icons.fact_check_outlined,
                bg: _cAmberBg,
                fg: _cAmberFg,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _Badge(label: _label(item.status), bg: bg, fg: fg),
            ],
          ),
          const SizedBox(height: 16),
          _PhotoStrip(photos: item.photos),
          const SizedBox(height: 12),
          _InfoRow('Price', '${item.price} THB'),
          _InfoRow('Category', item.category),
          _InfoRow('Seller', item.seller),
          _InfoRow('Location', item.place),
          _InfoRow('Submitted', item.submitted),
          if (item.urgent) const _InfoRow('Urgent', 'Has a move-out deadline'),
          const SizedBox(height: 6),
          const Divider(height: 1, color: _cBorder),
          const SizedBox(height: 14),
          const Text(
            'Description',
            style: TextStyle(fontSize: 12, color: _cMuted),
          ),
          const SizedBox(height: 6),
          Text(
            item.description,
            style: const TextStyle(fontSize: 13, height: 1.45),
          ),
          if (item.flag != null) ...[
            const SizedBox(height: 14),
            _Notice(item.flag!, bg: _cAmberBg, fg: _cAmberFg),
          ],
          if (item.note != null) ...[
            const SizedBox(height: 14),
            _Notice('Sent to seller: ${item.note}', bg: _cBlueBg, fg: _cBlueFg),
          ],
          const SizedBox(height: 20),
          _ActionButton(
            label: 'Approve item',
            onPressed: () {
              // TODO: API -> products.status='available' (ขึ้นหน้าร้าน), reviewed_by=admin, reviewed_at=now
              //   (ผู้ขายเห็นสถานะใน My items ไม่มีระบบแจ้งเตือน)
              setState(() => _items.remove(item));
              Navigator.pop(ctx);
              _snack(context, '${item.title} approved and live (mock)');
            },
          ),
          const SizedBox(height: 10),
          _ActionButton(
            filled: false,
            label: 'Request changes',
            onPressed: () async {
              final note = await _showSheet<String>(
                ctx,
                (c) => _NoteForm(
                  title: 'Request changes',
                  hint: 'e.g. Please add clearer photos of the front.',
                  button: 'Send to seller',
                ),
              );
              if (note == null || !mounted) return;
              // TODO: API -> products.status='changes_requested', review_note=<ข้อความถึงผู้ขาย>, reviewed_by/at
              setState(() {
                item.status = _LStatus.changes;
                item.note = note;
              });
              if (ctx.mounted) Navigator.pop(ctx);
              _snack(context, 'Sent to ${item.seller} (mock)');
            },
          ),
          const SizedBox(height: 10),
          _ActionButton(
            filled: false,
            danger: true,
            label: 'Reject item',
            onPressed: () async {
              final reason = await _pickReason(ctx, _rejectReasons);
              if (reason == null || !mounted) return;
              // TODO: API -> products.status='rejected', reject_reason=reason.$1 (ถ้าเป็น 'other' ให้ใส่ review_note), reviewed_by/at
              setState(() => _items.remove(item));
              if (ctx.mounted) Navigator.pop(ctx);
              _snack(context, '${item.title} rejected: ${reason.$2} (mock)');
            },
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _visible;
    final n = _items.length;
    return Scaffold(
      backgroundColor: _cBg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'Items review',
              subtitle: n == 1
                  ? '1 item waiting for review'
                  : '$n items waiting for review',
            ),
            _SearchRow(
              hint: 'Search items or sellers',
              filterActive: _filter != 'All',
              onChanged: (v) => setState(() => _query = v),
              onFilter: _openFilter,
            ),
            _SectionRow(label: 'Needs attention', shown: list.length),
            Expanded(
              child: list.isEmpty
                  ? const _Empty('No items to review')
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        for (final i in list)
                          _ListRow(
                            icon: Icons.fact_check_outlined,
                            iconBg: _cAmberBg,
                            iconFg: _cAmberFg,
                            thumb: _Thumb(i.photos.first),
                            title: i.title,
                            subtitle:
                                '${i.price} THB · ${i.seller} · ${i.submitted}',
                            badge: _label(i.status),
                            badgeBg: _colors(i.status).$1,
                            badgeFg: _colors(i.status).$2,
                            onTap: () => _openItem(i),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteForm extends StatefulWidget {
  final String title;
  final String hint;
  final String button;
  const _NoteForm({
    required this.title,
    required this.hint,
    required this.button,
  });

  @override
  State<_NoteForm> createState() => _NoteFormState();
}

class _NoteFormState extends State<_NoteForm> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _ctrl,
          minLines: 3,
          maxLines: 5,
          maxLength: 300,
          textCapitalization: TextCapitalization.sentences,
          decoration: _dec(widget.hint, error: _error),
        ),
        const SizedBox(height: 14),
        _ActionButton(
          label: widget.button,
          onPressed: () {
            final text = _ctrl.text.trim();
            if (text.length < 5) {
              setState(() => _error = 'Please write a short message');
              return;
            }
            Navigator.pop(context, text);
          },
        ),
      ],
    );
  }
}

// ---- small shared widgets (local to this file) ----
void _snack(BuildContext context, String msg) {
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

Future<T?> _showSheet<T>(
  BuildContext context,
  Widget Function(BuildContext) builder,
) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _cBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(ctx).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(child: builder(ctx)),
    ),
  );
}

Future<(String, String)?> _pickReason(
  BuildContext context,
  List<(String, String)> reasons,
) {
  return showModalBottomSheet<(String, String)>(
    context: context,
    backgroundColor: _cBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Why are you rejecting this?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          for (final r in reasons)
            ListTile(title: Text(r.$2), onTap: () => Navigator.pop(ctx, r)),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Future<String?> _pickFilter(
  BuildContext context,
  String current,
  List<String> options,
) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: _cBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final o in options)
                  ChoiceChip(
                    label: Text(o),
                    selected: o == current,
                    showCheckmark: false,
                    selectedColor: _cInk,
                    backgroundColor: _cCard,
                    side: const BorderSide(color: _cBorder),
                    labelStyle: TextStyle(
                      color: o == current ? Colors.white : _cInk,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => Navigator.pop(ctx, o),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

InputDecoration _dec(String hint, {String? error}) {
  OutlineInputBorder b(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c),
  );
  return InputDecoration(
    hintText: hint,
    errorText: error,
    hintStyle: const TextStyle(color: Color(0xFFB0AFA8), fontSize: 14),
    filled: true,
    fillColor: _cCard,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: b(_cBorder),
    enabledBorder: b(_cBorder),
    focusedBorder: b(_cInk),
    errorBorder: b(_cRedFg),
    focusedErrorBorder: b(_cRedFg),
  );
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _cInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: _cMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  final String hint;
  final bool filterActive;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;
  const _SearchRow({
    required this.hint,
    required this.filterActive,
    required this.onChanged,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder b(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFFB0AFA8),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search, size: 20, color: _cInk),
                filled: true,
                fillColor: _cCard,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                border: b(_cBorder),
                enabledBorder: b(_cBorder),
                focusedBorder: b(_cInk),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: _cCard,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onFilter,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: filterActive ? _cInk : _cBorder),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.tune, size: 20),
                    if (filterActive)
                      const Positioned(
                        top: 12,
                        right: 12,
                        child: CircleAvatar(
                          radius: 4,
                          backgroundColor: _cRedFg,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  final String label;
  final int shown;
  const _SectionRow({required this.label, required this.shown});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(
            '$shown shown',
            style: const TextStyle(fontSize: 11, color: _cMuted),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Badge({required this.label, required this.bg, required this.fg});

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

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;
  const _IconBox({
    required this.icon,
    required this.bg,
    required this.fg,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, size: size * 0.42, color: fg),
  );
}

class _ListRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeBg;
  final Color badgeFg;
  final VoidCallback onTap;
  final Widget? thumb; // ถ้ามี จะแสดงแทนกล่องไอคอน (เช่น รูปสินค้า)
  const _ListRow({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeBg,
    required this.badgeFg,
    required this.onTap,
    this.thumb,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _cBorder)),
        ),
        child: Row(
          children: [
            thumb ?? _IconBox(icon: icon, bg: iconBg, fg: iconFg),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: _cMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _Badge(label: badge, bg: badgeBg, fg: badgeFg),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final bool danger;
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? _cRedFg : _cInk;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final text = Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    );
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: filled
          ? FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: color,
                shape: shape,
              ),
              onPressed: onPressed,
              child: text,
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: danger ? _cRedFg : _cBorder),
                shape: shape,
              ),
              onPressed: onPressed,
              child: text,
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: _cMuted)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _Notice extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _Notice(this.text, {required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(text, style: TextStyle(fontSize: 12, height: 1.4, color: fg)),
  );
}

// ---- แสดงรูปสินค้า ----
Widget _photoWidget(String? url, {BoxFit fit = BoxFit.cover}) {
  final placeholder = Container(
    color: _cChip,
    alignment: Alignment.center,
    child: const Icon(Icons.image_outlined, size: 30, color: _cMuted),
  );
  if (url == null) return placeholder;
  return Image.network(
    url,
    fit: fit,
    errorBuilder: (_, __, ___) => placeholder,
    loadingBuilder: (_, child, progress) =>
        progress == null ? child : placeholder,
  );
}

/// รูปย่อในรายการ
class _Thumb extends StatelessWidget {
  final String? url;
  const _Thumb(this.url);

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: SizedBox(width: 48, height: 48, child: _photoWidget(url)),
  );
}

/// แถบรูปทั้งหมดในหน้ารายละเอียด เลื่อนดูได้ กดเพื่อขยายเต็มจอ
class _PhotoStrip extends StatelessWidget {
  final List<String?> photos;
  const _PhotoStrip({required this.photos});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) => GestureDetector(
              onTap: () => showDialog(
                context: ctx,
                builder: (_) => _PhotoViewer(photos: photos, initial: i),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: _photoWidget(photos[i]),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${photos.length} ${photos.length == 1 ? 'photo' : 'photos'} · tap to enlarge',
          style: const TextStyle(fontSize: 11, color: _cMuted),
        ),
      ],
    );
  }
}

/// ดูรูปเต็มจอ ปัดซ้ายขวาได้ บีบนิ้วซูมได้
class _PhotoViewer extends StatefulWidget {
  final List<String?> photos;
  final int initial;
  const _PhotoViewer({required this.photos, required this.initial});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _ctrl = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => InteractiveViewer(
              child: Center(
                child: _photoWidget(widget.photos[i], fit: BoxFit.contain),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '${_index + 1} / ${widget.photos.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);

  @override
  Widget build(BuildContext context) => Center(
    child: Text(text, style: const TextStyle(color: _cMuted)),
  );
}
