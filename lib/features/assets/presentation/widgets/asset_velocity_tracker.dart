import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_border_width.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_icon_size.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../controllers/assets_controller.dart';

/// Hero visual tracker that sits at the top of the dashboard showcasing long-term wealth assets.
class AssetVelocityTracker extends ConsumerWidget {
  const AssetVelocityTracker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final assets = ref.watch(assetsControllerProvider);
    final totalTarget = ref.watch(totalAssetTargetProvider);
    final totalSaved = ref.watch(totalAssetSavedProvider);

    final double overallProgress =
        totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            brandColors.surfaceCard,
            brandColors.subtle.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: AppBorderRadius.allXL,
        border: Border.all(
          color: brandColors.accent.withValues(alpha: 0.25),
          width: AppBorderWidth.hairline,
        ),
        boxShadow: [
          BoxShadow(
            color: brandColors.accent.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header badge & title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: brandColors.accent.withValues(alpha: 0.15),
                      borderRadius: AppBorderRadius.allM,
                    ),
                    child: Icon(
                      Icons.auto_graph_rounded,
                      color: brandColors.accent,
                      size: AppIconSize.m,
                    ),
                  ),
                  AppSpacing.hM,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Long-Term Wealth Horizon',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: AppFontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Tier 1 Asset Progression',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: brandColors.accent.withValues(alpha: 0.15),
                  borderRadius: AppBorderRadius.pill,
                  border: Border.all(
                    color: brandColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${(overallProgress * 100).round()}% OF HORIZON',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: AppFontWeight.bold,
                    color: brandColors.accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vL,

          // Large overarching progress metric
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Capital Secured',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.vXXS,
                  Text(
                    FinancialNumberFormatter.format(totalSaved),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: AppFontWeight.bold,
                      color: brandColors.progress,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Target Valuation',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.vXXS,
                  Text(
                    FinancialNumberFormatter.format(totalTarget),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: AppFontWeight.semiBold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          AppSpacing.vM,

          // Glowing overarching progress bar
          ClipRRect(
            borderRadius: AppBorderRadius.pill,
            child: LinearProgressIndicator(
              value: overallProgress,
              minHeight: 10,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(brandColors.accent),
            ),
          ),
          AppSpacing.vL,

          // Sub-item cards (Plot of Land, Mac M4)
          Wrap(
            spacing: AppSpacing.m,
            runSpacing: AppSpacing.m,
            children: assets.map((asset) {
              return Container(
                constraints: const BoxConstraints(minWidth: 260),
                padding: const EdgeInsets.all(AppSpacing.s + 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: AppBorderRadius.allM,
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      asset.title.contains('Land')
                          ? Icons.landscape_rounded
                          : Icons.laptop_mac_rounded,
                      size: AppIconSize.s,
                      color: brandColors.accent,
                    ),
                    AppSpacing.hS,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            asset.title,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: AppFontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${FinancialNumberFormatter.format(asset.currentAmount)} / ${FinancialNumberFormatter.format(asset.targetAmount)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.hS,
                    Text(
                      '${asset.progressPercentage}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: AppFontWeight.bold,
                        color: brandColors.accent,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
