import 'package:flutter/material.dart';
import '../../../../core/theme/velocity_tokens.dart';

/// Legacy [ThemeExtension] mapping for brand colors, ensuring existing widgets
/// seamlessly integrate with the new Velocity design tokens.
class BrandColors extends ThemeExtension<BrandColors> {
  final Color dark;
  final Color mid;
  final Color subtle;
  final Color accent;
  final Color debt;
  final Color progress;
  final Color milestone;
  final Color receivable;
  final Color surfaceCard;

  const BrandColors({
    required this.dark,
    required this.mid,
    required this.subtle,
    required this.accent,
    required this.debt,
    required this.progress,
    required this.milestone,
    required this.receivable,
    required this.surfaceCard,
  });

  /// Factory translating directly from [VelocityTokens].
  factory BrandColors.fromTokens(VelocityTokens tokens) {
    return BrandColors(
      dark: tokens.ink,
      mid: tokens.accent,
      subtle: tokens.soft,
      accent: tokens.accent,
      debt: tokens.moneyOut,
      progress: tokens.moneyIn,
      milestone: tokens.accent,
      receivable: tokens.moneyOwed,
      surfaceCard: tokens.surface,
    );
  }

  @override
  BrandColors copyWith({
    Color? dark,
    Color? mid,
    Color? subtle,
    Color? accent,
    Color? debt,
    Color? progress,
    Color? milestone,
    Color? receivable,
    Color? surfaceCard,
  }) {
    return BrandColors(
      dark: dark ?? this.dark,
      mid: mid ?? this.mid,
      subtle: subtle ?? this.subtle,
      accent: accent ?? this.accent,
      debt: debt ?? this.debt,
      progress: progress ?? this.progress,
      milestone: milestone ?? this.milestone,
      receivable: receivable ?? this.receivable,
      surfaceCard: surfaceCard ?? this.surfaceCard,
    );
  }

  @override
  BrandColors lerp(ThemeExtension<BrandColors>? other, double t) {
    if (other is! BrandColors) return this;
    return BrandColors(
      dark: Color.lerp(dark, other.dark, t)!,
      mid: Color.lerp(mid, other.mid, t)!,
      subtle: Color.lerp(subtle, other.subtle, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      debt: Color.lerp(debt, other.debt, t)!,
      progress: Color.lerp(progress, other.progress, t)!,
      milestone: Color.lerp(milestone, other.milestone, t)!,
      receivable: Color.lerp(receivable, other.receivable, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
    );
  }
}

/// Helper extension to easily access [BrandColors] directly from the [BuildContext].
extension BrandColorsBuildContext on BuildContext {
  BrandColors get brandColors =>
      Theme.of(this).extension<BrandColors>() ??
      BrandColors.fromTokens(VelocityTokens.light);
}
