import 'package:flutter/material.dart';
import '../../shared/design_system/tokens/app_typography.dart';
import '../../shared/design_system/tokens/brand_colors.dart';
import 'app_colors.dart';

/// Central theme provider orchestrating Material 3 [ThemeData],
/// color schemes, typography presets, and custom theme extensions.
class AppTheme {
  AppTheme._();

  /// Default light theme configuration.
  static ThemeData get lightTheme => buildTheme(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      surface: AppColors.background,
      onSurface: AppColors.onBackground,
    ),
    brandColors: const BrandColors(
      dark: Color(0xFF0F172A),
      mid: Color(0xFF6366F1),
      subtle: Color(0xFFEEF2FF),
      accent: Color(0xFF818CF8),
      debt: Color(0xFFE11D48),
      progress: Color(0xFF059669),
      milestone: Color(0xFF0284C7),
      surfaceCard: Color(0xFFFFFFFF),
    ),
  );

  /// Default dark theme configuration.
  static ThemeData get darkTheme => buildTheme(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryDark,
      onPrimary: AppColors.onPrimaryDark,
      surface: AppColors.backgroundDark,
      onSurface: AppColors.onBackgroundDark,
      surfaceContainerLow: Color(0xFF11151E),
      surfaceContainer: Color(0xFF161B26),
      surfaceContainerHigh: Color(0xFF1E2433),
      outline: Color(0xFF283042),
      outlineVariant: Color(0xFF1F2636),
    ),
    brandColors: const BrandColors(
      dark: Color(0xFFF8FAFC),
      mid: Color(0xFF818CF8),
      subtle: Color(0xFF181D29),
      accent: Color(0xFFA5B4FC),
      debt: Color(0xFFFF5252),      // Neon Debt Red
      progress: Color(0xFF00E676),  // Neon Emerald
      milestone: Color(0xFF00E5FF), // Electric Cyan
      surfaceCard: Color(0xFF131823),
    ),
  );

  /// Builds a cohesive [ThemeData] allowing custom typography configuration
  /// (e.g. from Google Fonts or local TTF assets).
  static ThemeData buildTheme({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required BrandColors brandColors,
    AppTypography typography = const AppTypography.fallback(),
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: typography.toTextTheme(defaultColor: colorScheme.onSurface),
      extensions: [brandColors, typography],
    );
  }
}
