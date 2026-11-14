import 'package:flutter/material.dart';
import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/model/enums.dart';
import 'package:uni_swap/model/format.dart';
import 'package:uni_swap/model/json_utils.dart';
import 'package:uni_swap/model/location.dart';
import 'package:uni_swap/view/user/location_picker.dart';

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

class AdminLocationsPage extends StatefulWidget {
  const AdminLocationsPage({super.key});

  @override
  State<AdminLocationsPage> createState() => _AdminLocationsPageState();
}

class _AdminLocationsPageState extends State<AdminLocationsPage> {
  static const _filters = ['All', 'Pending', 'Reviewing'];

  // คำขอที่ยังเปิดอยู่ (pending + reviewing) จาก GET /admin/location-requests
  List<LocationRequest> _requests = [];
  // คำขอที่กำลังยิง API อยู่ (disable แถวนั้นไว้)
  final Set<int> _busyIds = {};
  bool _loading = true;
  String? _error;

  String _query = '';
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ---- data ----

  Future<List<LocationRequest>> _fetchByStatus(String status) async {
    final response = await adminController.locationRequests(
      status: status,
      limit: 100,
    );
    if (response['success'] != true || response['data'] is! List) {
      throw const ApiException('The server returned invalid location requests.');
    }
    return jsonParseList(response['data'], LocationRequest.fromJson);
  }

