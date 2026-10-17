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
      dark: Color(0xFF26215C),
      mid: Color(0xFF534AB7),
      subtle: Color(0xFFEEEDFE),
      accent: Color(0xFFAFA9EC),
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
    ),
    brandColors: const BrandColors(
      dark: Color(0xFFEEEDFE),
      mid: Color(0xFFAFA9EC),
      subtle: Color(0xFF26215C),
      accent: Color(0xFF534AB7),
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
