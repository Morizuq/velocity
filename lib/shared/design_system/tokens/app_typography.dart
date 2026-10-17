import 'package:flutter/material.dart';
import 'app_font_weight.dart';
import 'app_letter_spacing.dart';
import 'app_line_height.dart';

/// A functional resolver that applies a font family or dynamic font (such as Google Fonts)
/// to a base [TextStyle].
typedef TypographyFontResolver = TextStyle Function(TextStyle baseStyle);

/// Application typography design tokens and semantic text style hierarchy.
///
/// Implemented as a [ThemeExtension] to allow dynamic runtime configuration
/// (e.g. Google Fonts, custom TTF/OTF asset fonts, or system fallbacks) while
/// ensuring immutable, testable, and theme-adaptive typographic styling.
class AppTypography extends ThemeExtension<AppTypography> {
  /// Major heading or screen-level title style (e.g. 32px, bold).
  final TextStyle largeTitle;

  /// Secondary heading or section-level title style (e.g. 24px, semi-bold).
  final TextStyle title;

  /// Primary body copy style for paragraphs and general content (e.g. 16px, regular).
  final TextStyle body;

  /// Interactive label style for buttons, chips, and actions (e.g. 14px, medium).
  final TextStyle button;

  /// Secondary metadata or auxiliary caption style (e.g. 12px, regular).
  final TextStyle caption;

  /// Creates an explicit typography set.
  const AppTypography({
    required this.largeTitle,
    required this.title,
    required this.body,
    required this.button,
    required this.caption,
  });

  /// Default compile-time fallback using system font tokens.
  const AppTypography.fallback()
    : largeTitle = const TextStyle(
        fontSize: 32,
        fontWeight: AppFontWeight.bold,
        letterSpacing: -0.5,
        height: AppLineHeight.heading,
      ),
      title = const TextStyle(
        fontSize: 24,
        fontWeight: AppFontWeight.semiBold,
        letterSpacing: -0.25,
        height: AppLineHeight.heading,
      ),
      body = const TextStyle(
        fontSize: 16,
        fontWeight: AppFontWeight.regular,
        letterSpacing: 0.25,
        height: AppLineHeight.body,
      ),
      button = const TextStyle(
        fontSize: 14,
        fontWeight: AppFontWeight.medium,
        letterSpacing: AppLetterSpacing.label,
      ),
      caption = const TextStyle(
        fontSize: 12,
        fontWeight: AppFontWeight.regular,
        letterSpacing: 0.25,
        height: 1.4,
      );

  /// Factory to construct typography backed by a local TTF/OTF font family
  /// registered in `pubspec.yaml`.
  ///
  /// ```dart
  /// final typography = AppTypography.fromFontFamily('Inter');
  /// ```
  factory AppTypography.fromFontFamily(String fontFamily, {String? package}) {
    TextStyle applyFamily(TextStyle base) =>
        base.copyWith(fontFamily: fontFamily, package: package);

    const fallback = AppTypography.fallback();
    return AppTypography(
      largeTitle: applyFamily(fallback.largeTitle),
      title: applyFamily(fallback.title),
      body: applyFamily(fallback.body),
      button: applyFamily(fallback.button),
      caption: applyFamily(fallback.caption),
    );
  }

  /// Factory to construct typography dynamically using a font resolver function,
  /// such as from the `google_fonts` package.
  ///
  /// This decouples the design tokens from any compile-time dependency on `google_fonts`.
  ///
  /// ```dart
  /// import 'package:google_fonts/google_fonts.dart';
  ///
  /// final typography = AppTypography.fromFontResolver(
  ///   (style) => GoogleFonts.inter(textStyle: style),
  /// );
  /// ```
  factory AppTypography.fromFontResolver(TypographyFontResolver resolver) {
    const fallback = AppTypography.fallback();
    return AppTypography(
      largeTitle: resolver(fallback.largeTitle),
      title: resolver(fallback.title),
      body: resolver(fallback.body),
      button: resolver(fallback.button),
      caption: resolver(fallback.caption),
    );
  }

  /// Standard compile-time reference for non-contextual or test fallbacks.
  static const AppTypography standard = AppTypography.fallback();

  /// Converts this custom token set into Flutter's native Material 3 [TextTheme].
  ///
  /// This ensures built-in Material components (e.g. AppBar, ListTile, Dialog)
  /// automatically adopt the configured font family and scale.
  TextTheme toTextTheme({Color? defaultColor}) {
    TextStyle colorize(TextStyle style) =>
        defaultColor != null ? style.copyWith(color: defaultColor) : style;

    return TextTheme(
      headlineLarge: colorize(largeTitle),
      headlineMedium: colorize(largeTitle.copyWith(fontSize: 28)),
      titleLarge: colorize(title),
      titleMedium: colorize(title.copyWith(fontSize: 18)),
      bodyLarge: colorize(body),
      bodyMedium: colorize(body.copyWith(fontSize: 14)),
      bodySmall: colorize(caption),
      labelLarge: colorize(button),
    );
  }

  @override
  AppTypography copyWith({
    TextStyle? largeTitle,
    TextStyle? title,
    TextStyle? body,
    TextStyle? button,
    TextStyle? caption,
  }) {
    return AppTypography(
      largeTitle: largeTitle ?? this.largeTitle,
      title: title ?? this.title,
      body: body ?? this.body,
      button: button ?? this.button,
      caption: caption ?? this.caption,
    );
  }

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) return this;
    return AppTypography(
      largeTitle: TextStyle.lerp(largeTitle, other.largeTitle, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      button: TextStyle.lerp(button, other.button, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
    );
  }

  /// Convenience accessor to retrieve [AppTypography] from the nearest [Theme].
  static AppTypography of(BuildContext context) {
    return Theme.of(context).extension<AppTypography>() ?? standard;
  }
}

/// BuildContext extension for concise typography access.
extension AppTypographyBuildContext on BuildContext {
  /// Resolves the current theme's typography tokens from the widget tree.
  AppTypography get appTypography => AppTypography.of(this);
}