  /// [silent] = ไม่โชว์ spinner เต็มหน้า (ใช้ตอน pull-to-refresh / โหลดซ้ำหลัง action)
  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        _fetchByStatus('pending'),
        _fetchByStatus('reviewing'),
      ]);
      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      // เก่าสุดขึ้นก่อน (รอนานสุด = ควรดูก่อน)
      final open =
          [...results[0], ...results[1]]
              .where((request) => request.isOpen && request.id > 0)
              .toList()
            ..sort(
              (a, b) =>
                  (a.createdAt ?? epoch).compareTo(b.createdAt ?? epoch),
            );
      if (mounted) {
        setState(() {
          _requests = open;
          _error = null;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not load location requests.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review(
    LocationRequest request, {
    required String action,
    int? mergeIntoLocationId,
    required String doneMessage,
  }) async {
    if (_busyIds.contains(request.id)) return;
    setState(() => _busyIds.add(request.id));
    try {
      final response = await adminController.reviewLocationRequest(
        request.id,
        action: action,
        mergeIntoLocationId: mergeIntoLocationId,
      );
      if (response['success'] == false) {
        throw ApiException(
          response['message']?.toString() ?? 'Could not update the request.',
        );
      }
      if (!mounted) return;
      _snack(context, doneMessage);
      await _load(silent: true);
    } on ApiException catch (error) {
      if (!mounted) return;
      _snack(context, error.message, isError: true);
      // 409 "Location request is not open": มีคนจัดการไปแล้ว ให้โหลดรายการใหม่
      if (error.statusCode == 409) await _load(silent: true);
    } catch (_) {
      if (mounted) {
        _snack(context, 'Could not update the request.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busyIds.remove(request.id));
    }
  }

  // ---- derived ----

  String _statusLabel(LocationRequestStatus s) =>
      s == LocationRequestStatus.reviewing ? 'Reviewing' : 'Pending';

  (Color, Color) _colors(LocationRequestStatus s) =>
      s == LocationRequestStatus.reviewing
      ? (_cBlueBg, _cBlueFg)
      : (_cAmberBg, _cAmberFg);

  String _requesterLabel(LocationRequest r) {
    final name = (r.requesterName ?? '').trim();
    if (name.isNotEmpty) return name;
    final username = (r.requesterUsername ?? '').trim();
    if (username.isNotEmpty) return username;
    return 'a member';
  }

  String _subtitle(LocationRequest r) {
    final ago = timeAgo(r.createdAt);
    return [
      locationZoneLabel(r.zone),
      'Requested by ${_requesterLabel(r)}',
      if (ago.isNotEmpty) ago,
    ].join(' · ');
  }

  List<LocationRequest> get _visible {
    final q = _query.trim().toLowerCase();
    return _requests.where((r) {
      final matchQ =
          q.isEmpty ||
          r.name.toLowerCase().contains(q) ||
          locationZoneLabel(r.zone).toLowerCase().contains(q) ||
          _requesterLabel(r).toLowerCase().contains(q);
      final matchF = _filter == 'All' || _statusLabel(r.status) == _filter;
      return matchQ && matchF;
    }).toList();
  }

  // ---- actions ----

  Future<void> _openFilter() async {
    final r = await _pickFilter(context, _filter, _filters);
    if (r != null && mounted) setState(() => _filter = r);
  }

  void _openRequest(LocationRequest r) {
    if (_busyIds.contains(r.id)) return;
    final (bg, fg) = _colors(r.status);
    final address = (r.address ?? '').trim();
    final reason = (r.reason ?? '').trim();
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
                  r.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _Badge(label: _statusLabel(r.status), bg: bg, fg: fg),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow('Zone', locationZoneLabel(r.zone)),
          _InfoRow('Requested by', _requesterLabel(r)),
          if (r.createdAt != null)
            _InfoRow('Requested', timeAgo(r.createdAt)),
          if (address.isNotEmpty) _InfoRow('Address', address),
          if (reason.isNotEmpty) _InfoRow('Reason', reason),
          const Divider(height: 1, color: _cBorder),
          const SizedBox(height: 20),
          _ActionButton(
            label: 'Approve location',
            onPressed: () {
              Navigator.pop(ctx);
              _review(
                r,
                action: 'approve',
                doneMessage: '${r.name} approved',
              );
            },
          ),
          const SizedBox(height: 10),
          // ใช้กรณีผู้ใช้พิมพ์ชื่อไม่ตรงกับที่พักที่มีอยู่ (สะกดผิด/ชื่อเรียกต่างกัน)
          _ActionButton(
            filled: false,
            label: 'Merge into existing location',
            onPressed: () async {
              final target = await _pickExisting(ctx, r.zone);
              if (target == null || !mounted) return;
              if (ctx.mounted) Navigator.pop(ctx);
              _review(
                r,
                action: 'merge',
                mergeIntoLocationId: target.id,
                doneMessage: '${r.name} merged into ${target.name}',
              );
            },
          ),
          const SizedBox(height: 10),
          if (r.status == LocationRequestStatus.pending) ...[
            _ActionButton(
              filled: false,
              label: 'Mark as reviewing',
              onPressed: () {
                Navigator.pop(ctx);
                _review(
                  r,
                  action: 'reviewing',
                  doneMessage: '${r.name} marked as reviewing',
                );
              },
            ),
            const SizedBox(height: 10),
          ],
          _ActionButton(
            filled: false,
            danger: true,
            label: 'Reject request',
            onPressed: () {
              Navigator.pop(ctx);
              _review(
                r,
                action: 'reject',
                doneMessage: '${r.name} rejected',
              );
            },
          ),
        ],
      );
    });
  }

  /// เลือกที่พักปลายทางของการ Merge (เฉพาะ zone เดียวกับคำขอ และ is_active)
  Future<Location?> _pickExisting(BuildContext context, ResidenceZone zone) {
    return showModalBottomSheet<Location>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _MergeTargetSheet(zone: zone),
    );
  }

  Future<void> _addLocation() async {
    final added = await _showSheet<bool>(context, (ctx) {
      return _LocationForm(
        onSave: (name, zone) async {
          try {
            final response = await adminController.createLocation(
              name: name,
              zone: zone.apiValue,
            );
            if (response['success'] == false) {
              return response['message']?.toString() ??
                  'Could not add the location.';
            }
            return null;
          } on ApiException catch (error) {
            return error.message;
          } catch (_) {
            return 'Could not add the location.';
          }
        },
      );
    });
    if (added != true || !mounted) return;
    _snack(context, 'Location added');
    await _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final list = _visible;
    final n = _requests.length;
    final hasData = _requests.isNotEmpty;
    return Scaffold(
      backgroundColor: _cBg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'Location requests',
              subtitle: _loading && !hasData
                  ? 'Loading…'
                  : n == 1
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
            if (_error != null && hasData)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: _cRedFg, fontSize: 12),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _load(silent: true),
                child: _buildBody(list, hasData),
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

  Widget _buildBody(List<LocationRequest> list, bool hasData) {
    if (_loading && !hasData) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }
    if (_error != null && !hasData) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _load,
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }
    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(48),
        children: [
          _Empty(hasData ? 'No requests found' : 'No pending requests'),
        ],
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final r in list)
          _ListRow(
            icon: Icons.location_on_outlined,
            iconBg: _cBlueBg,
            iconFg: _cBlueFg,
            title: r.name,
            subtitle: _subtitle(r),
            badge: _statusLabel(r.status),
            badgeBg: _colors(r.status).$1,
            badgeFg: _colors(r.status).$2,
            busy: _busyIds.contains(r.id),
            onTap: () => _openRequest(r),
          ),
      ],
    );
  }
}

