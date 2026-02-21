import 'package:flutter/material.dart';

class IconColorMapper {
  static String colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  // Convert Hex String to Color
  static Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  // Map icons to strings
  static final Map<String, IconData> _stringToIcon = {
    'restaurant': Icons.restaurant_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'directions_car': Icons.directions_car_rounded,
    'home': Icons.home_rounded,
    'bolt': Icons.bolt_rounded,
    'movie': Icons.movie_rounded,
    'local_hospital': Icons.local_hospital_rounded,
    'account_balance_wallet': Icons.account_balance_wallet_rounded,
    'work': Icons.work_rounded,
    'trending_up': Icons.trending_up_rounded,
    'pets': Icons.pets_rounded,
    'flight': Icons.flight_rounded,
    'school': Icons.school_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'devices': Icons.devices_rounded,
    'category': Icons.category_rounded, // default
  };

  static final Map<IconData, String> _iconToString = _stringToIcon.map(
    (key, value) => MapEntry(value, key),
  );

  // Convert IconData to String
  static String iconToString(IconData icon) {
    return _iconToString[icon] ?? 'category';
  }

  // Convert String to IconData
  static IconData stringToIcon(String name) {
    return _stringToIcon[name] ?? Icons.category_rounded;
  }
}
