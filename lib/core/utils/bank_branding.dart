import 'package:flutter/material.dart';

/// Shared bank branding utility — maps bank name keywords to brand color + icon.
/// Used by both AddAccountScreen (card preview) and AccountsListScreen (account cards).
class BankBranding {
  static const Map<String, Map<String, dynamic>> _brandMap = {
    'hdfc': {'color': Color(0xFF004C8F), 'icon': Icons.account_balance},
    'icici': {'color': Color(0xFFE85012), 'icon': Icons.credit_card},
    'sbi': {'color': Color(0xFF1A237E), 'icon': Icons.account_balance},
    'state bank': {'color': Color(0xFF1A237E), 'icon': Icons.account_balance},
    'axis': {'color': Color(0xFF97144D), 'icon': Icons.credit_card},
    'kotak': {'color': Color(0xFFEE2737), 'icon': Icons.account_balance},
    'pnb': {'color': Color(0xFFFFC72C), 'icon': Icons.account_balance},
    'punjab national': {
      'color': Color(0xFFFFC72C),
      'icon': Icons.account_balance,
    },
    'union': {'color': Color(0xFF0055A5), 'icon': Icons.account_balance},
    'bank of baroda': {
      'color': Color(0xFFF05A22),
      'icon': Icons.account_balance,
    },
    'yes bank': {'color': Color(0xFF0032A0), 'icon': Icons.account_balance},
    'indusind': {'color': Color(0xFF1D4289), 'icon': Icons.credit_card},
    'idfc': {'color': Color(0xFFF5512C), 'icon': Icons.credit_card},
    'chase': {'color': Color(0xFF117ACA), 'icon': Icons.credit_card},
    'wells fargo': {'color': Color(0xFFD71E28), 'icon': Icons.account_balance},
    'citi': {'color': Color(0xFF003B80), 'icon': Icons.credit_card},
    'hsbc': {'color': Color(0xFFDB0011), 'icon': Icons.account_balance},
    'barclays': {'color': Color(0xFF00AEEF), 'icon': Icons.account_balance},
    'amex': {'color': Color(0xFF2E77BC), 'icon': Icons.credit_card},
    'american express': {'color': Color(0xFF2E77BC), 'icon': Icons.credit_card},
    'discover': {'color': Color(0xFFFF6600), 'icon': Icons.credit_card},
    'rbl': {'color': Color(0xFF8B0000), 'icon': Icons.credit_card},
    'bandhan': {'color': Color(0xFF00796B), 'icon': Icons.account_balance},
    'federal': {'color': Color(0xFF1565C0), 'icon': Icons.account_balance},
    'canara': {'color': Color(0xFF1B5E20), 'icon': Icons.account_balance},
    'indian bank': {'color': Color(0xFF4A148C), 'icon': Icons.account_balance},
    'bank of india': {
      'color': Color(0xFFC62828),
      'icon': Icons.account_balance,
    },
    'uco': {'color': Color(0xFF006064), 'icon': Icons.account_balance},
    'idbi': {'color': Color(0xFF880E4F), 'icon': Icons.account_balance},
  };

  static const Color _defaultColor = Color(0xFF6366F1);
  static const IconData _defaultIcon = Icons.account_balance_rounded;

  /// Returns brand color for a given bank name. Falls back to a purple default.
  static Color colorFor(String bankName) {
    final lower = bankName.toLowerCase();
    for (final entry in _brandMap.entries) {
      if (lower.contains(entry.key)) {
        return entry.value['color'] as Color;
      }
    }
    return _defaultColor;
  }

  /// Returns brand icon for a given bank name.
  static IconData iconFor(String bankName) {
    final lower = bankName.toLowerCase();
    for (final entry in _brandMap.entries) {
      if (lower.contains(entry.key)) {
        return entry.value['icon'] as IconData;
      }
    }
    return _defaultIcon;
  }

  /// Returns a gradient pair (light → dark variant of brand color) for card rendering.
  static List<Color> gradientFor(String bankName) {
    final base = colorFor(bankName);
    return [base, Color.alphaBlend(Colors.black.withAlpha(60), base)];
  }

  /// Converts the UI display type (e.g. "Credit card") to the DB-stored value ("CreditCard").
  static String toDbType(String displayType) =>
      displayType == 'Credit card' ? 'CreditCard' : displayType;

  /// Converts the DB-stored type ("CreditCard") back to the UI display label ("Credit card").
  static String fromDbType(String dbType) =>
      dbType == 'CreditCard' ? 'Credit card' : dbType;
}
