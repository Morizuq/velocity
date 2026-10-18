import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';

/// Tab selector for choosing operation mode in asset management dialog.
class AssetModeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const AssetModeTab({
    super.key,
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AppBorderRadius.allM,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: AppBorderRadius.allM,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: isSelected ? AppFontWeight.bold : AppFontWeight.medium,
            color: isSelected
                ? selectedColor
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Compact chip for quickly applying common capital adjustments.
class AssetQuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isHighlight;

  const AssetQuickChip({
    super.key,
    required this.label,
    required this.onTap,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;

    return InkWell(
      onTap: onTap,
      borderRadius: AppBorderRadius.pill,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s,
          vertical: AppSpacing.xxs + 2,
        ),
        decoration: BoxDecoration(
          color: isHighlight
              ? brandColors.subtle
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: AppBorderRadius.pill,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: AppFontWeight.medium,
            color: isHighlight
                ? brandColors.accent
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
