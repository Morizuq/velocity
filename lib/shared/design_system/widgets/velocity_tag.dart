import 'package:flutter/material.dart';
import '../../../core/theme/velocity_tokens.dart';

import '../tokens/app_border_radius.dart';
import '../tokens/app_spacing.dart';

enum VelocityTagVariant {
  neutral,
  overdue,
  cleared,
  received,
  warning;

  static const VelocityTagVariant late = VelocityTagVariant.overdue;
}

/// Tag chip matching Velocity Redesign:
/// Pill-shaped ([AppBorderRadius.allPill]), 1px border, 12px text.
class VelocityTag extends StatelessWidget {
  final String label;
  final VelocityTagVariant variant;

  const VelocityTag({
    super.key,
    required this.label,
    this.variant = VelocityTagVariant.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    Color textColor;
    Color borderColor;

    switch (variant) {
      case VelocityTagVariant.overdue:
        textColor = tokens.moneyOut;
        borderColor = tokens.moneyOut;
        break;
      case VelocityTagVariant.cleared:
      case VelocityTagVariant.received:
        textColor = tokens.moneyIn;
        borderColor = tokens.moneyIn;
        break;
      case VelocityTagVariant.warning:
        textColor = tokens.moneyOwed;
        borderColor = tokens.moneyOwed;
        break;
      case VelocityTagVariant.neutral:
        textColor = tokens.mute;
        borderColor = tokens.line;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.allPill,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        label,
        style: tokens.figtree(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
          height: 1.2,
        ),
      ),
    );
  }
}
