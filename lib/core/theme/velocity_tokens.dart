import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens specified in Velocity Redesign.
///
/// Implemented as a [ThemeExtension] to provide type-safe, theme-adaptive
/// tokens across light and dark modes with zero magic numbers or hardcoded colors.
class VelocityTokens extends ThemeExtension<VelocityTokens> {
  final Color bg;
  final Color surface;
  final Color ink;
  final Color mute;
  final Color line;
  final Color moneyIn;
  final Color moneyOut;
  final Color moneyOwed;
  final Color accent;
  final Color soft;
  final List<Color> chartCategories;

  const VelocityTokens({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.mute,
    required this.line,
    required this.moneyIn,
    required this.moneyOut,
    required this.moneyOwed,
    required this.accent,
    required this.soft,
    required this.chartCategories,
  });

  Color get bgColor => bg;
  Color get surfaceColor => surface;
  Color get inkColor => ink;
  Color get muteColor => mute;
  Color get lineColor => line;
  Color get inColor => moneyIn;
  Color get outColor => moneyOut;
  Color get owedColor => moneyOwed;
  Color get accentColor => accent;
  Color get softColor => soft;

  /// Light theme tokens as per design spec:
  /// --bg #F3F1EC / --surface #FFFFFF / --ink #16211E / --mute #66726E / --line #DDD9CF
  /// --in #0F7B5F / --out #B8432F / --owed #B27A12 / --accent #0F7B5F / --soft #E6EFEA
  static const VelocityTokens light = VelocityTokens(
    bg: Color(0xFFF3F1EC),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF16211E),
    mute: Color(0xFF66726E),
    line: Color(0xFFDDD9CF),
    moneyIn: Color(0xFF0F7B5F),
    moneyOut: Color(0xFFB8432F),
    moneyOwed: Color(0xFFB27A12),
    accent: Color(0xFF0F7B5F),
    soft: Color(0xFFE6EFEA),
    chartCategories: [
      Color(0xFFE0674D),
      Color(0xFFE5A93A),
      Color(0xFF2FB98D),
      Color(0xFF5E8BD6),
      Color(0xFFA97BC4),
      Color(0xFF8FA84A),
    ],
  );

  /// Dark theme tokens as per design spec:
  /// --bg #0B101B / --surface #131B2A / --ink #E8EEF0 / --mute #8A98A6 / --line #223045
  /// --in #3DD6A3 / --out #FF8A6B / --owed #F2B84B / --accent #3DD6A3 / --soft #12261F
  static const VelocityTokens dark = VelocityTokens(
    bg: Color(0xFF0B101B),
    surface: Color(0xFF131B2A),
    ink: Color(0xFFE8EEF0),
    mute: Color(0xFF8A98A6),
    line: Color(0xFF223045),
    moneyIn: Color(0xFF3DD6A3),
    moneyOut: Color(0xFFFF8A6B),
    moneyOwed: Color(0xFFF2B84B),
    accent: Color(0xFF3DD6A3),
    soft: Color(0xFF12261F),
    chartCategories: [
      Color(0xFFE0674D),
      Color(0xFFE5A93A),
      Color(0xFF2FB98D),
      Color(0xFF5E8BD6),
      Color(0xFFA97BC4),
      Color(0xFF8FA84A),
    ],
  );

  /// Typography helper for headings and money figures using Bricolage Grotesque
  /// with strict tight letter-spacing (-0.02em).
  TextStyle bricolage({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.bricolageGrotesque(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: -0.02 * fontSize,
      color: color ?? ink,
      height: height,
    );
  }

  /// Typography helper for body and metadata using Figtree.
  TextStyle figtree({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height = 1.5,
  }) {
    return GoogleFonts.figtree(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? ink,
      height: height,
    );
  }

  @override
  VelocityTokens copyWith({
    Color? bg,
    Color? surface,
    Color? ink,
    Color? mute,
    Color? line,
    Color? moneyIn,
    Color? moneyOut,
    Color? moneyOwed,
    Color? accent,
    Color? soft,
    List<Color>? chartCategories,
  }) {
    return VelocityTokens(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      ink: ink ?? this.ink,
      mute: mute ?? this.mute,
      line: line ?? this.line,
      moneyIn: moneyIn ?? this.moneyIn,
      moneyOut: moneyOut ?? this.moneyOut,
      moneyOwed: moneyOwed ?? this.moneyOwed,
      accent: accent ?? this.accent,
      soft: soft ?? this.soft,
      chartCategories: chartCategories ?? this.chartCategories,
    );
  }

  @override
  VelocityTokens lerp(ThemeExtension<VelocityTokens>? other, double t) {
    if (other is! VelocityTokens) return this;
    return VelocityTokens(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      mute: Color.lerp(mute, other.mute, t)!,
      line: Color.lerp(line, other.line, t)!,
      moneyIn: Color.lerp(moneyIn, other.moneyIn, t)!,
      moneyOut: Color.lerp(moneyOut, other.moneyOut, t)!,
      moneyOwed: Color.lerp(moneyOwed, other.moneyOwed, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      chartCategories: [
        for (int i = 0; i < chartCategories.length; i++)
          Color.lerp(chartCategories[i], other.chartCategories[i], t)!,
      ],
    );
  }
}

/// Convenience extension to easily access [VelocityTokens] on any [BuildContext].
extension VelocityTokensBuildContext on BuildContext {
  VelocityTokens get tokens =>
      Theme.of(this).extension<VelocityTokens>() ?? VelocityTokens.light;
}
