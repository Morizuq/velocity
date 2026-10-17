import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_icon_size.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../domain/entities/asset_entity.dart';
import '../controllers/assets_controller.dart';
import '../../../../shared/design_system/cards/velocity_empty_state_card.dart';
import 'add_asset_dialog.dart';
import 'manage_asset_dialog.dart';

/// Hero visual tracker that sits at the top of the dashboard showcasing long-term wealth assets.
class AssetVelocityTracker extends ConsumerWidget {
  const AssetVelocityTracker({super.key});

  void _showAddAssetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AddAssetDialog(
        onAddConfirmed: (title, target, initial) {
          ref
              .read(assetsControllerProvider.notifier)
              .addAsset(
                title: title,
                targetAmount: target,
                initialAmount: initial,
              );
        },
      ),
    );
  }

  void _showManageAssetDialog(
    BuildContext context,
    WidgetRef ref,
    AssetEntity asset,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => ManageAssetDialog(
        asset: asset,
        onAdjustCapital: (delta) {
          ref
              .read(assetsControllerProvider.notifier)
              .adjustCapital(asset.id, delta);
          if (delta > 0) {
            ref.read(dashboardControllerProvider.notifier).deductCash(delta);
          } else if (delta < 0) {
            ref.read(dashboardControllerProvider.notifier).addIncome(-delta);
          }
        },
        onSetExactTotal: (newTotal) {
          final diff = newTotal - asset.currentAmount;
          ref
              .read(assetsControllerProvider.notifier)
              .setAssetAmount(asset.id, newTotal);
          if (diff > 0) {
            ref.read(dashboardControllerProvider.notifier).deductCash(diff);
          } else if (diff < 0) {
            ref.read(dashboardControllerProvider.notifier).addIncome(-diff);
          }
        },
        onTogglePurchased: () {
          ref.read(assetsControllerProvider.notifier).togglePurchased(asset.id);
        },
        onDelete: () {
          ref.read(assetsControllerProvider.notifier).deleteAsset(asset.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final isDark = theme.brightness == Brightness.dark;

    final assets = ref.watch(assetsControllerProvider);
    final totalTarget = ref.watch(totalAssetTargetProvider);
    final totalSaved = ref.watch(totalAssetSavedProvider);

    final double overallProgress = totalTarget > 0
        ? (totalSaved / totalTarget).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: brandColors.surfaceCard,
        borderRadius: AppBorderRadius.allXL,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0x08000000),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header badge, title, and Add Action
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 460;
              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color: brandColors.accent.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: AppBorderRadius.allM,
                                ),
                                child: Icon(
                                  Icons.auto_graph_rounded,
                                  color: brandColors.accent,
                                  size: AppIconSize.m,
                                ),
                              ),
                              AppSpacing.hS,
                              Expanded(
                                child: Text(
                                  'Long-Term Wealth Horizon',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: AppFontWeight.bold,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.hS,
                        IconButton.filledTonal(
                          tooltip: 'Add Asset Goal',
                          onPressed: () => _showAddAssetDialog(context, ref),
                          icon: const Icon(
                            Icons.add_rounded,
                            size: AppIconSize.s,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: brandColors.subtle,
                            foregroundColor: brandColors.accent,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vXS,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Tier 1 Asset Progression',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AppSpacing.hS,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: brandColors.accent.withValues(alpha: 0.12),
                            borderRadius: AppBorderRadius.pill,
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
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
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
                        AppSpacing.hS,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Long-Term Wealth Horizon',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: AppFontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Tier 1 Asset Progression',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.hS,
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: brandColors.accent.withValues(alpha: 0.12),
                          borderRadius: AppBorderRadius.pill,
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
                      AppSpacing.hS,
                      IconButton.filledTonal(
                        tooltip: 'Add Asset Goal',
                        onPressed: () => _showAddAssetDialog(context, ref),
                        icon: const Icon(
                          Icons.add_rounded,
                          size: AppIconSize.s,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: brandColors.subtle,
                          foregroundColor: brandColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          AppSpacing.vL,

          // Large overarching progress metric
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Capital Secured',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.vXXS,
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        FinancialNumberFormatter.format(totalSaved),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: AppFontWeight.bold,
                          color: brandColors.progress,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.hM,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Target Valuation',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.vXXS,
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        FinancialNumberFormatter.format(totalTarget),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: AppFontWeight.semiBold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vM,

          // Glowing overarching progress bar
          ClipRRect(
            borderRadius: AppBorderRadius.pill,
            child: LinearProgressIndicator(
              value: overallProgress,
              minHeight: 8,
              backgroundColor: isDark
                  ? const Color(0xFF1B2333)
                  : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(brandColors.accent),
            ),
          ),
          AppSpacing.vL,

          // Sub-item cards (Plot of Land, Mac M4)
          if (assets.isEmpty)
            VelocityEmptyStateCard(
              icon: Icons.landscape_rounded,
              iconColor: brandColors.accent,
              badgeLabel: 'WEALTH HORIZON',
              badgeColor: brandColors.accent,
              title: 'No Long-Term Assets Logged',
              description:
                  'Define your premier multi-year wealth acquisition goals (e.g., Real Estate, Workstations, Capital Assets) to track your overarching net worth trajectory.',
              actionLabel: 'Define First Wealth Goal',
              onAction: () => _showAddAssetDialog(context, ref),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 600;
                final double cardWidth = isWide
                    ? (constraints.maxWidth - AppSpacing.m) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: AppSpacing.m,
                  runSpacing: AppSpacing.m,
                  children: assets.map((asset) {
                  final isCompleted = asset.isCompleted;
                  final badgeColor = isCompleted
                      ? brandColors.progress
                      : brandColors.accent;

                  return SizedBox(
                    width: cardWidth,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: AppBorderRadius.allM,
                      child: InkWell(
                        borderRadius: AppBorderRadius.allM,
                        onTap: () =>
                            _showManageAssetDialog(context, ref, asset),
                        hoverColor: brandColors.accent.withValues(alpha: 0.05),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.m,
                            vertical: AppSpacing.s + 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF161E2E)
                                : const Color(0xFFF8FAFC),
                            borderRadius: AppBorderRadius.allM,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
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
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: AppFontWeight.bold,
                                          ),
                                      maxLines: 2,
                                    ),
                                  ),
                                  AppSpacing.hS,
                                  Text(
                                    isCompleted
                                        ? '100%'
                                        : '${asset.progressPercentage}%',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          fontWeight: AppFontWeight.bold,
                                          color: badgeColor,
                                        ),
                                  ),
                                  AppSpacing.hXS,
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 14,
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ],
                              ),
                              AppSpacing.vXS,
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 24.0,
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          '${FinancialNumberFormatter.format(asset.currentAmount)} / ${FinancialNumberFormatter.format(asset.targetAmount)}',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
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
                                        color: brandColors.progress.withValues(
                                          alpha: 0.15,
                                        ),
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
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
