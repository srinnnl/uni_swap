import 'package:flutter/material.dart';
import 'package:uni_swap/view/user/sell_page.dart'; // ดึงหน้าลงขายมา

const _cBg = Color(0xFFFAF9F6);
const _cInk = Color(0xFF2B2B26);
const _cMuted = Color(0xFF8A8A82);
const _cBorder = Color(0xFFE6E4DE);
const _cLink = Color(0xFF4A5C8F);

const _cAmberBg = Color(0xFFFBEBC2);
const _cAmberFg = Color(0xFF8A6410);
const _cRedBg = Color(0xFFF8DADA);
const _cRedFg = Color(0xFFB3402F);
const _cSageBg = Color(0xFFD8E4DC);
const _cSageFg = Color(0xFF3F6B52);

// เปลี่ยนชื่อ Enum จาก ListingStatus เป็น ItemStatus
enum ItemStatus { active, urgent, pending, actionRequired, rejected }

// เปลี่ยนชื่อคลาส _Listing เป็น _Item
class _Item {
  const _Item({
    required this.status,
    required this.title,
    required this.subtitle,
    this.views,
    this.adminNote,
  });

  final ItemStatus status;
  final String title;
  final String subtitle;
  final int? views;
  final String? adminNote;
}

// เปลี่ยนตัวแปร _listings เป็น _items
const _items = <_Item>[
  _Item(
    status: ItemStatus.actionRequired,
    title: 'Bean bag chair',
    subtitle: '15 THB · Lamduan 1 Dormitory',
    adminNote: 'Please add clearer photos of the front.',
  ),
  _Item(
    status: ItemStatus.rejected,
    title: 'Energy drink pack',
    subtitle: '40 THB · Lamduan 1 Dormitory',
    adminNote: 'Prohibited item: food and drink are not allowed.',
  ),
  _Item(
    status: ItemStatus.pending,
    title: 'Mini fridge',
    subtitle: '60 THB · Lamduan 2 Dormitory',
  ),
  _Item(
    status: ItemStatus.urgent,
    title: 'Oak study desk',
    subtitle: '45 THB · Lamduan 1 Dormitory',
    views: 48,
  ),
  _Item(
    status: ItemStatus.active,
    title: 'Acoustic guitar',
    subtitle: '80 THB · Lamduan 1 Dormitory',
    views: 31,
  ),
];

const _soldCount = 8;

class MyItemsPage extends StatelessWidget {
  const MyItemsPage({super.key});

  static int get _activeCount => _items
      .where(
        (i) => i.status == ItemStatus.active || i.status == ItemStatus.urgent,
      )
      .length;

  static int get _totalViews =>
      _items.fold(0, (sum, i) => sum + (i.views ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cBg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          // ท้ายหน้าเว้น 120 ให้พ้นแถบเมนูล่าง (เหมือนหน้า Orders)
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            Center(
              child: Column(
                children: [
                  const Text(
                    'My items',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _cInk,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_activeCount active items',
                    style: const TextStyle(fontSize: 13, color: _cMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // กล่อง Stats ให้เป็นสีเข้ม ตัดกับแอปสีสว่าง
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: _cInk,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat('$_activeCount', 'Active'),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _buildStat('$_soldCount', 'Sold'),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _buildStat('$_totalViews', 'Views'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SellPage()),
                ),
                icon: const Icon(Icons.add),
                label: const Text(
                  'Sell an item',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _cInk,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            const Text(
              'Recent items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _cInk,
              ),
            ),
            const SizedBox(height: 12),

            // แถวเรียบมีเส้นคั่น เหมือนรายการในหน้า Orders
            for (final item in _items)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: _cBorder)),
                ),
                child: _ItemCard(
                  status: item.status,
                  title: item.title,
                  subtitle: item.subtitle,
                  views: item.views,
                  adminNote: item.adminNote,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFFC9C7BF)),
        ),
      ],
    );
  }
}

// เปลี่ยนชื่อคลาส _ListingItem เป็น _ItemCard
class _ItemCard extends StatelessWidget {
  final String title, subtitle;
  final String? imageUrl; // null = แสดงไอคอนแทนรูป
  final ItemStatus status;
  final int? views;
  final String? adminNote;

  const _ItemCard({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.status,
    this.views,
    this.adminNote,
  });

  @override
  Widget build(BuildContext context) {
    String badgeLabel;
    Color badgeBg;
    Color badgeFg;

    switch (status) {
      case ItemStatus.pending:
        badgeLabel = 'Pending review';
        badgeBg = _cAmberBg;
        badgeFg = _cAmberFg;
        break;
      case ItemStatus.actionRequired:
        badgeLabel = 'Action required';
        badgeBg = _cRedBg;
        badgeFg = _cRedFg;
        break;
      case ItemStatus.rejected:
        badgeLabel = 'Rejected';
        badgeBg = _cRedBg;
        badgeFg = _cRedFg;
        break;
      case ItemStatus.urgent:
        badgeLabel = 'Urgent';
        badgeBg = _cRedBg;
        badgeFg = _cRedFg;
        break;
      case ItemStatus.active:
        badgeLabel = 'Active';
        badgeBg = _cSageBg;
        badgeFg = _cSageFg;
        break;
    }

    final showViews =
        (status == ItemStatus.active || status == ItemStatus.urgent) &&
        views != null;

    final placeholder = Container(
      width: 80,
      height: 94,
      color: const Color(0xFFF0EEE9),
      child: const Icon(Icons.image_outlined, color: _cMuted),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: imageUrl == null
              ? placeholder
              : Image.network(
                  imageUrl!,
                  width: 80,
                  height: 94,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => placeholder,
                ),
        ),
        const SizedBox(width: 14),
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
                  else if (status == ItemStatus.pending)
                    const Text(
                      'Not visible yet',
                      style: TextStyle(fontSize: 11, color: _cMuted),
                    )
                  else if (status == ItemStatus.rejected)
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
              if ((status == ItemStatus.actionRequired ||
                      status == ItemStatus.rejected) &&
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
              if (status != ItemStatus.rejected) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      // แก้คำว่า listing เป็น item
                      status == ItemStatus.actionRequired
                          ? 'Fix item'
                          : 'Edit item',
                      style: TextStyle(
                        fontSize: 12,
                        color: status == ItemStatus.actionRequired
                            ? _cRedFg
                            : _cLink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: status == ItemStatus.actionRequired
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
