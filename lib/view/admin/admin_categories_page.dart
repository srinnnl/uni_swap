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
const _cAmberBg = Color(0xFFFBEBC2);
const _cAmberFg = Color(0xFF8A6410);
const _cRedFg = Color(0xFFB3402F);

class _Cat {
  String name;
  String emoji;
  final int count;
  bool active;
  _Cat(this.name, this.emoji, this.count, this.active);
}

class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({super.key});

  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage> {
  static const _filters = ['All', 'Active', 'Inactive'];

  // Mock data (UI only)
  final List<_Cat> _cats = [
    _Cat('Furniture', '🪑', 184, true),
    _Cat('Books', '📚', 142, true),
    _Cat('Technology', '📘', 119, true),
    _Cat('Transport', '🚲', 76, true),
    _Cat('Home & kitchen', '🏠', 63, true),
    _Cat('Clothing', '👕', 58, true),
    _Cat('Appliances', '🔌', 49, true),
    _Cat('Sports', '⚽', 41, true),
    _Cat('Music', '🎸', 37, true),
    _Cat('Stationery', '✏️', 33, true),
    _Cat('Other', '📦', 28, true),
    _Cat('Toys', '🧸', 0, false),
  ];

  String _query = '';
  String _filter = 'All';

  List<_Cat> get _visible {
    final q = _query.trim().toLowerCase();
    return _cats.where((c) {
      final matchQ = q.isEmpty || c.name.toLowerCase().contains(q);
      final matchF = _filter == 'All' ||
          (_filter == 'Active' && c.active) ||
          (_filter == 'Inactive' && !c.active);
      return matchQ && matchF;
    }).toList();
  }

  Future<void> _openFilter() async {
    final r = await _pickFilter(context, _filter, _filters);
    if (r != null) setState(() => _filter = r);
  }

  void _openForm([_Cat? cat]) {
    _showSheet(context, (ctx) {
      return _CategoryForm(
        cat: cat,
        onSave: (name, emoji, active) {
          setState(() {
            if (cat == null) {
              _cats.insert(0, _Cat(name, emoji, 0, active));
            } else {
              cat.name = name;
              cat.emoji = emoji;
              cat.active = active;
            }
          });
          _snack(context, cat == null ? 'Category added (mock)' : 'Category saved (mock)');
        },
        onDelete: cat == null
            ? null
            : () async {
                final ok = await _confirm(ctx,
                    title: 'Delete category?',
                    message: '"${cat.name}" will be removed.',
                    confirmLabel: 'Delete');
                if (!ok || !mounted) return;
                setState(() => _cats.remove(cat));
                if (ctx.mounted) Navigator.pop(ctx);
                _snack(context, 'Category deleted (mock)');
              },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _visible;
    return Scaffold(
      backgroundColor: _cBg,
      body: SafeArea(
        child: Column(children: [
          _Header(
              title: 'Categories',
              subtitle: '${_cats.length} marketplace categories'),
          _SearchRow(
            hint: 'Search categories',
            filterActive: _filter != 'All',
            onChanged: (v) => setState(() => _query = v),
            onFilter: _openFilter,
          ),
          _SectionRow(label: 'All records', shown: list.length),
          Expanded(
            child: list.isEmpty
                ? const _Empty('No categories found')
                : ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      for (final c in list)
                        _ListRow(
                          icon: Icons.sell_outlined,
                          iconBg: _cAmberBg,
                          iconFg: _cAmberFg,
                          title: c.name,
                          subtitle: '${c.emoji} ${c.count} active products',
                          badge: c.active ? 'Active' : 'Inactive',
                          badgeBg: c.active ? _cSage : _cChip,
                          badgeFg: c.active ? _cSageDark : _cMuted,
                          onTap: () => _openForm(c),
                        ),
                    ],
                  ),
          ),
        ]),
      ),
      bottomNavigationBar:
          _BottomBar(label: 'Add category', onPressed: () => _openForm()),
    );
  }
}

class _CategoryForm extends StatefulWidget {
  final _Cat? cat;
  final void Function(String name, String emoji, bool active) onSave;
  final VoidCallback? onDelete;
  const _CategoryForm({required this.cat, required this.onSave, this.onDelete});

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  late final _name = TextEditingController(text: widget.cat?.name ?? '');
  late final _emoji = TextEditingController(text: widget.cat?.emoji ?? '🏷️');
  late bool _active = widget.cat?.active ?? true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _emoji.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.cat != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(editing ? 'Edit category' : 'Add category',
            style:
                const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
        const Text('Name',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          decoration: _dec('e.g. Furniture', error: _error),
        ),
        const SizedBox(height: 16),
        const Text('Emoji',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _emoji,
          maxLength: 4,
          decoration: _dec('🏷️'),
        ),
        const SizedBox(height: 8),
        Row(children: [
          const Expanded(
            child: Text('Active',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Switch(
            value: _active,
            onChanged: (v) => setState(() => _active = v),
            activeColor: Colors.white,
            activeTrackColor: _cSageDark,
          ),
        ]),
        const SizedBox(height: 14),
        _ActionButton(
          label: editing ? 'Save changes' : 'Add category',
          onPressed: () {
            if (_name.text.trim().isEmpty) {
              setState(() => _error = 'Please enter a name');
              return;
            }
            widget.onSave(_name.text.trim(),
                _emoji.text.trim().isEmpty ? '🏷️' : _emoji.text.trim(), _active);
            Navigator.pop(context);
          },
        ),
        if (widget.onDelete != null) ...[
          const SizedBox(height: 10),
          _ActionButton(
              filled: false,
              danger: true,
              label: 'Delete category',
              onPressed: widget.onDelete!),
        ],
      ],
    );
  }
}

// ---- small shared widgets (local to this file) ----
void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _cInk,
    ));
}

