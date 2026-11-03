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

enum ListingStatus { active, urgent, pending, actionRequired }

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

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
              '4 active listings',
              style: TextStyle(fontSize: 12, color: _cMuted),
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
                _buildStat('4', 'Active'),
                Container(width: 1, height: 40, color: _cBorder),
                _buildStat('8', 'Sold'),
                Container(width: 1, height: 40, color: _cBorder),
                _buildStat('124', 'Total views'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 1. สถานะ: แอดมินตีกลับให้แก้ไข (Action Required)
          const _ListingItem(
            status: ListingStatus.actionRequired,
            title: 'Bean bag chair',
            subtitle: '15 THB · Maple Hall',
            imageUrl: 'https://via.placeholder.com/80',
            adminNote: 'Please add clearer photos of the front.',
          ),
          const Divider(color: _cBorder, height: 32),

          // 2. สถานะ: รอแอดมินอนุมัติ (Pending Review) - ยังไม่โชว์ยอดวิว
          const _ListingItem(
            status: ListingStatus.pending,
            title: 'Mini fridge',
            subtitle: '60 THB · Oak Hall',
            imageUrl: 'https://via.placeholder.com/80',
          ),
          const Divider(color: _cBorder, height: 32),

          // 3. สถานะ: ด่วน (Urgent) อนุมัติแล้ว
          const _ListingItem(
            status: ListingStatus.urgent,
            views: 48,
            title: 'Oak study desk',
            subtitle: '45 THB · Maple Hall',
            imageUrl: 'https://via.placeholder.com/80',
          ),
          const Divider(color: _cBorder, height: 32),

          // 4. สถานะ: ปกติ (Active) อนุมัติแล้ว
          const _ListingItem(
            status: ListingStatus.active,
            views: 31,
            title: 'Acoustic guitar',
            subtitle: '80 THB · Maple Hall',
            imageUrl: 'https://via.placeholder.com/80',
          ),
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

              // กล่องแจ้งเตือนจากแอดมิน (แสดงเฉพาะตอนสถานะ Action Required)
              if (status == ListingStatus.actionRequired &&
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
          ),
        ),
      ],
    );
  }
}
