import 'package:flutter/material.dart';

// ไฟล์นี้ใช้งานได้ด้วยตัวเอง: หน้านัดรับสินค้า (เปิดหลังกด Request to buy)
// กด Confirm แล้วจะ pop กลับพร้อมจุดนัดพบและเวลา (MeetupChoice)

typedef MeetupChoice = ({String spot, DateTime when});

class _C {
  static const bg = Color(0xFFFAF9F6);
  static const ink = Color(0xFF2F2F2B);
  static const muted = Color(0xFF7A7973);
  static const faint = Color(0xFFA9A8A2);
  static const border = Color(0xFFE6E4DD);
  static const surface = Color(0xFFF3F2EE);
  static const sage = Color(0xFF3F6B52);
}

class ArrangeMeetupPage extends StatefulWidget {
  const ArrangeMeetupPage({
    super.key,
    required this.productTitle,
    required this.price,
    required this.sellerName,
    required this.sellerLocation,
  });

  final String productTitle;
  final int price;
  final String sellerName;
  final String sellerLocation; // เช่น 'On-campus dorms · Lamduan 1 Dormitory'

  @override
  State<ArrangeMeetupPage> createState() => _ArrangeMeetupPageState();
}

class _ArrangeMeetupPageState extends State<ArrangeMeetupPage> {
  // TODO: ดึงจุดนัดพบที่เหมาะกับที่พักของผู้ขายจาก API
  List<String> get _spots => [
    '$_building lobby',
    'Main library',
    'Student union entrance',
  ];

  int _spot = 0;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 17, minute: 30);

  String get _building => widget.sellerLocation.split(' · ').last;

  String get _initials {
    final parts = widget.sellerName.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  String get _firstName => widget.sellerName.trim().split(RegExp(r'\s+')).first;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  // ===== จุดเชื่อมต่อ API: ให้เพื่อนแก้ฟังก์ชันนี้ =====
  void _confirm() {
    final when = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    if (when.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Please choose a time in the future')),
        );
      return;
    }

    // TODO: ส่งไป API -> spot: _spots[_spot], when: when
    // (ส่งพร้อมคำขอซื้อ แล้วผู้ขายตอบรับ/ปฏิเสธที่หน้า Orders)
    Navigator.pop<MeetupChoice>(context, (spot: _spots[_spot], when: when));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSellerLocation(),
            const SizedBox(height: 22),
            _buildSellerRow(),
            const SizedBox(height: 26),
            const _SectionLabel('Choose a meet-up spot'),
            _buildSpots(),
            const SizedBox(height: 26),
            const _SectionLabel('Date & time'),
            Row(
              children: [
                Expanded(
                  child: _PickerBox(
                    icon: Icons.calendar_today_outlined,
                    label: _formatDate(_date),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerBox(
                    icon: Icons.access_time,
                    label: _formatTime(_time),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _buildSafetyNote(),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: _C.ink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Confirm meet-up',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        Expanded(
          child: Column(
            children: [
              const Text(
                'Arrange meet-up',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _C.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.productTitle} · ${widget.price} THB',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: _C.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48), // ถ่วงให้หัวข้ออยู่กลางพอดี
      ],
    );
  }

  Widget _buildSellerLocation() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.location_on, color: Colors.red.shade400),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seller location',
                  style: TextStyle(fontSize: 11, color: _C.muted),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.sellerLocation,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerRow() {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFE9E1D9),
          child: Text(
            _initials,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF5B534B),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meet $_firstName',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _C.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _building,
                style: const TextStyle(fontSize: 12, color: _C.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpots() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < _spots.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _C.border),
            InkWell(
              onTap: () => setState(() => _spot = i),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 17,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 20,
                      color: _C.ink,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _spots[i],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _C.ink,
                        ),
                      ),
                    ),
                    _RadioDot(selected: i == _spot),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSafetyNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, size: 20, color: _C.sage),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meet safely',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _C.ink,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Choose a public spot. Check the item in person, then tap '
                  '"Confirm received" in the app so UniSwap can pay the seller.',
                  style: TextStyle(fontSize: 12, color: _C.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _C.ink,
      ),
    ),
  );
}

/// วงกลมเลือก (แทน Radio ของระบบ ซึ่งเปลี่ยน API บ่อยตามเวอร์ชัน Flutter)
class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    width: 22,
    height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: selected ? _C.ink : _C.border,
        width: selected ? 2 : 1.5,
      ),
    ),
    child: selected
        ? Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: _C.ink,
              shape: BoxShape.circle,
            ),
          )
        : null,
  );
}

class _PickerBox extends StatelessWidget {
  const _PickerBox({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _C.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          child: Row(
            children: [
              Icon(icon, size: 19, color: _C.ink),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _C.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime d) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
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
  return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
}

String _formatTime(TimeOfDay t) {
  final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
}
