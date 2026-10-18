import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/cards/velocity_empty_state_card.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../domain/entities/debt_entity.dart';
import '../controllers/clearance_controller.dart';
import 'add_debt_dialog.dart';
import 'clearance_filter_bar.dart';
import 'debt_card.dart';

/// Section widget rendering the Clearance Bucket list with drag-and-drop reordering,
/// due date tracking, and dynamic status/sort filters.
class ClearanceBucketSection extends ConsumerStatefulWidget {
  const ClearanceBucketSection({super.key});

  @override
  ConsumerState<ClearanceBucketSection> createState() =>
      _ClearanceBucketSectionState();
}

class _ClearanceBucketSectionState
    extends ConsumerState<ClearanceBucketSection> {
  DebtFilterStatus _filter = DebtFilterStatus.all;
  DebtSortOption _sort = DebtSortOption.custom;

  void _showAddDebtDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AddDebtDialog(
        onAddConfirmed: (creditor, total, paid, dueDate) {
          ref
              .read(clearanceControllerProvider.notifier)
              .addDebt(
                creditor: creditor,
                totalOwed: total,
                initialPaid: paid,
                dueDate: dueDate,
              );
        },
      ),
    );
  }

  List<DebtEntity> _filterAndSort(List<DebtEntity> raw) {
    var list = raw.where((d) {
      switch (_filter) {
        case DebtFilterStatus.all:
          return true;
        case DebtFilterStatus.pending:
          return !d.isCleared;
        case DebtFilterStatus.dueSoon:
          return d.isDueSoon || d.isOverdue;
        case DebtFilterStatus.cleared:
          return d.isCleared;
      }
    }).toList();

    switch (_sort) {
      case DebtSortOption.custom:
        // Preserves manual drag-and-drop order
        break;
      case DebtSortOption.dueDate:
        list.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case DebtSortOption.highestBalance:
        list.sort((a, b) => b.remainingAmount.compareTo(a.remainingAmount));
        break;
      case DebtSortOption.lowestBalance:
        list.sort((a, b) => a.remainingAmount.compareTo(b.remainingAmount));
        break;
      case DebtSortOption.creditorName:
        list.sort((a, b) =>
            a.creditor.toLowerCase().compareTo(b.creditor.toLowerCase()));
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final debts = ref.watch(clearanceControllerProvider);
    final clearanceNotifier = ref.read(clearanceControllerProvider.notifier);
    final dashboardNotifier = ref.read(dashboardControllerProvider.notifier);

    final isCustomDraggable =
        _sort == DebtSortOption.custom && _filter == DebtFilterStatus.all;
    final displayedDebts = _filterAndSort(debts);

    final pendingCount = debts.where((d) => !d.isCleared).length;
    final dueSoonCount = debts.where((d) => d.isDueSoon || d.isOverdue).length;
    final clearedCount = debts.where((d) => d.isCleared).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The Clearance Bucket',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: AppFontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.vXXS,
                  Text(
                    '$clearedCount of ${debts.length} cleared accounts',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AppSpacing.hS,
            FilledButton.tonalIcon(
              onPressed: () => _showAddDebtDialog(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Debt', style: TextStyle(fontSize: 12)),
              style: FilledButton.styleFrom(
                backgroundColor: brandColors.subtle,
                foregroundColor: brandColors.debt,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppBorderRadius.pill,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: AppSpacing.xs,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.vM,

        // Delegated Filter and Sort Control Bar
        ClearanceFilterBar(
          currentFilter: _filter,
          currentSort: _sort,
          totalCount: debts.length,
          pendingCount: pendingCount,
          dueSoonCount: dueSoonCount,
          clearedCount: clearedCount,
          onFilterChanged: (f) => setState(() => _filter = f),
          onSortChanged: (s) => setState(() => _sort = s),
        ),
        AppSpacing.vM,

        if (debts.isEmpty)
          VelocityEmptyStateCard(
            icon: Icons.verified_user_rounded,
            iconColor: brandColors.progress,
            badgeLabel: 'CLEARANCE ZERO',
            badgeColor: brandColors.progress,
            title: 'Clearance Bucket is Clean',
            description:
                'No pending debts or active liabilities. Log any loans, IOUs, or credit balances to start monitoring your burn-down trajectory.',
            actionLabel: 'Log First Debt Account',
            onAction: () => _showAddDebtDialog(context),
          )
        else if (displayedDebts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
            child: Center(
              child: Text(
                'No accounts match the active filter.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.6),
                ),
              ),
            ),
          )
        else if (isCustomDraggable)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            proxyDecorator: (child, index, animation) => Material(
              elevation: 8,
              color: Colors.transparent,
              shadowColor: Colors.black.withValues(alpha: 0.4),
              borderRadius: AppBorderRadius.allL,
              child: child,
            ),
            itemCount: displayedDebts.length,
            onReorderItem: clearanceNotifier.reorder,
            itemBuilder: (context, index) {
              final debt = displayedDebts[index];
              return Padding(
                key: ValueKey(debt.id),
                padding: const EdgeInsets.only(bottom: AppSpacing.m),
                child: DebtCard(
                  debt: debt,
                  dragHandle: ReorderableDragStartListener(
                    index: index,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.grab,
                      child: Tooltip(
                        message: 'Drag to reorder',
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.05),
                            borderRadius: AppBorderRadius.allS,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.drag_indicator_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  onLogPayment: (amount) {
                    clearanceNotifier.logPayment(debt.id, amount);
                    dashboardNotifier.deductCash(amount);
                  },
                  onToggleCleared: () =>
                      clearanceNotifier.toggleCleared(debt.id),
                  onDelete: () => clearanceNotifier.deleteDebt(debt.id),
                ),
              );
            },
          )
        else
          Column(
            children: [
              for (final debt in displayedDebts)
                Padding(
                  key: ValueKey(debt.id),
                  padding: const EdgeInsets.only(bottom: AppSpacing.m),
                  child: DebtCard(
                    debt: debt,
                    onLogPayment: (amount) {
                      clearanceNotifier.logPayment(debt.id, amount);
                      dashboardNotifier.deductCash(amount);
                    },
                    onToggleCleared: () =>
                        clearanceNotifier.toggleCleared(debt.id),
                    onDelete: () => clearanceNotifier.deleteDebt(debt.id),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
