import 'package:flutter/material.dart';
import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/model/enums.dart';
import 'package:uni_swap/view/user/location_picker.dart';
import 'package:flutter/services.dart';

const _cBg = Color(0xFFFAF9F6);
const _cInk = Color(0xFF2B2B26);
const _cMuted = Color(0xFF8A8A82);
const _cBorder = Color(0xFFE6E4DE);
const _cRedFg = Color(0xFFB3402F);

// หน้าขอเพิ่มที่พัก (หอ) ที่ยังไม่มีในรายการ
// กด Submit แล้วส่งคำขอไป POST /api/location-requests และ pop กลับพร้อมค่า true เมื่อสำเร็จ
//
// zone = หอใน/หอนอก (ตรงกับ location_requests.zone: on_campus / off_campus)
// สถานะเริ่มต้นของคำขอใน DB = pending (แอดมินเปลี่ยนเป็น reviewing / approved / merged / rejected)
class RequestLocationPage extends StatefulWidget {
  const RequestLocationPage({super.key, this.currentLocation});

  /// ที่พักปัจจุบันของผู้ใช้ (profile_page ส่งเข้ามา) null = ยังไม่ได้ตั้ง
  final String? currentLocation;

  @override
  State<RequestLocationPage> createState() => _RequestLocationPageState();
}

class _RequestLocationPageState extends State<RequestLocationPage> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  ResidenceZone? _zone;
  String? _nameError;
  String? _zoneError;
  bool _submitting = false;

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
                dense: true,
                visualDensity: const VisualDensity(vertical: -1),
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
    final v = await _pick<ResidenceZone>(
      title: 'Where is it?',
      options: [for (final z in ResidenceZone.values) (z, locationZoneLabel(z))],
      selected: _zone,
    );
    if (v != null && mounted) {
      setState(() {
        _zone = v;
        _zoneError = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final name = _nameCtrl.text.trim();
    setState(() {
      _nameError = name.length > 150
          ? 'Location name must be 150 characters or fewer'
          : name.length < 3
          ? 'Please enter the location name'
          : null;
      _zoneError = _zone == null ? 'Please choose a zone' : null;
    });
    if (_nameError != null || _zoneError != null) return;

    setState(() => _submitting = true);
    try {
      final response = await productController.requestLocation(
        name: name,
        zone: _zone!.apiValue,
        address: _addressCtrl.text.trim(),
        reason: _reasonCtrl.text.trim(),
      );
      if (response['success'] != true) {
        throw ApiException(
          response['message']?.toString() ?? 'Could not send your request.',
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              "Request sent. Your place shows as pending until an admin reviews it.",
            ),
          ),
        );
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Could not send your request. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: _cRedFg),
      );
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
                      Expanded(
                        child: Text(
                          widget.currentLocation ?? 'Not set yet',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
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
              maxLength: 150,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              errorText: _nameError,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            _buildSelector(
              'On / off campus',
              _zone == null ? 'Choose a zone' : locationZoneLabel(_zone!),
              onTap: _pickZone,
              placeholder: _zone == null,
              errorText: _zoneError,
            ),
            _buildFieldGroup(
              'Address (optional)',
              'Street address or nearby landmark',
              controller: _addressCtrl,
              maxLines: 3,
              maxLength: 255,
            ),
            _buildFieldGroup(
              'Why should we add it? (optional)',
              'Tell us how many students live here...',
              controller: _reasonCtrl,
              maxLines: 3,
              maxLength: 5000,
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
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _cInk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit request',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
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
    int? maxLength,
    MaxLengthEnforcement? maxLengthEnforcement,
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
            maxLength: maxLength,
            maxLengthEnforcement: maxLengthEnforcement,
            enabled: !_submitting,
            onChanged: onChanged,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _cMuted, fontSize: 13),
              errorText: errorText,
              counterText: '',
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
