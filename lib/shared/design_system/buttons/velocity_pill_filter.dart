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
  final EdgeInsetsGeometry? padding;

  const VelocityPillFilter({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor,
    this.badgeColor,
    this.icon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final effectiveActiveColor = activeColor ?? brandColors.accent;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isBounded =
            constraints.hasBoundedWidth &&
            constraints.maxWidth != double.infinity;
        final useCompactPadding = isBounded && constraints.maxWidth < 160;

        final effectivePadding =
            padding ??
            EdgeInsets.symmetric(
              horizontal: useCompactPadding ? AppSpacing.s : AppSpacing.m,
              vertical: AppSpacing.xs + 2,
            );

        final textStyle = theme.textTheme.labelSmall?.copyWith(
          color: isSelected
              ? Colors.white
              : (badgeColor ?? theme.colorScheme.onSurfaceVariant),
          fontWeight: isSelected ? AppFontWeight.bold : AppFontWeight.medium,
          fontSize: 11,
          letterSpacing: 0.2,
        );

        final rowContent = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: isBounded
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
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
            if (isBounded)
              Flexible(
                child: Text(
                  label,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              Text(label, style: textStyle, maxLines: 1),
          ],
        );

        return InkWell(
          onTap: onTap,
          borderRadius: AppBorderRadius.pill,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: effectivePadding,
            decoration: BoxDecoration(
              color: isSelected
                  ? effectiveActiveColor
                  : (badgeColor != null
                        ? badgeColor!.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.35,
                          )),
              borderRadius: AppBorderRadius.pill,
              border: Border.all(
                color: isSelected
                    ? effectiveActiveColor
                    : (badgeColor != null
                          ? badgeColor!.withValues(alpha: 0.4)
                          : theme.dividerColor.withValues(alpha: 0.18)),
              ),
            ),
            child: isBounded ? Center(child: rowContent) : rowContent,
          ),
        );
      },
    );
  }
}
