import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/design_system/tokens/app_border_radius.dart';
import '../../shared/design_system/tokens/brand_colors.dart';
import 'velocity_tokens.dart';

/// Central theme provider orchestrating Material 3 [ThemeData],
/// color schemes, typography presets, and custom theme extensions.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _buildTheme(VelocityTokens.light, Brightness.light);

  static ThemeData get darkTheme => _buildTheme(VelocityTokens.dark, Brightness.dark);

  static ThemeData _buildTheme(VelocityTokens tokens, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: tokens.accent,
      onPrimary: isDark ? const Color(0xFF0B101B) : const Color(0xFFFFFFFF),
      secondary: tokens.moneyOwed,
      onSecondary: isDark ? const Color(0xFF0B101B) : const Color(0xFFFFFFFF),
      surface: tokens.bg,
      onSurface: tokens.ink,
      surfaceContainer: tokens.surface,
      surfaceContainerHigh: tokens.soft,
      outline: tokens.line,
      outlineVariant: tokens.line,
      error: tokens.moneyOut,
      onError: Colors.white,
    );

    final textTheme = TextTheme(
      displayLarge: GoogleFonts.bricolageGrotesque(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 48,
        color: tokens.ink,
        height: 1.05,
      ),
      headlineLarge: GoogleFonts.bricolageGrotesque(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 26,
        color: tokens.ink,
        height: 1.15,
      ),
      headlineMedium: GoogleFonts.bricolageGrotesque(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 22,
        color: tokens.ink,
        height: 1.2,
      ),
      titleLarge: GoogleFonts.bricolageGrotesque(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.02 * 20,
        color: tokens.ink,
        height: 1.25,
      ),
      titleMedium: GoogleFonts.bricolageGrotesque(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.02 * 16,
        color: tokens.ink,
        height: 1.3,
      ),
      titleSmall: GoogleFonts.bricolageGrotesque(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.02 * 14,
        color: tokens.ink,
        height: 1.3,
      ),
      bodyLarge: GoogleFonts.figtree(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: tokens.ink,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.figtree(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: tokens.mute,
        height: 1.45,
      ),
      bodySmall: GoogleFonts.figtree(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: tokens.mute,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.figtree(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: tokens.ink,
        height: 1.4,
      ),
      labelMedium: GoogleFonts.figtree(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: tokens.mute,
        height: 1.35,
      ),
      labelSmall: GoogleFonts.figtree(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: tokens.mute,
        height: 1.3,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.bg,
      dividerColor: tokens.line,
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.allCard,
          side: BorderSide(color: tokens.line, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.surface,
        elevation: 0,
        height: 64,
        indicatorColor: tokens.soft,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: tokens.accent, size: 22);
          }
          return IconThemeData(color: tokens.mute, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.figtree(
              color: tokens.accent,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            );
          }
          return GoogleFonts.figtree(
            color: tokens.mute,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        border: OutlineInputBorder(
          borderRadius: AppBorderRadius.allInput,
          borderSide: BorderSide(color: tokens.line, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.allInput,
          borderSide: BorderSide(color: tokens.line, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.allInput,
          borderSide: BorderSide(color: tokens.accent, width: 2),
        ),
        hintStyle: GoogleFonts.figtree(color: tokens.mute, fontSize: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.accent,
          foregroundColor: tokens.bg,
          shape: const RoundedRectangleBorder(borderRadius: AppBorderRadius.allButton),
          textStyle: GoogleFonts.figtree(fontSize: 14, fontWeight: FontWeight.w600),
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.mute,
          side: BorderSide(color: tokens.line, width: 1),
          shape: const RoundedRectangleBorder(borderRadius: AppBorderRadius.allButton),
          textStyle: GoogleFonts.figtree(fontSize: 14, fontWeight: FontWeight.w500),
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          elevation: 0,
        ),
      ),
      textTheme: textTheme,
      extensions: [
        tokens,
        BrandColors.fromTokens(tokens),
      ],
    );
  }
}
