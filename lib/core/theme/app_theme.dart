import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF07101F);
  static const surface = Color(0xFF0F1B2E);
  static const surfaceHigh = Color(0xFF16243B);
  static const border = Color(0xFF243552);

  static const gold = Color(0xFFE0B04B);
  static const goldSoft = Color(0xFFF2D08A);
  static const goldDeep = Color(0xFFB8862B);

  static const textPrimary = Color(0xFFF4F6FA);
  static const textMuted = Color(0xFF9AA7BD);

  static const success = Color(0xFF3DDC97);
  static const danger = Color(0xFFFF6B6B);
  static const info = Color(0xFF5AB8FF);

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldSoft, gold, goldDeep],
  );

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0B1830), background],
  );
}

class AppTheme {
  static const fontFamily = 'Tajawal';

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: fontFamily,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      onPrimary: Color(0xFF1A1204),
      secondary: AppColors.info,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.2),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 18, height: 1.5),
      bodyMedium: TextStyle(fontSize: 16, height: 1.5),
      bodySmall: TextStyle(fontSize: 13, color: AppColors.textMuted),
      labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    ).apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.textPrimary,
      titleTextStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(60),
        backgroundColor: AppColors.gold,
        foregroundColor: const Color(0xFF1A1204),
        textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.gold,
      thumbColor: AppColors.gold,
      inactiveTrackColor: AppColors.border,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.gold, width: 2),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.gold,
      foregroundColor: Color(0xFF1A1204),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.gold),
  );
}
