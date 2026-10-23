import 'package:flutter/material.dart';
import '../../../core/theme/velocity_tokens.dart';
import '../tokens/app_border_radius.dart';
import '../tokens/app_spacing.dart';

/// Semantic variants for buttons matching the Velocity Redesign specification.
enum VelocityButtonVariant {
  /// Primary filled button with `--accent` background and `--bg` text (e.g. `.go` form action).
  primary,

  /// Soft accent button with `--soft` background and `--accent` text (e.g. `.acts button`).
  soft,

  /// Ghost button with 1px `--line` border, transparent background, and `--mute` text (e.g. `.ghost`).
  ghost,

  /// Destructive danger button with `--out` text and border (e.g. Clear All Data / Delete).
  danger,

  /// Subtle text button with no border and `--mute` text (e.g. `.del` remove item).
  subtle,
}

/// A token-driven, reusable button component adhering to the Velocity design system.
///
/// Ensures consistent 8px corner radii ([AppBorderRadius.allButton]),
/// semantic tokens from [VelocityTokens], and standard minimum 44px touch targets.
class VelocityButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final VelocityButtonVariant variant;
  final bool isFullWidth;
  final bool isLoading;
  final double height;
  final EdgeInsetsGeometry? padding;

  const VelocityButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.variant = VelocityButtonVariant.primary,
    this.isFullWidth = false,
    this.isLoading = false,
    this.height = 40.0,
    this.padding,
  });

  /// Factory for primary action buttons (`.go`).
  const VelocityButton.primary({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isFullWidth = false,
    this.isLoading = false,
    this.height = 40.0,
    this.padding,
  }) : variant = VelocityButtonVariant.primary;

  /// Factory for soft secondary action buttons (`.acts button`).
  const VelocityButton.soft({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isFullWidth = false,
    this.isLoading = false,
    this.height = 36.0,
    this.padding,
  }) : variant = VelocityButtonVariant.soft;

  /// Factory for ghost outlined buttons (`.ghost`).
  const VelocityButton.ghost({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isFullWidth = false,
    this.isLoading = false,
    this.height = 36.0,
    this.padding,
  }) : variant = VelocityButtonVariant.ghost;

  /// Factory for destructive danger buttons (`.danger`).
  const VelocityButton.danger({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isFullWidth = false,
    this.isLoading = false,
    this.height = 40.0,
    this.padding,
  }) : variant = VelocityButtonVariant.danger;

  /// Factory for subtle text buttons (`.del`).
  const VelocityButton.subtle({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isFullWidth = false,
    this.isLoading = false,
    this.height = 36.0,
    this.padding,
  }) : variant = VelocityButtonVariant.subtle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isEnabled = onPressed != null && !isLoading;

    // Resolve color styling based on variant and tokens
    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide;

    switch (variant) {
      case VelocityButtonVariant.primary:
        backgroundColor = isEnabled ? tokens.accentColor : tokens.accentColor.withValues(alpha: 0.5);
        foregroundColor = tokens.bgColor;
        borderSide = BorderSide.none;
        break;

      case VelocityButtonVariant.soft:
        backgroundColor = isEnabled ? tokens.softColor : tokens.softColor.withValues(alpha: 0.5);
        foregroundColor = tokens.accentColor;
        borderSide = BorderSide.none;
        break;

      case VelocityButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = isEnabled ? tokens.muteColor : tokens.muteColor.withValues(alpha: 0.5);
        borderSide = BorderSide(color: tokens.lineColor, width: 1.0);
        break;

      case VelocityButtonVariant.danger:
        backgroundColor = Colors.transparent;
        foregroundColor = isEnabled ? tokens.outColor : tokens.outColor.withValues(alpha: 0.5);
        borderSide = BorderSide(color: tokens.outColor.withValues(alpha: 0.6), width: 1.0);
        break;

      case VelocityButtonVariant.subtle:
        backgroundColor = Colors.transparent;
        foregroundColor = isEnabled ? tokens.muteColor : tokens.muteColor.withValues(alpha: 0.5);
        borderSide = BorderSide.none;
        break;
    }

    final content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          AppSpacing.hXS,
        ] else if (icon != null) ...[
          Icon(icon, size: 16, color: foregroundColor),
          AppSpacing.hXS,
        ],
        Text(
          label,
          style: tokens.figtree(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: foregroundColor,
          ),
        ),
      ],
    );

    final resolvedPadding = padding ??
        EdgeInsets.symmetric(
          horizontal: variant == VelocityButtonVariant.subtle ? AppSpacing.xs : AppSpacing.m,
          vertical: AppSpacing.xs,
        );

    Widget button = Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.allButton,
        side: borderSide,
      ),
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: AppBorderRadius.allButton,
        child: Container(
          constraints: BoxConstraints(
            minHeight: height,
            minWidth: 44.0, // Minimum accessible touch target
          ),
          padding: resolvedPadding,
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );

    if (isFullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
