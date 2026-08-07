import 'package:flutter/material.dart';

abstract final class AppColors {
  static const canvas = Color(0xFFF6F3EC);
  static const surface = Color(0xFFFFFDF8);
  static const ink = Color(0xFF132238);
  static const inkMuted = Color(0xFF687384);
  static const lime = Color(0xFFB9F44A);
  static const limeDark = Color(0xFF668F14);
  static const aqua = Color(0xFF58D6C7);
  static const coral = Color(0xFFEF6A5B);
  static const line = Color(0xFFDDE0DA);
  static const navySoft = Color(0xFFE9EDF1);
}

ThemeData buildAppTheme() {
  const colorScheme = ColorScheme.light(
    primary: AppColors.ink,
    onPrimary: Colors.white,
    secondary: AppColors.lime,
    onSecondary: AppColors.ink,
    tertiary: AppColors.aqua,
    onTertiary: AppColors.ink,
    error: AppColors.coral,
    onError: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    outline: AppColors.line,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.canvas,
    splashFactory: InkSparkle.splashFactory,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displayLarge: const TextStyle(
        color: AppColors.ink,
        fontSize: 48,
        height: 0.98,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      displayMedium: const TextStyle(
        color: AppColors.ink,
        fontSize: 38,
        height: 1.04,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      headlineLarge: const TextStyle(
        color: AppColors.ink,
        fontSize: 30,
        height: 1.08,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      headlineMedium: const TextStyle(
        color: AppColors.ink,
        fontSize: 24,
        height: 1.12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleLarge: const TextStyle(
        color: AppColors.ink,
        fontSize: 19,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: const TextStyle(
        color: AppColors.ink,
        fontSize: 16,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: const TextStyle(
        color: AppColors.ink,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: const TextStyle(
        color: AppColors.inkMuted,
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: const TextStyle(
        color: AppColors.ink,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.canvas,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        side: BorderSide(color: AppColors.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 56),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size(64, 54),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        side: const BorderSide(color: AppColors.ink, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.lime,
      side: const BorderSide(color: AppColors.line),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      labelStyle: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      indicatorColor: AppColors.lime.withValues(alpha: 0.9),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? AppColors.ink
              : AppColors.inkMuted,
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w600,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.ink
              : AppColors.inkMuted,
        ),
      ),
    ),
  );
}
