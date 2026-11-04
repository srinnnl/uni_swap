import 'package:flutter/material.dart';

const _cBg = Color(0xFFFAF9F6);
const _cInk = Color(0xFF2B2B26);
const _cMuted = Color(0xFF8A8A82);
const _cBorder = Color(0xFFE6E4DE);
const _cLink = Color(0xFF4A5C8F);

// เพิ่มสีสำหรับ Badge สถานะต่างๆ ให้ตรงกับหน้า Admin
const _cAmberBg = Color(0xFFFBEBC2);
const _cAmberFg = Color(0xFF8A6410);
const _cRedBg = Color(0xFFF8DADA);
const _cRedFg = Color(0xFFB3402F);
const _cSageBg = Color(0xFFD8E4DC);
const _cSageFg = Color(0xFF3F6B52);
const _cBlueBg = Color(0xFFE3ECF7);
const _cBlueFg = Color(0xFF3B5E8C);

// ตรงกับ products.status ใน DB:
//   pending = pending, actionRequired = changes_requested,
//   rejected = rejected, active / urgent = active (urgent = มี clearance_deadline)
enum ListingStatus { active, urgent, pending, actionRequired, rejected }

// ข้อมูลจำลอง (TODO: โหลดจาก API)
class _Listing {
  const _Listing({
    required this.status,
    required this.title,
    required this.subtitle,
    this.views,
    this.adminNote,
  });

  final ListingStatus status;
  final String title;
  final String subtitle;
  final int? views;
  final String? adminNote; // admin_note (changes_requested) / เหตุผลที่ปฏิเสธ (rejected)
}

const _listings = <_Listing>[
  // แอดมินตีกลับให้แก้ไข
  _Listing(
    status: ListingStatus.actionRequired,
    title: 'Bean bag chair',
    subtitle: '15 THB · Maple Hall',
    adminNote: 'Please add clearer photos of the front.',
  ),
  // แอดมินปฏิเสธ (ผู้ขายต้องเห็นเหตุผล ไม่งั้นไม่รู้ว่าทำไมสินค้าหายไป)
  _Listing(
    status: ListingStatus.rejected,
    title: 'Energy drink pack',
    subtitle: '40 THB · Maple Hall',
    adminNote: 'Prohibited item: food and drink are not allowed.',
  ),
  // รอแอดมินอนุมัติ ยังไม่โชว์ยอดวิว
  _Listing(
    status: ListingStatus.pending,
    title: 'Mini fridge',
    subtitle: '60 THB · Oak Hall',
  ),
  // ด่วน อนุมัติแล้ว
  _Listing(
    status: ListingStatus.urgent,
    title: 'Oak study desk',
    subtitle: '45 THB · Maple Hall',
    views: 48,
  ),
  // ปกติ อนุมัติแล้ว
  _Listing(
    status: ListingStatus.active,
    title: 'Acoustic guitar',
    subtitle: '80 THB · Maple Hall',
    views: 31,
  ),
];

const _soldCount = 8; // TODO: นับจากสินค้าสถานะ sold

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

  static int get _activeCount => _listings
      .where(
        (l) =>
            l.status == ListingStatus.active ||
            l.status == ListingStatus.urgent,
      )
      .length;

  static int get _totalViews =>
      _listings.fold(0, (sum, l) => sum + (l.views ?? 0));

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
              'My listings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _cInk,
              ),
            ),
            Text(
              '$_activeCount active listings',
              style: const TextStyle(fontSize: 12, color: _cMuted),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _cInk),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: _cInk),
            onPressed: () {}, // TODO: Action add listing
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Stats Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _cBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat('$_activeCount', 'Active'),
                Container(width: 1, height: 40, color: _cBorder),
                _buildStat('$_soldCount', 'Sold'),
                Container(width: 1, height: 40, color: _cBorder),
                _buildStat('$_totalViews', 'Total views'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          for (var i = 0; i < _listings.length; i++) ...[
            if (i > 0) const Divider(color: _cBorder, height: 32),
            _ListingItem(
              status: _listings[i].status,
              title: _listings[i].title,
              subtitle: _listings[i].subtitle,
              views: _listings[i].views,
              adminNote: _listings[i].adminNote,
              imageUrl: 'https://via.placeholder.com/80',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStat(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: _cMuted)),
      ],
    );
  }
}

class _ListingItem extends StatelessWidget {
  final String title, subtitle, imageUrl;
  final ListingStatus status;
  final int? views;
  final String? adminNote;

  const _ListingItem({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.status,
    this.views,
    this.adminNote,
  });

  @override
  Widget build(BuildContext context) {
    // กำหนดสีและข้อความของ Badge ตามสถานะ
    String badgeLabel;
    Color badgeBg;
    Color badgeFg;

    switch (status) {
      case ListingStatus.pending:
        badgeLabel = 'Pending review';
        badgeBg = _cAmberBg;
        badgeFg = _cAmberFg;
        break;
      case ListingStatus.actionRequired:
        badgeLabel = 'Action required';
        badgeBg = _cRedBg;
        badgeFg = _cRedFg;
        break;
      case ListingStatus.rejected:
        badgeLabel = 'Rejected';
        badgeBg = _cRedBg;
        badgeFg = _cRedFg;
        break;
      case ListingStatus.urgent:
        badgeLabel = 'Urgent';
        badgeBg = _cRedBg;
        badgeFg = _cRedFg;
        break;
      case ListingStatus.active:
      default:
        badgeLabel = 'Active';
        badgeBg = _cSageBg;
        badgeFg = _cSageFg;
        break;
    }

    // ซ่อนยอดวิวถ้ายังไม่ผ่านการอนุมัติ
    final showViews =
        (status == ListingStatus.active || status == ListingStatus.urgent) &&
        views != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            // รูปโหลดไม่ได้ (หรือยังไม่มีรูปจริง) ให้โชว์กรอบเทาแทน
            errorBuilder: (_, __, ___) => Container(
              width: 80,
              height: 80,
              color: const Color(0xFFF0EEE9),
              child: const Icon(Icons.image_outlined, color: _cMuted),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeFg,
                      ),
                    ),
                  ),
                  if (showViews)
                    Text(
                      '$views views',
                      style: const TextStyle(fontSize: 11, color: _cMuted),
                    )
                  else if (status == ListingStatus.pending)
                    const Text(
                      'Not visible yet',
                      style: TextStyle(fontSize: 11, color: _cMuted),
                    )
                  else if (status == ListingStatus.rejected)
                    const Text(
                      'Not published',
                      style: TextStyle(fontSize: 11, color: _cMuted),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _cInk,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: _cMuted),
              ),

              // กล่องข้อความจากแอดมิน (Action required = สิ่งที่ต้องแก้, Rejected = เหตุผลที่ปฏิเสธ)
              if ((status == ListingStatus.actionRequired ||
                      status == ListingStatus.rejected) &&
                  adminNote != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _cRedBg.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _cRedBg),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: _cRedFg),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          adminNote!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _cRedFg,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // TODO: เปิดหน้าแก้ไขสินค้า (ยังไม่มีหน้านี้ใน Sprint 2)
              // สินค้าที่ถูกปฏิเสธแก้ไม่ได้ ผู้ขายต้องลงขายใหม่
              if (status != ListingStatus.rejected) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      status == ListingStatus.actionRequired
                          ? 'Fix listing'
                          : 'Edit listing',
                      style: TextStyle(
                        fontSize: 12,
                        color: status == ListingStatus.actionRequired
                            ? _cRedFg
                            : _cLink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: status == ListingStatus.actionRequired
                          ? _cRedFg
                          : _cLink,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
