import 'package:flutter/material.dart';
import '../../shared/design_system/tokens/app_typography.dart';
import '../../shared/design_system/tokens/brand_colors.dart';
import 'app_colors.dart';

/// Central theme provider orchestrating Material 3 [ThemeData],
/// color schemes, typography presets, and custom theme extensions.
class AppTheme {
  AppTheme._();

  /// Refined light theme configuration with borderless soft cards, zero purple.
  static ThemeData get lightTheme => buildTheme(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      surface: AppColors.background,
      onSurface: AppColors.onBackground,
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFFFFFFF),
      surfaceContainer: Color(0xFFF1F5F9),
      surfaceContainerHigh: Color(0xFFE2E8F0),
      outlineVariant: Colors.transparent, // Avoid wireframe borders
    ),
    brandColors: const BrandColors(
      dark: Color(0xFF0F172A),
      mid: Color(0xFF0284C7),
      subtle: Color(0xFFF0F4F8),
      accent: Color(0xFF0284C7),
      debt: Color(0xFFE11D48),
      progress: Color(0xFF059669),
      milestone: Color(0xFF0284C7),
      surfaceCard: Color(0xFFFFFFFF),
    ),
  );

  /// Default sleek dark theme with obsidian depth and neon visual hierarchy, zero purple.
  static ThemeData get darkTheme => buildTheme(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryDark,
      onPrimary: AppColors.onPrimaryDark,
      surface: AppColors.backgroundDark,
      onSurface: AppColors.onBackgroundDark,
      surfaceContainerLowest: Color(0xFF0D121B),
      surfaceContainerLow: Color(0xFF111723),
      surfaceContainer: Color(0xFF151D2C),
      surfaceContainerHigh: Color(0xFF1B2436),
      outlineVariant: Colors.transparent, // Avoid wireframe borders
    ),
    brandColors: const BrandColors(
      dark: Color(0xFFF8FAFC),
      mid: Color(0xFF38BDF8),
      subtle: Color(0xFF131A26),
      accent: Color(0xFF38BDF8),
      debt: Color(0xFFFF5252),      // Neon Debt Red
      progress: Color(0xFF00E676),  // Neon Emerald
      milestone: Color(0xFF00E5FF), // Electric Cyan
      surfaceCard: Color(0xFF111724), // Sleek obsidian card surface
    ),
  );

  /// Builds a cohesive [ThemeData] allowing custom typography configuration.
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
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      textTheme: typography.toTextTheme(defaultColor: colorScheme.onSurface),
      extensions: [brandColors, typography],
    );
  }
}
