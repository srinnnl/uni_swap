import 'package:flutter/material.dart';

const _cBg = Color(0xFFFAF9F6);
const _cInk = Color(0xFF2B2B26);
const _cMuted = Color(0xFF8A8A82);
const _cBorder = Color(0xFFE6E4DE);

class RequestLocationPage extends StatelessWidget {
  const RequestLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cBg,
      appBar: AppBar(
        backgroundColor: _cBg,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
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
                    children: const [
                      Icon(Icons.location_on_outlined, size: 18, color: _cInk),
                      SizedBox(width: 8),
                      Text(
                        'North Campus · Maple Hall',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildFieldGroup('Location name', 'e.g. Riverside Residence'),
            _buildSelector('Location type', 'Dorm / residence hall'),
            _buildSelector('Campus zone', 'North Campus'),
            _buildFieldGroup(
              'Address',
              'Street address or nearby landmark',
              maxLines: 3,
            ),
            _buildFieldGroup(
              'Why should we add it?',
              'Tell us how many students live here...',
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
                onPressed: () {}, // TODO: Submit action
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

  Widget _buildFieldGroup(String label, String hint, {int maxLines = 1}) {
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
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _cMuted, fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _cBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _cBorder),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelector(String label, String value) {
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _cBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(fontSize: 14, color: _cInk)),
                const Icon(Icons.chevron_right, color: _cMuted, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
