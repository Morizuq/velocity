import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';

/// Available status filters for the clearance bucket accounts.
enum DebtFilterStatus {
  all,
  pending,
  dueSoon,
  cleared,
}

/// Available sorting strategies for the clearance bucket accounts.
enum DebtSortOption {
  custom,
  dueDate,
  highestBalance,
  lowestBalance,
  creditorName,
}

/// Dedicated filter and sort bar widget for the Clearance Bucket.
class ClearanceFilterBar extends StatelessWidget {
  final DebtFilterStatus currentFilter;
  final DebtSortOption currentSort;
  final int totalCount;
  final int pendingCount;
  final int dueSoonCount;
  final int clearedCount;
  final ValueChanged<DebtFilterStatus> onFilterChanged;
  final ValueChanged<DebtSortOption> onSortChanged;

  const ClearanceFilterBar({
    super.key,
    required this.currentFilter,
    required this.currentSort,
    required this.totalCount,
    required this.pendingCount,
    required this.dueSoonCount,
    required this.clearedCount,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  String _sortLabel(DebtSortOption opt) {
    switch (opt) {
      case DebtSortOption.custom:
        return 'Custom Order';
      case DebtSortOption.dueDate:
        return 'Due Date (Earliest)';
      case DebtSortOption.highestBalance:
        return 'Highest Balance';
      case DebtSortOption.lowestBalance:
        return 'Lowest Balance';
      case DebtSortOption.creditorName:
        return 'Creditor (A-Z)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All ($totalCount)',
            isSelected: currentFilter == DebtFilterStatus.all,
            onTap: () => onFilterChanged(DebtFilterStatus.all),
            theme: theme,
            brandColors: brandColors,
          ),
          AppSpacing.hXS,
          _buildFilterChip(
            label: 'Pending ($pendingCount)',
            isSelected: currentFilter == DebtFilterStatus.pending,
            onTap: () => onFilterChanged(DebtFilterStatus.pending),
            theme: theme,
            brandColors: brandColors,
          ),
          AppSpacing.hXS,
          _buildFilterChip(
            label: 'Due Soon ($dueSoonCount)',
            isSelected: currentFilter == DebtFilterStatus.dueSoon,
            badgeColor: dueSoonCount > 0 ? brandColors.debt : null,
            onTap: () => onFilterChanged(DebtFilterStatus.dueSoon),
            theme: theme,
            brandColors: brandColors,
          ),
          AppSpacing.hXS,
          _buildFilterChip(
            label: 'Cleared ($clearedCount)',
            isSelected: currentFilter == DebtFilterStatus.cleared,
            onTap: () => onFilterChanged(DebtFilterStatus.cleared),
            theme: theme,
            brandColors: brandColors,
          ),
          AppSpacing.hM,
          PopupMenuButton<DebtSortOption>(
            initialValue: currentSort,
            tooltip: 'Sort Options',
            onSelected: onSortChanged,
            shape: const RoundedRectangleBorder(
              borderRadius: AppBorderRadius.allM,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s + 2,
                vertical: AppSpacing.xs + 1,
              ),
              decoration: BoxDecoration(
                color: currentSort != DebtSortOption.custom
                    ? brandColors.debt.withValues(alpha: 0.12)
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                borderRadius: AppBorderRadius.pill,
                border: Border.all(
                  color: currentSort != DebtSortOption.custom
                      ? brandColors.debt.withValues(alpha: 0.4)
                      : theme.dividerColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sort_rounded,
                    size: 14,
                    color: currentSort != DebtSortOption.custom
                        ? brandColors.debt
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  AppSpacing.hXXS,
                  Text(
                    _sortLabel(currentSort),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: currentSort != DebtSortOption.custom
                          ? brandColors.debt
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: AppFontWeight.semiBold,
                      fontSize: 11,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down_rounded, size: 16),
                ],
              ),
            ),
            itemBuilder: (ctx) => [
              for (final opt in DebtSortOption.values)
                PopupMenuItem(
                  value: opt,
                  child: Row(
                    children: [
                      Icon(
                        opt == DebtSortOption.custom
                            ? Icons.drag_indicator_rounded
                            : (opt == DebtSortOption.dueDate
                                ? Icons.event_rounded
                                : Icons.swap_vert_rounded),
                        size: 16,
                        color: currentSort == opt ? brandColors.debt : null,
                      ),
                      AppSpacing.hS,
                      Text(
                        _sortLabel(opt),
                        style: TextStyle(
                          fontWeight: currentSort == opt
                              ? AppFontWeight.bold
                              : AppFontWeight.regular,
                          color: currentSort == opt ? brandColors.debt : null,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    required BrandColors brandColors,
    Color? badgeColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppBorderRadius.pill,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.xs + 1,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? brandColors.debt
              : (badgeColor != null
                  ? badgeColor.withValues(alpha: 0.1)
                  : theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.35)),
          borderRadius: AppBorderRadius.pill,
          border: Border.all(
            color: isSelected
                ? brandColors.debt
                : (badgeColor != null
                    ? badgeColor.withValues(alpha: 0.4)
                    : theme.dividerColor.withValues(alpha: 0.15)),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected
                ? Colors.white
                : (badgeColor ?? theme.colorScheme.onSurfaceVariant),
            fontWeight:
                isSelected ? AppFontWeight.bold : AppFontWeight.medium,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
