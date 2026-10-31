import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                // 1. แถบด้านบน (โลโก้ + ชื่อแอป + กระดิ่งแจ้งเตือน)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'U',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'serif',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'UniSwap',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none,
                        color: Colors.black87,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. ปุ่มเลือกสถานที่
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.black54,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'North Campus · Maple Hall',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.black54),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 3. ข้อความทักทาย
                const Text(
                  'Good morning, Maya',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Find something nearby.',
                  style: TextStyle(
                    fontSize: 32,
                    color: Color(0xFF333333),
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 32),

                // 4. แถบหมวดหมู่ (Tabs)
                Row(
                  children: [
                    _buildTab(text: 'Same place', isActive: true),
                    const SizedBox(width: 24),
                    _buildTab(text: 'Same zone', isActive: false),
                    const SizedBox(width: 24),
                    _buildTab(text: 'All campus', isActive: false),
                  ],
                ),
                const Divider(
                  height: 1,
                  color: Colors.black12,
                ), // เส้นคั่นใต้ tab
                const SizedBox(height: 24),

                // 5. หัวข้อ "Near you"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Near you',
                          style: TextStyle(
                            fontSize: 20,
                            color: Color(0xFF333333),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Items in Maple Hall',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'See all',
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

                // 6. ตารางแสดงสินค้า (GridView)
                GridView.count(
                  crossAxisCount: 2, // แบ่งเป็น 2 คอลัมน์
                  crossAxisSpacing: 16, // ระยะห่างแนวนอน
                  mainAxisSpacing: 16, // ระยะห่างแนวตั้ง
                  childAspectRatio: 0.65, // สัดส่วนการ์ด (ความกว้างต่อความสูง)
                  shrinkWrap: true, // ให้ GridView ย่อขนาดตามเนื้อหา
                  physics:
                      const NeverScrollableScrollPhysics(), // ปิดการเลื่อนของ Grid ปล่อยให้หน้าหลักเลื่อนแทน
                  children: [
                    _buildProductCard(
                      title: 'Oak study desk',
                      price: '\$45',
                      oldPrice: '\$70',
                      locationTime: 'Maple Hall · 2 min',
                      isUrgent: true,
                    ),
                    _buildProductCard(
                      title: 'Acoustic guitar',
                      price: '\$80',
                      locationTime: 'Maple Hall · 4 min',
                      isUrgent: false,
                    ),
                  ],
                ),
                const SizedBox(height: 24), // เว้นที่ว่างด้านล่างเผื่อติดขอบ
              ],
            ),
          ),
        ),
      ),
    );
  }

  // วิดเจ็ตย่อยสำหรับสร้าง Tab เมนู
  Widget _buildTab({required String text, required bool isActive}) {
    return Column(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? const Color(0xFF333333) : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        if (isActive)
          Container(height: 2, width: 80, color: const Color(0xFF333333))
        else
          const SizedBox(height: 2),
      ],
    );
  }

  // วิดเจ็ตย่อยสำหรับสร้าง การ์ดสินค้าแต่ละชิ้น
  Widget _buildProductCard({
    required String title,
    required String price,
    String? oldPrice,
    required String locationTime,
    required bool isUrgent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // รูปภาพสินค้า + ไอคอนหัวใจ + ป้าย Urgent
        Expanded(
          child: Stack(
            children: [
              // กรอบรูปภาพจำลอง
              Container(
                decoration: BoxDecoration(
                  color: Colors.black12, // สีเทาแทนรูป
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // ไอคอนหัวใจมุมขวาบน
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
              // ป้าย Urgent มุมซ้ายล่าง
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
        // ชื่อสินค้า
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
        // ราคา
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
        const SizedBox(height: 4),
        // สถานที่และเวลา
        Text(
          locationTime,
          style: const TextStyle(fontSize: 12, color: Colors.black45),
        ),
      ],
    );
  }
}
