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

/// Workspace section widget rendering the full Clearance Bucket liability hub.
/// Features interactive status filters, sorting, drag-and-drop custom reordering,
/// and a sunken collapsible archive partition for completed/settled debts.
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
  bool _isSettledExpanded = false;

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

    final displayedDebts = _filterAndSort(debts);
    final isCustomDraggable =
        _sort == DebtSortOption.custom && _filter == DebtFilterStatus.all;

    // Partition displayed items into active priority and sunken settled accounts
    final active = displayedDebts.where((d) => !d.isCleared).toList();
    final settled = displayedDebts.where((d) => d.isCleared).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClearanceFilterBar(
          currentFilter: _filter,
          currentSort: _sort,
          totalCount: debts.length,
          pendingCount: debts.where((d) => !d.isCleared).length,
          dueSoonCount:
              debts.where((d) => d.isDueSoon || d.isOverdue).length,
          clearedCount: debts.where((d) => d.isCleared).length,
          onFilterChanged: (filter) => setState(() => _filter = filter),
          onSortChanged: (sort) => setState(() => _sort = sort),
        ),
        AppSpacing.vL,

        if (debts.isEmpty)
          VelocityEmptyStateCard(
            icon: Icons.verified_user_rounded,
            iconColor: brandColors.progress,
            badgeLabel: 'CLEARANCE ZERO',
            badgeColor: brandColors.progress,
            title: 'Clearance Bucket is Clean',
            description:
                'No pending debts or active liabilities. Log any loans or credit balances to start monitoring your burn-down trajectory.',
            actionLabel: 'Log First Debt Account',
            onAction: () => _showAddDebtDialog(context),
          )
        else if (displayedDebts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
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
        else ...[
          // Active accounts (Reorderable in custom mode)
          if (isCustomDraggable)
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
              itemCount: active.length,
              onReorderItem: clearanceNotifier.reorder,
              itemBuilder: (context, index) {
                final debt = active[index];
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
                for (final debt in active)
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

          // Settled Accounts Sunk Below
          if (settled.isNotEmpty) ...[
            AppSpacing.vL,
            InkWell(
              onTap: () =>
                  setState(() => _isSettledExpanded = !_isSettledExpanded),
              borderRadius: AppBorderRadius.allM,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: brandColors.progress.withValues(alpha: 0.06),
                  borderRadius: AppBorderRadius.allM,
                  border: Border.all(
                    color: brandColors.progress.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: brandColors.progress,
                    ),
                    AppSpacing.hS,
                    Expanded(
                      child: Text(
                        'Settled Accounts (${settled.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: AppFontWeight.bold,
                          color: brandColors.progress,
                        ),
                      ),
                    ),
                    Icon(
                      _isSettledExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: brandColors.progress,
                    ),
                  ],
                ),
              ),
            ),
            if (_isSettledExpanded) ...[
              AppSpacing.vM,
              for (final debt in settled)
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
          ],
        ],
      ],
    );
  }
}
