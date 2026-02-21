import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  AppThemeOption _currentTheme = AppThemeOption.dark; // Default to dark

  AppThemeOption get currentTheme => _currentTheme;

  ThemeProvider() {
    _loadTheme();
  }

  ThemeData get themeData => AppTheme.getTheme(_currentTheme);

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_themeKey);
    if (index != null && index < AppThemeOption.values.length) {
      _currentTheme = AppThemeOption.values[index];
      notifyListeners();
    }
  }

  Future<void> setTheme(AppThemeOption theme) async {
    if (_currentTheme == theme) return;
    _currentTheme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
  }
}
