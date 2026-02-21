import 'package:flutter/material.dart';

enum AppThemeOption {
  minimalist,
  dark,
  gradient,
  glassmorphism,
  neumorphism,
  retro,
  futuristic,
  organic,
  corporate,
  gamified,
  illustrative,
  material,
}

class AppTheme {
  static ThemeData getTheme(AppThemeOption option) {
    switch (option) {
      case AppThemeOption.minimalist:
        return _buildTheme(
          brightness: Brightness.light,
          bg: Colors.white,
          surface: Colors.grey[50]!,
          primary: Colors.black,
          accent: Colors.black54,
          text: Colors.black,
          textSec: Colors.grey[700]!,
          cardBorder: Colors.grey[200]!,
          elevation: 0,
        );
      case AppThemeOption.dark:
        return _buildTheme(
          brightness: Brightness.dark,
          bg: const Color(0xFF0F172A), // Deep Slate
          surface: const Color(0xFF1E293B),
          primary: const Color(0xFF6366F1), // Indigo
          accent: const Color(0xFF0EA5E9),
          text: const Color(0xFFF8FAFC),
          textSec: const Color(0xFF94A3B8),
          cardBorder: const Color(0xFF334155),
        );
      case AppThemeOption.gradient:
        return _buildTheme(
          brightness: Brightness.dark,
          bg: const Color(0xFF1A1A2E),
          surface: const Color(0xFF16213E),
          primary: const Color(0xFFE94560),
          accent: const Color(0xFF0F3460),
          text: Colors.white,
          textSec: Colors.white70,
          cardBorder: Colors.transparent,
        );
      case AppThemeOption.glassmorphism:
        return _buildTheme(
          brightness: Brightness.dark,
          bg: const Color(0xFF0B101E),
          surface: Colors.white.withAlpha(25), // Translucent
          primary: const Color(0xFF4DB8FF),
          accent: const Color(0xFFB14DFF),
          text: Colors.white,
          textSec: Colors.white70,
          cardBorder: Colors.white.withAlpha(50),
        );
      case AppThemeOption.neumorphism:
        return _buildTheme(
          brightness: Brightness.light,
          bg: const Color(0xFFE0E5EC),
          surface: const Color(0xFFE0E5EC),
          primary: const Color(0xFF4A90E2),
          accent: const Color(0xFF50E3C2),
          text: const Color(0xFF4A4A4A),
          textSec: const Color(0xFF8B8B8B),
          cardBorder: Colors.transparent,
        );
      case AppThemeOption.retro:
        return _buildTheme(
          brightness: Brightness.light,
          bg: const Color(0xFFF4ECD8), // Sepia/Beige
          surface: const Color(0xFFE8DABA),
          primary: const Color(0xFFD66853), // Rusty Orange
          accent: const Color(0xFF7D4E57),
          text: const Color(0xFF363636),
          textSec: const Color(0xFF5C5C5C),
          cardBorder: const Color(0xFFC4A485),
          fontFamily: 'Courier', // Example of retro font feel
        );
      case AppThemeOption.futuristic:
        return _buildTheme(
          brightness: Brightness.dark,
          bg: Colors.black,
          surface: const Color(0xFF080808),
          primary: const Color(0xFF00FFCC), // Neon Cyan
          accent: const Color(0xFFFF00FF), // Neon Pink
          text: const Color(0xFFE0FFFF),
          textSec: const Color(0xFF008B8B),
          cardBorder: const Color(0xFF00FFCC).withAlpha(100),
        );
      case AppThemeOption.organic:
        return _buildTheme(
          brightness: Brightness.light,
          bg: const Color(0xFFF6F7F3),
          surface: Colors.white,
          primary: const Color(0xFF4B6F44), // Forest Green
          accent: const Color(0xFF8B5A2B), // Earth Brown
          text: const Color(0xFF2F4F4F),
          textSec: const Color(0xFF6E8B3D),
          cardBorder: const Color(0xFFE4E6D9),
        );
      case AppThemeOption.corporate:
        return _buildTheme(
          brightness: Brightness.light,
          bg: const Color(0xFFF0F4F8), // Light cool gray
          surface: Colors.white,
          primary: const Color(0xFF0A2540), // Deep Navy
          accent: const Color(0xFF00D4B6),
          text: const Color(0xFF1A1A1A),
          textSec: const Color(0xFF5B6987),
          cardBorder: const Color(0xFFE2E8F0),
        );
      case AppThemeOption.gamified:
        return _buildTheme(
          brightness: Brightness.light,
          bg: const Color(0xFFFFFBE8), // Warm light yellow
          surface: Colors.white,
          primary: const Color(0xFFFF3366), // Punchy Pink
          accent: const Color(0xFFFFCC00), // Action Yellow
          text: const Color(0xFF2D2D2D),
          textSec: const Color(0xFF757575),
          cardBorder: const Color(0xFF2D2D2D), // Bold outlines
          borderWidth: 2.0,
        );
      case AppThemeOption.illustrative:
        return _buildTheme(
          brightness: Brightness.light,
          bg: const Color(0xFFFFF0F5), // Lavender Blush
          surface: Colors.white,
          primary: const Color(0xFFFF8DA1), // Soft Pastel Pink
          accent: const Color(0xFF81D4FA), // Soft Light Blue
          text: const Color(0xFF5D4037), // Soft Brown
          textSec: const Color(0xFFA1887F),
          cardBorder: const Color(0xFFFFCDD2),
        );
      case AppThemeOption.material:
        return ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue,
          brightness: Brightness.light,
        );
    }
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color primary,
    required Color accent,
    required Color text,
    required Color textSec,
    required Color cardBorder,
    double elevation = 0,
    double borderWidth = 1.0,
    String fontFamily = 'Roboto',
  }) {
    const errorColor = Color(0xFFEF4444);

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      fontFamily: fontFamily,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: primary.computeLuminance() > 0.5
            ? Colors.black
            : Colors.white,
        secondary: accent,
        onSecondary: accent.computeLuminance() > 0.5
            ? Colors.black
            : Colors.white,
        surface: surface,
        onSurface: text,
        error: errorColor,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          letterSpacing: -1.5,
        ),
        displayMedium: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(color: text, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: text, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: text, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: text, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: text, fontSize: 16),
        bodyMedium: TextStyle(color: text, fontSize: 14),
        labelLarge: TextStyle(
          color: text,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          elevation: elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cardBorder, width: borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cardBorder, width: borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        hintStyle: TextStyle(color: textSec),
        labelStyle: TextStyle(color: textSec),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: cardBorder, width: borderWidth),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSec,
        elevation: elevation,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withAlpha(50),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary);
          }
          return IconThemeData(color: textSec);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return TextStyle(
            color: textSec,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: elevation == 0 ? 2 : elevation,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: text),
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: IconThemeData(color: text),
    );
  }

  // Legacy fallback for explicit colors used directly in UI widgets previously
  static const Color primary = Color(0xFF6366F1);
  static const Color accent = Color(0xFF0EA5E9);
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
}
