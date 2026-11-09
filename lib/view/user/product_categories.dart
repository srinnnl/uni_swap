import 'package:flutter/material.dart';

// ไฟล์กลางของหมวดหมู่สินค้า ใช้ร่วมกันทุกหน้า (sell, search, product_detail)
// วางที่ lib/view/user/product_categories.dart (path เดียวกับ campus_locations.dart)
// ตรงกับ DB: categories (ชุดเดียวกับที่ admin จัดการในหน้า Categories)
// TODO: เปลี่ยน kProductCategories เป็นข้อมูลจาก API (รายการ categories ที่ active)

class ProductCategory {
  const ProductCategory(this.id, this.name, this.icon);
  final int id; // categories.category_id (ตัวเลขในนี้เป็นค่าจำลอง)
  final String name;
  final IconData icon;
}

const kProductCategories = <ProductCategory>[
  ProductCategory(1, 'Furniture', Icons.chair_alt_outlined),
  ProductCategory(2, 'Books', Icons.menu_book_outlined),
  ProductCategory(3, 'Technology', Icons.computer_outlined),
  ProductCategory(4, 'Transport', Icons.pedal_bike_outlined),
  ProductCategory(5, 'Home & kitchen', Icons.kitchen_outlined),
  ProductCategory(6, 'Clothing', Icons.checkroom_outlined),
  ProductCategory(7, 'Appliances', Icons.electrical_services_outlined),
  ProductCategory(8, 'Sports', Icons.sports_soccer_outlined),
  ProductCategory(9, 'Music', Icons.music_note_outlined),
  ProductCategory(10, 'Stationery', Icons.edit_outlined),
  ProductCategory(11, 'Other', Icons.category_outlined),
];

/// ไอคอนจากชื่อหมวด (ไม่เจอ = ไอคอนทั่วไป)
IconData categoryIcon(String? name) {
  for (final c in kProductCategories) {
    if (c.name == name) return c.icon;
  }
  return Icons.sell_outlined;
}
