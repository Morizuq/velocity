import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_icon_size.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../domain/entities/asset_entity.dart';

/// Interactive sub-item card representing an individual wealth goal (e.g. Land, Mac).
/// Uses [ThemeData] tokens and synchronized animation timing to eliminate color flash.
class AssetGoalTile extends StatelessWidget {
  final AssetEntity asset;
  final VoidCallback onTap;
  final Widget? dragHandle;

  const AssetGoalTile({
    super.key,
    required this.asset,
    required this.onTap,
    this.dragHandle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final isCompleted = asset.isCompleted;
    final badgeColor = isCompleted ? brandColors.progress : brandColors.accent;

    return Material(
      color: Colors.transparent,
      borderRadius: AppBorderRadius.allM,
      child: InkWell(
        borderRadius: AppBorderRadius.allM,
        onTap: onTap,
        hoverColor: brandColors.accent.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.s + 2,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: AppBorderRadius.allM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (dragHandle != null) ...[
                    dragHandle!,
                    AppSpacing.hXXS,
                  ],
                  Icon(
                    isCompleted
                        ? Icons.verified_rounded
                        : (asset.title.contains('Land')
                              ? Icons.landscape_rounded
                              : Icons.laptop_mac_rounded),
                    size: AppIconSize.s,
                    color: badgeColor,
                  ),
                  AppSpacing.hS,
                  Expanded(
                    child: Text(
                      asset.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: AppFontWeight.bold,
                      ),
                      maxLines: 2,
                    ),
                  ),
                  AppSpacing.hS,
                  Text(
                    isCompleted ? '100%' : '${asset.progressPercentage}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: AppFontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                  AppSpacing.hXS,
                  Icon(
                    Icons.tune_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ],
              ),
              AppSpacing.vXS,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 24.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${FinancialNumberFormatter.format(asset.currentAmount)} / ${FinancialNumberFormatter.format(asset.targetAmount)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isCompleted) ...[
                    AppSpacing.hS,
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: brandColors.progress.withValues(alpha: 0.15),
                        borderRadius: AppBorderRadius.pill,
                      ),
                      child: Text(
                        'ACQUIRED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: AppFontWeight.bold,
                          color: brandColors.progress,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
