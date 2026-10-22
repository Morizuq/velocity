import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/design_system/buttons/velocity_pill_filter.dart';
import '../../../shared/design_system/cards/velocity_empty_state_card.dart';
import '../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../shared/design_system/tokens/app_responsive.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/design_system/tokens/brand_colors.dart';
import '../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../dashboard/presentation/widgets/velocity_metric_card.dart';
import '../domain/entities/receivable_type.dart';
import 'controllers/receivables_controller.dart';
import 'widgets/add_receivable_dialog.dart';
import 'widgets/receivable_card.dart';

/// Full-screen dedicated workspace for managing all receivables,
/// freelance client invoices, personal loans, and settlement histories.
class ReceivablesPage extends ConsumerStatefulWidget {
  const ReceivablesPage({super.key});

  @override
  ConsumerState<ReceivablesPage> createState() => _ReceivablesPageState();
}

class _ReceivablesPageState extends ConsumerState<ReceivablesPage> {
  int _selectedFilterIndex = 0;

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AddReceivableDialog(
        onAddConfirmed: ({
          required debtor,
          required totalAmount,
          required initialReceived,
          required type,
          description,
          dueDate,
          invoiceNumber,
          notes,
        }) {
          ref
              .read(receivablesControllerProvider.notifier)
              .addReceivable(
                debtor: debtor,
                description: description,
                totalAmount: totalAmount,
                initialReceived: initialReceived,
                type: type,
                dueDate: dueDate,
                invoiceNumber: invoiceNumber,
                notes: notes,
              );
          if (initialReceived > 0) {
            ref
                .read(dashboardControllerProvider.notifier)
                .addIncome(initialReceived);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final items = ref.watch(receivablesControllerProvider);
    final totalOutstanding = ref.watch(totalReceivablesProvider);
    final totalCollected = ref.watch(totalReceivedProvider);
    final totalFaceValue = ref.watch(totalOriginalReceivablesProvider);
    final receivablesNotifier = ref.read(
      receivablesControllerProvider.notifier,
    );
    final dashboardNotifier = ref.read(dashboardControllerProvider.notifier);

    final pendingCount = items.where((i) => !i.isSettled).length;
    final settledCount = items.where((i) => i.isSettled).length;

    // Filter items based on selected tab
    final filteredItems = items.where((item) {
      switch (_selectedFilterIndex) {
        case 1:
          return item.type == ReceivableType.freelanceInvoice &&
              !item.isSettled;
        case 2:
          return item.type == ReceivableType.personalLoan && !item.isSettled;
        case 3:
          return item.type == ReceivableType.reimbursement && !item.isSettled;
        case 4:
          return item.isSettled;
        default:
          return !item.isSettled; // Default: All active
      }
    }).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.responsive<double>(
              mobile: AppSpacing.m,
              tablet: AppSpacing.xl,
              desktop: AppSpacing.xxl,
            ),
            vertical: AppSpacing.l,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receivables Hub',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: AppFontWeight.bold,
                          ),
                        ),
                        AppSpacing.vXXS,
                        Text(
                          'Track freelance invoices, personal loans, and incoming cash settlements.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.hM,
                  FilledButton.icon(
                    onPressed: () => _showAddDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Claim'),
                    style: FilledButton.styleFrom(
                      backgroundColor: brandColors.receivable,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.l,
                        vertical: AppSpacing.m,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppBorderRadius.pill,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.vL,

              // Top Metric KPI Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 800;
                  final outstandingCard = VelocityMetricCard(
                    title: 'Pending Inflows',
                    value: FinancialNumberFormatter.format(totalOutstanding),
                    subtitle: '$pendingCount Active Accounts',
                    icon: Icons.hourglass_top_rounded,
                    accentColor: brandColors.receivable,
                  );

                  final collectedCard = VelocityMetricCard(
                    title: 'Total Collected',
                    value: FinancialNumberFormatter.format(totalCollected),
                    subtitle: '$settledCount Settled Claims',
                    icon: Icons.check_circle_rounded,
                    accentColor: brandColors.progress,
                  );

                  final faceValueCard = VelocityMetricCard(
                    title: 'Total Face Value',
                    value: FinancialNumberFormatter.format(totalFaceValue),
                    subtitle: '${items.length} Total Registered Claims',
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: brandColors.mid,
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: outstandingCard),
                        AppSpacing.hM,
                        Expanded(child: collectedCard),
                        AppSpacing.hM,
                        Expanded(child: faceValueCard),
                      ],
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      outstandingCard,
                      AppSpacing.vM,
                      collectedCard,
                      AppSpacing.vM,
                      faceValueCard,
                    ],
                  );
                },
              ),
              AppSpacing.vL,

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(0, 'Active All ($pendingCount)'),
                    AppSpacing.hS,
                    _buildFilterChip(1, 'Invoices'),
                    AppSpacing.hS,
                    _buildFilterChip(2, 'Loans Lent'),
                    AppSpacing.hS,
                    _buildFilterChip(3, 'Reimbursements'),
                    AppSpacing.hS,
                    _buildFilterChip(4, 'Settled ($settledCount)'),
                  ],
                ),
              ),
              AppSpacing.vL,

              // Receivables List or Empty State
              if (filteredItems.isEmpty)
                VelocityEmptyStateCard(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: brandColors.receivable,
                  badgeLabel: 'NO CLAIMS',
                  badgeColor: brandColors.receivable,
                  title: 'No Claims in this View',
                  description:
                      'No receivables match the active filter. Record a freelance invoice, personal loan, or expense reimbursement to get started.',
                  actionLabel: 'Add Receivable Claim',
                  onAction: () => _showAddDialog(context),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: filteredItems.length,
                  onReorder: (oldIndex, newIndex) {
                    final movedItem = filteredItems[oldIndex];
                    final fullOldIndex = items.indexOf(movedItem);
                    final fullNewIndex = newIndex < filteredItems.length
                        ? items.indexOf(filteredItems[newIndex])
                        : items.length;
                    receivablesNotifier.reorderReceivables(
                      fullOldIndex,
                      fullNewIndex,
                    );
                  },
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return Padding(
                      key: ValueKey(item.id),
                      padding: const EdgeInsets.only(bottom: AppSpacing.m),
                      child: ReceivableCard(
                        receivable: item,
                        dragHandle: ReorderableDragStartListener(
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.xs),
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                        onLogPayment: (amount) {
                          receivablesNotifier.logPayment(item.id, amount);
                          dashboardNotifier.addIncome(amount);
                        },
                        onToggleSettled: () =>
                            receivablesNotifier.toggleSettled(item.id),
                        onDelete: () =>
                            receivablesNotifier.deleteReceivable(item.id),
                      ),
                    );
                  },
                ),
              AppSpacing.vXXL,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    final brandColors = context.brandColors;

    return VelocityPillFilter(
      label: label,
      isSelected: isSelected,
      activeColor: brandColors.receivable,
      onTap: () => setState(() => _selectedFilterIndex = index),
    );
  }
}
