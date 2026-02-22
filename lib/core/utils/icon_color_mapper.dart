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
  static List<String> get availableIcons => _stringToIcon.keys.toList();

  static final Map<String, IconData> _stringToIcon = {
    // Basic & Finance
    'payments': Icons.payments_rounded,
    'account_balance_wallet': Icons.account_balance_wallet_rounded,
    'savings': Icons.savings_rounded,
    'trending_up': Icons.trending_up_rounded,
    'trending_down': Icons.trending_down_rounded,
    'request_quote': Icons.request_quote_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'credit_card': Icons.credit_card_rounded,
    'account_balance': Icons.account_balance_rounded,
    'token': Icons.token_rounded,

    // Lifestyle & Expense
    'shopping_cart': Icons.shopping_cart_rounded,
    'restaurant': Icons.restaurant_rounded,
    'home': Icons.home_rounded,
    'directions_car': Icons.directions_car_rounded,
    'flight': Icons.flight_rounded,
    'movie': Icons.movie_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'medical_services': Icons.medical_services_rounded,
    'school': Icons.school_rounded,
    'pets': Icons.pets_rounded,
    'construction': Icons.construction_rounded,
    'healing': Icons.healing_rounded,
    'self_improvement': Icons.self_improvement_rounded,
    'spa': Icons.spa_rounded,

    // Utilities & Tech
    'bolt': Icons.bolt_rounded,
    'water_drop': Icons.water_drop_rounded,
    'wifi': Icons.wifi_rounded,
    'devices': Icons.devices_rounded,
    'computer': Icons.computer_rounded,
    'phone_android': Icons.phone_android_rounded,

    // Work & Others
    'work': Icons.work_rounded,
    'business': Icons.business_rounded,
    'inventory': Icons.inventory_rounded,
    'verified_user': Icons.verified_user_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
    'more_time': Icons.more_time_rounded,
    'category': Icons.category_rounded, // default
  };

  static final Map<IconData, String> _iconToString = _stringToIcon.map(
    (key, value) => MapEntry(value, key),
  );

  // Premium Color Palette
  static const List<String> premiumColors = [
    '#10B981', // Emerald
    '#3B82F6', // Blue
    '#6366F1', // Indigo
    '#8B5CF6', // Violet
    '#EC4899', // Pink
    '#F43F5E', // Rose
    '#F59E0B', // Amber
    '#F97316', // Orange
    '#06B6D4', // Cyan
    '#0EA5E9', // Sky
    '#64748B', // Slate
    '#475569', // Slate 600
  ];

  // Convert IconData to String
  static String iconToString(IconData icon) {
    return _iconToString[icon] ?? 'category';
  }

  // Convert String to IconData
  static IconData stringToIcon(String name) {
    return _stringToIcon[name] ?? Icons.category_rounded;
  }
}
