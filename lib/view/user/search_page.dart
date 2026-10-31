import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // สร้างวิดเจ็ตย่อยสำหรับหมวดหมู่ (Category Chip)
  Widget _buildCategoryChip({
    required String label,
    IconData? icon,
    Color? iconColor,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF333333) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF333333) : Colors.black12,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: iconColor ?? Colors.black54),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? Colors.white : const Color(0xFF333333),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // วิดเจ็ตย่อยสำหรับแถวตัวกรอง (Price range, Location)
  Widget _buildFilterRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 20, color: Colors.black54),
        ],
      ),
    );
  }

  // วิดเจ็ตย่อยสำหรับสร้างการ์ดสินค้า (ก๊อปมาจากหน้า Home ได้เลย)
  Widget _buildProductCard({
    required String title,
    required String price,
    String? oldPrice,
    required bool isUrgent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    size: 20,
                    color: Colors.black54,
                  ),
                ),
              ),
              if (isUrgent)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE5E5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Urgent',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              price,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            if (oldPrice != null) ...[
              const SizedBox(width: 8),
              Text(
                oldPrice,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // สีพื้นหลังอิงตามรูป
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header (คำว่า Search และจุด 3 จุด)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Search',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(
                          Icons.more_horiz,
                          color: Colors.black87,
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. แถบค้นหา (Search Bar)
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search desks, books, bikes...',
                    hintStyle: const TextStyle(color: Colors.black38),
                    prefixIcon: const Icon(Icons.search, color: Colors.black54),
                    suffixIcon: const Icon(
                      Icons.tune,
                      color: Colors.black54,
                    ), // ไอคอน filter
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. หมวดหมู่ (Category)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'Clear all',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // แถบเลื่อนหมวดหมู่แนวนอน
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip(label: 'All', isSelected: true),
                      _buildCategoryChip(
                        label: 'Furniture',
                        icon: Icons.chair_alt_outlined,
                        iconColor: Colors.brown,
                      ),
                      _buildCategoryChip(
                        label: 'Books',
                        icon: Icons.menu_book,
                        iconColor: Colors.green,
                      ),
                      _buildCategoryChip(
                        label: 'Tech',
                        icon: Icons.computer,
                        iconColor: Colors.blue,
                      ),
                      _buildCategoryChip(
                        label: 'Transport',
                        icon: Icons.pedal_bike,
                        iconColor: Colors.redAccent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4. กล่องตัวกรอง (Price range & Location)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    children: [
                      _buildFilterRow(
                        icon: Icons.sell_outlined,
                        title: 'Price range',
                        value: 'Any price',
                      ),
                      const Divider(height: 1, color: Colors.black12),
                      _buildFilterRow(
                        icon: Icons.map_outlined,
                        title: 'Location',
                        value: 'Maple Hall +2',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 5. หัวข้อผลลัพธ์ (24 items)
                const Text(
                  '24 items',
                  style: TextStyle(fontSize: 20, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Closest first',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'Sort by',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 6. GridView สินค้าผลลัพธ์
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildProductCard(
                      title: 'Oak study desk',
                      price: '\$45',
                      oldPrice: '\$70',
                      isUrgent: true,
                    ),
                    _buildProductCard(
                      title: 'Acoustic guitar',
                      price: '\$80',
                      isUrgent: false,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