Future<T?> _showSheet<T>(
    BuildContext context, Widget Function(BuildContext) builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _cBg,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: SingleChildScrollView(child: builder(ctx)),
    ),
  );
}

Future<bool> _confirm(BuildContext context,
    {required String title,
    required String message,
    required String confirmLabel}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: _cBg,
      surfaceTintColor: Colors.transparent,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _cRedFg),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

Future<String?> _pickFilter(
    BuildContext context, String current, List<String> options) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: _cBg,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
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
                      fontWeight: FontWeight.w600),
                  onSelected: (_) => Navigator.pop(ctx, o),
                ),
            ]),
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
    counterText: '',
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
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: Column(children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, color: _cInk)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _cMuted)),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: () => _snack(context, 'More options (coming soon)'),
        ),
      ]),
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
      child: Row(children: [
        Expanded(
          child: TextField(
            onChanged: onChanged,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  const TextStyle(color: Color(0xFFB0AFA8), fontSize: 13),
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
              child: Stack(alignment: Alignment.center, children: [
                const Icon(Icons.tune, size: 20),
                if (filterActive)
                  const Positioned(
                    top: 12,
                    right: 12,
                    child: CircleAvatar(radius: 4, backgroundColor: _cRedFg),
                  ),
              ]),
            ),
          ),
        ),
      ]),
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
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Text('$shown shown',
            style: const TextStyle(fontSize: 11, color: _cMuted)),
      ]),
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
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
      );
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;
  const _IconBox(
      {required this.icon, required this.bg, required this.fg, this.size = 48});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
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
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _cBorder))),
        child: Row(children: [
          _IconBox(icon: icon, bg: iconBg, fg: iconFg),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(fontSize: 11, color: _cMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _Badge(label: badge, bg: badgeBg, fg: badgeFg),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, size: 20),
        ]),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _BottomBar({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _cBg,
        border: Border(top: BorderSide(color: _cBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _cInk,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onPressed,
              icon: const Icon(Icons.add, size: 20),
              label: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
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
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    final text = Text(label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14));
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: filled
          ? FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: color, shape: shape),
              onPressed: onPressed,
              child: text)
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: danger ? _cRedFg : _cBorder),
                  shape: shape),
              onPressed: onPressed,
              child: text),
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
