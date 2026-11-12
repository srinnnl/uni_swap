import 'package:flutter/material.dart';
import 'package:uni_swap/view/user/campus_locations.dart';
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

enum ItemStatus {
  active,
  urgent,
  pending,
  actionRequired,
  rejected,
  reserved,
  sold,
  hidden,
}

class _Item {
  const _Item({
    required this.status,
    required this.title,
    required this.subtitle,
    this.views,
    this.adminNote,
    this.draft,
  });

  final ItemStatus status;
  final String title;
  final String subtitle;
  final int? views;
  final String? adminNote;
  final SellDraft? draft; // ข้อมูลเดิมสำหรับหน้าแก้ไข (TODO: มาจาก API)
}

final _items = <_Item>[
  _Item(
    status: ItemStatus.actionRequired,
    title: 'Bean bag chair',
    subtitle: '15 THB · Lamduan 1 Dormitory',
    adminNote: 'Please add clearer photos of the front.',
    draft: SellDraft(
      productId: 1,
      title: 'Bean bag chair',
      price: 15,
      categoryId: 1,
      description: 'Comfy, lightly used.',
      location: locationById(12),
    ),
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
    draft: SellDraft(
      productId: 2,
      title: 'Mini fridge',
      price: 60,
      categoryId: 7,
      condition: 'good',
      location: locationById(13),
    ),
  ),
  _Item(
    status: ItemStatus.reserved,
    title: 'City bike',
    subtitle: '120 THB · Lamduan 1 Dormitory',
  ),
  _Item(
    status: ItemStatus.urgent,
    title: 'Oak study desk',
    subtitle: '45 THB · Lamduan 1 Dormitory',
    views: 48,
    draft: SellDraft(
      productId: 3,
      title: 'Oak study desk',
      price: 45,
      categoryId: 1,
      condition: 'good',
      location: locationById(12),
      deadline: DateTime.now().add(const Duration(days: 3)),
    ),
  ),
  _Item(
    status: ItemStatus.active,
    title: 'Acoustic guitar',
    subtitle: '80 THB · Lamduan 1 Dormitory',
    views: 31,
    draft: SellDraft(
      productId: 4,
      title: 'Acoustic guitar',
      price: 80,
      categoryId: 9,
      condition: 'like_new',
      location: locationById(12),
    ),
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            // Header (อยู่ตรงกลางเรียบร้อย)
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

            // Stats
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cBorder, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat('$_activeCount', 'Active'),
                  Container(width: 1, height: 40, color: _cBorder), // เส้นคั่น
                  _buildStat('$_soldCount', 'Sold'),
                  Container(width: 1, height: 40, color: _cBorder),
                  _buildStat('$_totalViews', 'Views'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ✨ ปุ่ม Sell เปลี่ยนให้ทึบและเด่นขึ้น ไม่แย่งซีนกับกล่องสถิติ
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SellPage()),
                ),
                icon: const Icon(Icons.add),
                label: const Text(
                  'Sell a new item',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      _cInk, // ✨ 1. เปลี่ยนพื้นหลังเป็นสีดำ (_cInk)
                  foregroundColor:
                      Colors.white, // ✨ 2. เปลี่ยนตัวอักษร/ไอคอนเป็นสีขาว
                  elevation: 0, // ✨ 3. เอาเงาออกให้ดูคลีนแบนราบไปเลย
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    // ✨ 4. เอาเส้นขอบ (side: BorderSide...) ออกไปเลยครับ
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Recent items
            const Text(
              'Recent items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _cInk,
              ),
            ),
            const SizedBox(height: 12),

            for (final item in _items)
              Container(
                // ✨ 1. เปลี่ยน padding/margin ให้ห่างกันเหมือนหน้า Orders
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                // ✨ 2. ทำกล่องสีขาว โค้งมน ไม่มีเส้นขอบ/เงา (สไตล์มินิมอล)
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _ItemCard(
                  status: item.status,
                  title: item.title,
                  subtitle: item.subtitle,
                  views: item.views,
                  adminNote: item.adminNote,
                  onEdit: item.draft == null
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SellPage(existing: item.draft),
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ✨ 4. แก้ฟังก์ชัน _buildStat นิดหน่อย ให้ตัวหนังสือเป็นสีดำเพื่อให้กลืนกับพื้นหลังสีสว่าง
  Widget _buildStat(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _cInk, // เปลี่ยนจากสีขาวเป็นสี _cInk
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: _cMuted)),
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
  final VoidCallback? onEdit;

  const _ItemCard({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.status,
    this.views,
    this.adminNote,
    this.onEdit,
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
      case ItemStatus.reserved:
        badgeLabel = 'Reserved';
        badgeBg = _cAmberBg;
        badgeFg = _cAmberFg;
        break;
      case ItemStatus.sold:
        badgeLabel = 'Sold';
        badgeBg = _cSageBg;
        badgeFg = _cSageFg;
        break;
      case ItemStatus.hidden:
        badgeLabel = 'Hidden';
        badgeBg = const Color(0xFFF0EEE9);
        badgeFg = _cMuted;
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
                  else if (status == ItemStatus.reserved)
                    const Text(
                      'In an order',
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
              if (status != ItemStatus.rejected &&
                  status != ItemStatus.reserved &&
                  status != ItemStatus.sold) ...[
                const SizedBox(height: 10),
                InkWell(
                  onTap: onEdit,
                  child: Row(
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
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
