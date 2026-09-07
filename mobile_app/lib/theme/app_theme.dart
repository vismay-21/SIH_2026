import 'package:flutter/material.dart';

final appThemeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

class AppColors {
  static const primary = Color(0xFF245B52);
  static const primaryDark = Color(0xFF173B36);
  static const accent = Color(0xFFE8B84A);
  static const background = Color(0xFFF7F8F5);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF17211F);
  static const muted = Color(0xFF737C78);
  static const border = Color(0xFFD8DDDA);
  static const success = Color(0xFF3D8B68);
  static const danger = Color(0xFFC85C5C);
}

ThemeData buildAppTheme({bool darkMode = false}) {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: darkMode ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: darkMode ? Colors.black : AppColors.text,
        surface: darkMode ? const Color(0xFF202A27) : AppColors.surface,
        onSurface: darkMode ? const Color(0xFFF1F5F2) : AppColors.text,
        error: AppColors.danger,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: darkMode
        ? const Color(0xFF121815)
        : AppColors.background,
    fontFamily: 'Avenir Next',
    appBarTheme: AppBarTheme(
      backgroundColor: darkMode
          ? const Color(0xFF121815)
          : AppColors.background,
      foregroundColor: darkMode ? const Color(0xFFF1F5F2) : AppColors.text,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: _appButtonStyle()),
    filledButtonTheme: FilledButtonThemeData(style: _appButtonStyle()),
    outlinedButtonTheme: OutlinedButtonThemeData(style: _appButtonStyle()),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkMode ? const Color(0xFF202A27) : AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: darkMode ? const Color(0xFF52605B) : AppColors.border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: darkMode ? const Color(0xFF52605B) : AppColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkMode ? const Color(0xFF202A27) : AppColors.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      labelTextStyle: WidgetStatePropertyAll(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      color: darkMode ? const Color(0xFF202A27) : AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: darkMode ? const Color(0xFF52605B) : AppColors.border,
        ),
      ),
    ),
  );
}

ButtonStyle _appButtonStyle() => ButtonStyle(
  backgroundColor: const WidgetStatePropertyAll(AppColors.surface),
  foregroundColor: const WidgetStatePropertyAll(Colors.black),
  overlayColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.08)),
  elevation: const WidgetStatePropertyAll(3),
  shadowColor: const WidgetStatePropertyAll(Colors.black),
  padding: const WidgetStatePropertyAll(
    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
  shape: const WidgetStatePropertyAll(
    RoundedRectangleBorder(
      borderRadius: BorderRadius.zero,
      side: BorderSide(color: Colors.black, width: 1),
    ),
  ),
);