/// bottom sheet เลือกที่พักปลายทางของ Merge: โหลดจาก adminController.locations()
class _MergeTargetSheet extends StatefulWidget {
  final ResidenceZone zone;
  const _MergeTargetSheet({required this.zone});

  @override
  State<_MergeTargetSheet> createState() => _MergeTargetSheetState();
}

class _MergeTargetSheetState extends State<_MergeTargetSheet> {
  List<Location> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await adminController.locations(
        zone: widget.zone.apiValue,
      );
      if (response['success'] != true || response['data'] is! List) {
        throw const ApiException('The server returned invalid locations.');
      }
      // กรองซ้ำฝั่งแอป: zone เดียวกับคำขอ + is_active เท่านั้น
      final items =
          jsonParseList(response['data'], Location.fromJson)
              .where(
                (l) => l.id > 0 && l.isActive && l.zone == widget.zone,
              )
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
      if (mounted) setState(() => _items = items);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load locations.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.55;
    Widget body;
    if (_loading) {
      body = const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_error != null) {
      body = Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          children: [
            Text(_error!, textAlign: TextAlign.center),
            TextButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    } else if (_items.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No active locations in this zone',
            style: TextStyle(color: _cMuted),
          ),
        ),
      );
    } else {
      body = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final l in _items)
              ListTile(
                title: Text(l.name),
                onTap: () => Navigator.pop(context, l),
              ),
          ],
        ),
      );
    }
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text(
              'Merge into which location?',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              locationZoneLabel(widget.zone),
              style: const TextStyle(fontSize: 12, color: _cMuted),
            ),
          ),
          body,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LocationForm extends StatefulWidget {
  /// คืนข้อความ error ถ้าบันทึกไม่สำเร็จ หรือ null เมื่อสำเร็จ
  final Future<String?> Function(String name, ResidenceZone zone) onSave;
  const _LocationForm({required this.onSave});

  @override
  State<_LocationForm> createState() => _LocationFormState();
}

class _LocationFormState extends State<_LocationForm> {
  final _name = TextEditingController();
  ResidenceZone _zone = ResidenceZone.onCampus;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a name');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(name, _zone);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
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
          enabled: !_saving,
          maxLength: 150,
          textCapitalization: TextCapitalization.words,
          decoration: _dec('e.g. Riverside Residence', error: _error),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Zone',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ResidenceZone>(
          value: _zone,
          decoration: _dec(''),
          items: [
            for (final z in ResidenceZone.values)
              DropdownMenuItem(value: z, child: Text(locationZoneLabel(z))),
          ],
          onChanged: _saving
              ? null
              : (v) => setState(() => _zone = v ?? _zone),
        ),
        const SizedBox(height: 22),
        _ActionButton(
          label: _saving ? 'Adding…' : 'Add location',
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}

// ---- small shared widgets (local to this file) ----
void _snack(BuildContext context, String msg, {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? _cRedFg : _cInk,
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
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 0),
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
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _cInk,
                  ),
                ),
                const SizedBox(height: 6),
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
  final bool busy;
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
    this.busy = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: busy ? null : onTap,
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
            busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(2),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.chevron_right, size: 20),
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
  final VoidCallback? onPressed;
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

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);

  @override
  Widget build(BuildContext context) => Center(
    child: Text(text, style: const TextStyle(color: _cMuted)),
  );
}
