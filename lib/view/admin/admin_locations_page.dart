import 'package:flutter/material.dart';

// ---- colors (local to this file) ----
const _cBg = Color(0xFFFAF9F6);
const _cCard = Color(0xFFFFFFFF);
const _cInk = Color(0xFF2B2B26);
const _cMuted = Color(0xFF8A8A82);
const _cBorder = Color(0xFFE6E4DE);
const _cBlueBg = Color(0xFFE3ECF7);
const _cBlueFg = Color(0xFF3B5E8C);
const _cAmberBg = Color(0xFFFBEBC2);
const _cAmberFg = Color(0xFF8A6410);
const _cRedFg = Color(0xFFB3402F);

enum _LStatus { pending, reviewing }

class _Loc {
  final String name;
  final String area;
  final String meta;
  _LStatus status;
  _Loc(this.name, this.area, this.meta, this.status);
}

class AdminLocationsPage extends StatefulWidget {
  const AdminLocationsPage({super.key});

  @override
  State<AdminLocationsPage> createState() => _AdminLocationsPageState();
}

class _AdminLocationsPageState extends State<AdminLocationsPage> {
  static const _filters = ['All', 'Pending', 'Reviewing'];
  static const _areas = [
    'North Campus',
    'South Campus',
    'East Campus',
    'West Campus',
    'Off-campus dorm',
    'Condo',
  ];

  // Mock data (UI only)
  final List<_Loc> _locs = [
    _Loc(
      'Riverside Residence',
      'North Campus',
      'Requested by Maya K.',
      _LStatus.pending,
    ),
    _Loc(
      'The Grove Condos',
      'East Campus',
      'Requested by Arun P.',
      _LStatus.pending,
    ),
    _Loc(
      'Cedar Student Living',
      'South Campus',
      'Requested by Lina W.',
      _LStatus.pending,
    ),
    _Loc(
      'Hilltop Apartments',
      'West Campus',
      'Requested yesterday',
      _LStatus.reviewing,
    ),
  ];

  String _query = '';
  String _filter = 'All';

  String _label(_LStatus s) => s == _LStatus.pending ? 'Pending' : 'Reviewing';

  (Color, Color) _colors(_LStatus s) =>
      s == _LStatus.pending ? (_cAmberBg, _cAmberFg) : (_cBlueBg, _cBlueFg);

  List<_Loc> get _visible {
    final q = _query.trim().toLowerCase();
    return _locs.where((l) {
      final matchQ =
          q.isEmpty ||
          l.name.toLowerCase().contains(q) ||
          l.area.toLowerCase().contains(q);
      final matchF = _filter == 'All' || _label(l.status) == _filter;
      return matchQ && matchF;
    }).toList();
  }

  Future<void> _openFilter() async {
    final r = await _pickFilter(context, _filter, _filters);
    if (r != null) setState(() => _filter = r);
  }

  void _openLoc(_Loc l) {
    final (bg, fg) = _colors(l.status);
    _showSheet(context, (ctx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBox(
                icon: Icons.location_on_outlined,
                bg: _cBlueBg,
                fg: _cBlueFg,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  l.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _Badge(label: _label(l.status), bg: bg, fg: fg),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow('Zone', l.area),
          _InfoRow('Request', l.meta),
          const Divider(height: 1, color: _cBorder),
          const SizedBox(height: 20),
          _ActionButton(
            label: 'Approve location',
            onPressed: () {
              setState(() => _locs.remove(l));
              Navigator.pop(ctx);
              _snack(context, '${l.name} approved (mock)');
            },
          ),
          const SizedBox(height: 10),
          if (l.status == _LStatus.pending) ...[
            _ActionButton(
              filled: false,
              label: 'Mark as reviewing',
              onPressed: () {
                setState(() => l.status = _LStatus.reviewing);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 10),
          ],
          _ActionButton(
            filled: false,
            danger: true,
            label: 'Reject request',
            onPressed: () {
              setState(() => _locs.remove(l));
              Navigator.pop(ctx);
              _snack(context, '${l.name} rejected (mock)');
            },
          ),
        ],
      );
    });
  }

  void _addLocation() {
    _showSheet(context, (ctx) {
      return _LocationForm(
        areas: _areas,
        onSave: (name, area) {
          setState(
            () => _locs.insert(
              0,
              _Loc(name, area, 'Requested just now', _LStatus.pending),
            ),
          );
          _snack(context, 'Location added (mock)');
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _visible;
    final n = _locs.length;
    return Scaffold(
      backgroundColor: _cBg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'Location requests',
              subtitle: n == 1
                  ? '1 request needs review'
                  : '$n requests need review',
            ),
            _SearchRow(
              hint: 'Search locations',
              filterActive: _filter != 'All',
              onChanged: (v) => setState(() => _query = v),
              onFilter: _openFilter,
            ),
            _SectionRow(label: 'Needs attention', shown: list.length),
            Expanded(
              child: list.isEmpty
                  ? const _Empty('No requests found')
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        for (final l in list)
                          _ListRow(
                            icon: Icons.location_on_outlined,
                            iconBg: _cBlueBg,
                            iconFg: _cBlueFg,
                            title: l.name,
                            subtitle: '${l.area} · ${l.meta}',
                            badge: _label(l.status),
                            badgeBg: _colors(l.status).$1,
                            badgeFg: _colors(l.status).$2,
                            onTap: () => _openLoc(l),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomBar(
        label: 'Add location',
        onPressed: _addLocation,
      ),
    );
  }
}

class _LocationForm extends StatefulWidget {
  final List<String> areas;
  final void Function(String name, String area) onSave;
  const _LocationForm({required this.areas, required this.onSave});

  @override
  State<_LocationForm> createState() => _LocationFormState();
}

class _LocationFormState extends State<_LocationForm> {
  final _name = TextEditingController();
  late String _area = widget.areas.first;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add location',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        const Text(
          'Name',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: _dec('e.g. Riverside Residence', error: _error),
        ),
        const SizedBox(height: 16),
        const Text(
          'Zone',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _area,
          decoration: _dec(''),
          items: [
            for (final a in widget.areas)
              DropdownMenuItem(value: a, child: Text(a)),
          ],
          onChanged: (v) => setState(() => _area = v ?? _area),
        ),
        const SizedBox(height: 22),
        _ActionButton(
          label: 'Add location',
          onPressed: () {
            if (_name.text.trim().isEmpty) {
              setState(() => _error = 'Please enter a name');
              return;
            }
            widget.onSave(_name.text.trim(), _area);
            Navigator.pop(context);
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
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () => _snack(context, 'More options (coming soon)'),
          ),
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
          border: Border(bottom: BorderSide(color: _cBorder)),
        ),
        child: Row(
          children: [
            _IconBox(icon: icon, bg: iconBg, fg: iconFg),
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
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onPressed,
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
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
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: _cMuted)),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);

  @override
  Widget build(BuildContext context) => Center(
    child: Text(text, style: const TextStyle(color: _cMuted)),
  );
}
