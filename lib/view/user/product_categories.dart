import 'package:flutter/material.dart';

const _categoryIcons = <String, IconData>{
  'Furniture': Icons.chair_alt_outlined,
  'Books': Icons.menu_book_outlined,
  'Technology': Icons.computer_outlined,
  'Transport': Icons.pedal_bike_outlined,
  'Home & kitchen': Icons.kitchen_outlined,
  'Clothing': Icons.checkroom_outlined,
  'Appliances': Icons.electrical_services_outlined,
  'Sports': Icons.sports_soccer_outlined,
  'Music': Icons.music_note_outlined,
  'Stationery': Icons.edit_outlined,
  'Other': Icons.category_outlined,
};

/// Category names come from the API; unknown names use a generic icon.
IconData categoryIcon(String? name) =>
    _categoryIcons[name] ?? Icons.sell_outlined;
