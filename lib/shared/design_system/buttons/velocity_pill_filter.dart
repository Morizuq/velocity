import 'package:flutter/material.dart';
import '../tokens/app_border_radius.dart';
import '../tokens/app_font_weight.dart';
import '../tokens/app_spacing.dart';
import '../tokens/brand_colors.dart';

/// Standard pill filter button used consistently across the application for tabs,
/// category filters, and modal segmented options.
class VelocityPillFilter extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? activeColor;
  final Color? badgeColor;
  final IconData? icon;

  const VelocityPillFilter({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor,
    this.badgeColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final effectiveActiveColor = activeColor ?? brandColors.accent;

    return InkWell(
      onTap: onTap,
      borderRadius: AppBorderRadius.pill,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveActiveColor
              : (badgeColor != null
                  ? badgeColor!.withValues(alpha: 0.1)
                  : theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.35)),
          borderRadius: AppBorderRadius.pill,
          border: Border.all(
            color: isSelected
                ? effectiveActiveColor
                : (badgeColor != null
                    ? badgeColor!.withValues(alpha: 0.4)
                    : theme.dividerColor.withValues(alpha: 0.18)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? Colors.white
                    : (badgeColor ?? theme.colorScheme.onSurfaceVariant),
              ),
              AppSpacing.hXXS,
            ],
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? Colors.white
                    : (badgeColor ?? theme.colorScheme.onSurfaceVariant),
                fontWeight:
                    isSelected ? AppFontWeight.bold : AppFontWeight.medium,
                fontSize: 11,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
