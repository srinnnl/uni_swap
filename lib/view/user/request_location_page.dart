import 'package:flutter/material.dart';
import 'package:uni_swap/view/user/campus_locations.dart';

const _cBg = Color(0xFFFAF9F6);
const _cInk = Color(0xFF2B2B26);
const _cMuted = Color(0xFF8A8A82);
const _cBorder = Color(0xFFE6E4DE);
const _cRedFg = Color(0xFFB3402F);

// หน้าขอเพิ่มที่พัก (หอ / คอนโด) ที่ยังไม่มีในรายการ
// กด Submit แล้วจะ pop กลับพร้อมค่า true (ตอนนี้ยังเป็นข้อมูลจำลอง)
//
// zone = หอใน/หอนอก (ตรงกับ location_requests.zone: on_campus / off_campus)
// สถานะเริ่มต้นของคำขอใน DB = pending (แอดมินเปลี่ยนเป็น reviewing / approved / merged / rejected)
class RequestLocationPage extends StatefulWidget {
  const RequestLocationPage({
    super.key,
    // TODO: ดึงที่พักปัจจุบันของผู้ใช้จาก API
    this.currentLocation = 'On-campus dorms · Lamduan 1 Dormitory',
  });

  final String currentLocation;

  @override
  State<RequestLocationPage> createState() => _RequestLocationPageState();
}

class _RequestLocationPageState extends State<RequestLocationPage> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  CampusZone? _zone;
  String? _nameError;
  String? _zoneError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  // เลือกจากรายการ (bottom sheet) แล้วคืนค่าที่เลือก
  Future<T?> _pick<T>({
    required String title,
    required List<(T, String)> options,
    required T? selected,
  }) {
    return showModalBottomSheet<T>(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _cInk,
                ),
              ),
            ),
            for (final o in options)
              ListTile(
                title: Text(o.$2),
                trailing: o.$1 == selected
                    ? const Icon(Icons.check, color: _cInk)
                    : null,
                onTap: () => Navigator.pop(ctx, o.$1),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickZone() async {
    final v = await _pick<CampusZone>(
      title: 'Where is it?',
      options: [for (final z in CampusZone.values) (z, z.label)],
      selected: _zone,
    );
    if (v != null) {
      setState(() {
        _zone = v;
        _zoneError = null;
      });
    }
  }

  // ===== จุดเชื่อมต่อ API: ให้เพื่อนแก้ฟังก์ชันนี้ =====
  void _submit() {
    final name = _nameCtrl.text.trim();
    setState(() {
      _nameError = name.length < 3 ? 'Please enter the location name' : null;
      _zoneError = _zone == null ? 'Please choose a zone' : null;
    });
    if (_nameError != null || _zoneError != null) return;

    // TODO: ส่งไป API (location_requests)
    //   name: name, zone: _zone!.code,
    //   address: _addressCtrl.text.trim(), reason: _reasonCtrl.text.trim()
    //   status เริ่มต้น = pending
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text("Request sent. Your place shows as pending until an admin reviews it."),
        ),
      );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cBg,
      appBar: AppBar(
        backgroundColor: _cBg,
        elevation: 0,
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              'Request a location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _cInk,
              ),
            ),
            Text(
              "Can't find where you live?",
              style: TextStyle(fontSize: 12, color: _cMuted),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _cInk),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Location Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your current location',
                    style: TextStyle(fontSize: 12, color: _cMuted),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: _cInk,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.currentLocation,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildFieldGroup(
              'Location name',
              'e.g. Riverside Residence',
              controller: _nameCtrl,
              errorText: _nameError,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            _buildSelector(
              'On / off campus',
              _zone?.label ?? 'Choose a zone',
              onTap: _pickZone,
              placeholder: _zone == null,
              errorText: _zoneError,
            ),
            _buildFieldGroup(
              'Address (optional)',
              'Street address or nearby landmark',
              controller: _addressCtrl,
              maxLines: 3,
            ),
            _buildFieldGroup(
              'Why should we add it? (optional)',
              'Tell us how many students live here...',
              controller: _reasonCtrl,
              maxLines: 3,
            ),

            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 24),
              child: Text(
                'This helps our admin verify the location.',
                style: TextStyle(fontSize: 11, color: _cMuted),
              ),
            ),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _cInk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Submit request',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldGroup(
    String label,
    String hint, {
    required TextEditingController controller,
    int maxLines = 1,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _cInk,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            onChanged: onChanged,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _cMuted, fontSize: 13),
              errorText: errorText,
              filled: true,
              fillColor: Colors.white,
              border: border(_cBorder),
              enabledBorder: border(_cBorder),
              focusedBorder: border(_cInk),
              errorBorder: border(_cRedFg),
              focusedErrorBorder: border(_cRedFg),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelector(
    String label,
    String value, {
    required VoidCallback onTap,
    bool placeholder = false,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _cInk,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: errorText == null ? _cBorder : _cRedFg,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        color: placeholder ? _cMuted : _cInk,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: _cMuted, size: 20),
                ],
              ),
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                errorText,
                style: const TextStyle(fontSize: 12, color: _cRedFg),
              ),
            ),
        ],
      ),
    );
  }
}
