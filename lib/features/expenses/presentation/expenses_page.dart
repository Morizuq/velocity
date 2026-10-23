import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/velocity_tokens.dart';
import '../../../shared/design_system/buttons/velocity_button.dart';
import '../../../shared/design_system/layout/velocity_scaffold.dart';
import '../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../../shared/design_system/widgets/velocity_action_row.dart';
import '../../../shared/design_system/widgets/velocity_avatar.dart';
import '../../../shared/design_system/widgets/velocity_card.dart';
import '../../../shared/design_system/widgets/velocity_inline_add.dart';
import '../../../shared/design_system/widgets/velocity_progress_bar.dart';
import '../../../shared/design_system/widgets/velocity_tag.dart';
import '../../clearance/presentation/controllers/clearance_controller.dart';
import '../domain/entities/cashflow_direction.dart';
import '../domain/entities/recurring_cashflow_entity.dart';
import 'controllers/recurring_cashflow_controller.dart';

/// Redesigned Monthly cashflow page orchestrating recurring inflows, bills, and monthly calendar cadence.
class ExpensesPage extends ConsumerStatefulWidget {
  const ExpensesPage({super.key});

  @override
  ConsumerState<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ConsumerState<ExpensesPage> {
  // Add income form controllers
  final _incomeNameController = TextEditingController();
  final _incomeAmountController = TextEditingController();

  // Add expense form controllers
  final _expenseNameController = TextEditingController();
  final _expenseAmountController = TextEditingController();
  final _expenseDayController = TextEditingController(text: '0');

  @override
  void dispose() {
    _incomeNameController.dispose();
    _incomeAmountController.dispose();
    _expenseNameController.dispose();
    _expenseAmountController.dispose();
    _expenseDayController.dispose();
    super.dispose();
  }

  void _addIncome() {
    final name = _incomeNameController.text.trim();
    final amount = double.tryParse(_incomeAmountController.text.replaceAll(',', '').trim()) ?? 0.0;
    if (name.isEmpty || amount <= 0) return;

    ref.read(recurringCashflowControllerProvider.notifier).addCashflow(
          title: name,
          amount: amount,
          direction: CashflowDirection.inflowReceivable,
          dayOfMonth: 1,
          category: 'Income',
        );

    _incomeNameController.clear();
    _incomeAmountController.clear();
  }

  void _addExpense() {
    final name = _expenseNameController.text.trim();
    final amount = double.tryParse(_expenseAmountController.text.replaceAll(',', '').trim()) ?? 0.0;
    final day = int.tryParse(_expenseDayController.text.trim()) ?? 0;
    if (name.isEmpty || amount <= 0) return;

    ref.read(recurringCashflowControllerProvider.notifier).addCashflow(
          title: name,
          amount: amount,
          direction: CashflowDirection.outflowPayable,
          dayOfMonth: day.clamp(0, 31),
          category: 'Expense',
        );

    _expenseNameController.clear();
    _expenseAmountController.clear();
    _expenseDayController.text = '0';
  }

  void _deleteWithUndo(RecurringCashflowEntity item, int index) {
    ref.read(recurringCashflowControllerProvider.notifier).deleteCashflow(item.id);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${item.title}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref
                .read(recurringCashflowControllerProvider.notifier)
                .restoreCashflow(item, index);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final incomeList = ref.watch(monthlyInflowsProvider);
    final expenseList = ref.watch(monthlyOutflowsProvider);
    final dm = ref.watch(totalDebtMonthlyPaymentProvider);

    final inc = incomeList.fold<double>(0.0, (s, x) => s + x.amount);
    final fixed = expenseList.fold<double>(0.0, (s, x) => s + x.amount);
    final free = inc - fixed - dm;
    final w = math.max(inc, math.max(fixed + dm, 1.0));

    // Calendar: days 1..31
    final Map<int, List<RecurringCashflowEntity>> billDays = {};
    for (final exp in expenseList) {
      if (exp.dayOfMonth > 0 && exp.dayOfMonth <= 31) {
        billDays.putIfAbsent(exp.dayOfMonth, () => []).add(exp);
      }
    }

    return VelocityScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary Card (Income, Recurring, Debt payments, Split bar)
          VelocityCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 480;
                    return Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MetricColumn(
                          label: 'Income',
                          value: FinancialNumberFormatter.format(inc),
                          color: tokens.inColor,
                        ),
                        if (!isWide) const SizedBox(height: 12),
                        _MetricColumn(
                          label: 'Recurring',
                          value: FinancialNumberFormatter.format(fixed),
                          color: tokens.outColor,
                        ),
                        if (!isWide) const SizedBox(height: 12),
                        _MetricColumn(
                          label: 'Debt payments',
                          value: FinancialNumberFormatter.format(dm),
                          color: tokens.owedColor,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                VelocitySplitBar(
                  total: w,
                  segments: [
                    if (fixed > 0)
                      VelocitySplitSegment(
                        value: fixed,
                        color: tokens.outColor,
                      ),
                    if (dm > 0)
                      VelocitySplitSegment(
                        value: dm,
                        color: tokens.owedColor,
                      ),
                    if (free > 0)
                      VelocitySplitSegment(
                        value: free,
                        color: tokens.inColor,
                      ),
                  ],
                ),
              ],
            ),
          ),
            const SizedBox(height: 28),

            // Income Section
            Text(
              'Income',
              style: tokens.bricolage(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (incomeList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18.0),
                child: Text(
                  'No income yet. Add your first source below.',
                  style: tokens.figtree(fontSize: 14, color: tokens.muteColor),
                ),
              )
            else
              for (int i = 0; i < incomeList.length; i++) ...[
                _buildIncomeCard(incomeList[i], i, incomeList.length, inc),
                const SizedBox(height: 12),
              ],

            // Inline Add Income Form
            VelocityInlineAddSection(
              title: 'Add income',
              initiallyExpanded: incomeList.isEmpty,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _incomeNameController,
                          decoration: InputDecoration(
                            labelText: 'Source',
                            hintText: 'Salary',
                            filled: true,
                            fillColor: tokens.bgColor,
                            border: const OutlineInputBorder(
                              borderRadius: AppBorderRadius.allInput,
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppBorderRadius.allInput,
                              borderSide: BorderSide(color: tokens.lineColor),
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.hXS,
                      Expanded(
                        child: TextField(
                          controller: _incomeAmountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Monthly amount (₦)',
                            filled: true,
                            fillColor: tokens.bgColor,
                            border: const OutlineInputBorder(
                              borderRadius: AppBorderRadius.allInput,
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppBorderRadius.allInput,
                              borderSide: BorderSide(color: tokens.lineColor),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vXS,
                  VelocityButton.primary(
                    onPressed: _addIncome,
                    label: 'Add',
                    isFullWidth: true,
                  ),
                ],
              ),
            ),
            AppSpacing.vXL,

            // Recurring Expenses Section
            Text(
              'Recurring expenses',
              style: tokens.bricolage(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            AppSpacing.vS,

            // Bill days this month Calendar
            VelocityCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bill days this month',
                    style: tokens.bricolage(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = math.max(34.0, (constraints.maxWidth - (6 * 6)) / 7);
                      return Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (int d = 1; d <= 31; d++) ...[
                            _CalendarDayTile(
                              day: d,
                              bills: billDays[d] ?? const [],
                              width: itemWidth,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Expense Items
            if (expenseList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18.0),
                child: Text(
                  'No expenses yet. Add rent, data, food and subscriptions below.',
                  style: tokens.figtree(fontSize: 14, color: tokens.muteColor),
                ),
              )
            else
              for (int i = 0; i < expenseList.length; i++) ...[
                _buildExpenseCard(expenseList[i], i, expenseList.length, inc),
                const SizedBox(height: 12),
              ],

            // Inline Add Expense Form
            VelocityInlineAddSection(
              title: 'Add expense',
              initiallyExpanded: expenseList.isEmpty,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _expenseNameController,
                    decoration: InputDecoration(
                      labelText: 'Expense',
                      hintText: 'Rent',
                      filled: true,
                      fillColor: tokens.bgColor,
                      border: const OutlineInputBorder(
                        borderRadius: AppBorderRadius.allInput,
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppBorderRadius.allInput,
                        borderSide: BorderSide(color: tokens.lineColor),
                      ),
                    ),
                  ),
                  AppSpacing.vXS,
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _expenseAmountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Monthly amount (₦)',
                            filled: true,
                            fillColor: tokens.bgColor,
                            border: const OutlineInputBorder(
                              borderRadius: AppBorderRadius.allInput,
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppBorderRadius.allInput,
                              borderSide: BorderSide(color: tokens.lineColor),
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.hXS,
                      Expanded(
                        child: TextField(
                          controller: _expenseDayController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Due day (0 if none)',
                            filled: true,
                            fillColor: tokens.bgColor,
                            border: const OutlineInputBorder(
                              borderRadius: AppBorderRadius.allInput,
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppBorderRadius.allInput,
                              borderSide: BorderSide(color: tokens.lineColor),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vXS,
                  VelocityButton.primary(
                    onPressed: _addExpense,
                    label: 'Add',
                    isFullWidth: true,
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildIncomeCard(
    RecurringCashflowEntity item,
    int index,
    int totalCount,
    double totalIncome,
  ) {
    final tokens = context.tokens;
    final pct = totalIncome > 0 ? (item.amount / totalIncome * 100).round() : 0;
    final progress = totalIncome > 0 ? (item.amount / totalIncome).clamp(0.0, 1.0) : 0.0;

    return VelocityCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              VelocityAvatar(name: item.title, color: tokens.inColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: tokens.figtree(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: tokens.inkColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$pct% of income',
                      style: tokens.figtree(fontSize: 14, color: tokens.muteColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                FinancialNumberFormatter.format(item.amount),
                style: tokens.bricolage(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: tokens.inColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          VelocityProgressBar(progress: progress, color: tokens.inColor),
          const SizedBox(height: 10),
          VelocityActionRow(
            index: index,
            totalCount: totalCount,
            onRemove: () => _deleteWithUndo(item, index),
            onMoveTop: () => ref
                .read(recurringCashflowControllerProvider.notifier)
                .moveWithinDirection(item.id, CashflowDirection.inflowReceivable, 'top'),
            onMoveUp: () => ref
                .read(recurringCashflowControllerProvider.notifier)
                .moveWithinDirection(item.id, CashflowDirection.inflowReceivable, 'up'),
            onMoveDown: () => ref
                .read(recurringCashflowControllerProvider.notifier)
                .moveWithinDirection(item.id, CashflowDirection.inflowReceivable, 'down'),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(
    RecurringCashflowEntity item,
    int index,
    int totalCount,
    double totalIncome,
  ) {
    final tokens = context.tokens;
    final pct = totalIncome > 0 ? (item.amount / totalIncome * 100).round() : 0;
    final progress = totalIncome > 0 ? (item.amount / totalIncome).clamp(0.0, 1.0) : 0.0;

    return VelocityCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              VelocityAvatar(name: item.title, color: tokens.outColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: tokens.figtree(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: tokens.inkColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [
                        VelocityTag(
                          label: item.dayOfMonth > 0 ? 'Day ${item.dayOfMonth}' : 'No fixed date',
                        ),
                        VelocityTag(label: '$pct% of income'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                FinancialNumberFormatter.format(item.amount),
                style: tokens.bricolage(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: tokens.outColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          VelocityProgressBar(progress: progress, color: tokens.outColor),
          const SizedBox(height: 10),
          VelocityActionRow(
            index: index,
            totalCount: totalCount,
            onRemove: () => _deleteWithUndo(item, index),
            onMoveTop: () => ref
                .read(recurringCashflowControllerProvider.notifier)
                .moveWithinDirection(item.id, CashflowDirection.outflowPayable, 'top'),
            onMoveUp: () => ref
                .read(recurringCashflowControllerProvider.notifier)
                .moveWithinDirection(item.id, CashflowDirection.outflowPayable, 'up'),
            onMoveDown: () => ref
                .read(recurringCashflowControllerProvider.notifier)
                .moveWithinDirection(item.id, CashflowDirection.outflowPayable, 'down'),
          ),
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tokens.figtree(fontSize: 14, color: tokens.muteColor)),
        const SizedBox(height: 2),
        Text(
          value,
          style: tokens.bricolage(fontSize: 26, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

class _CalendarDayTile extends StatelessWidget {
  final int day;
  final List<RecurringCashflowEntity> bills;
  final double width;

  const _CalendarDayTile({
    required this.day,
    required this.bills,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hasBills = bills.isNotEmpty;

    return Tooltip(
      message: hasBills ? bills.map((b) => '${b.title}: ${FinancialNumberFormatter.format(b.amount)}').join('\n') : '',
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: hasBills ? tokens.outColor.withValues(alpha: 0.18) : tokens.bgColor,
          borderRadius: AppBorderRadius.allButton,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: tokens.figtree(
                fontSize: 13,
                fontWeight: hasBills ? FontWeight.w700 : FontWeight.w500,
                color: hasBills ? tokens.outColor : tokens.muteColor,
              ),
            ),
            if (hasBills)
              Positioned(
                top: 0,
                right: 4,
                child: Text(
                  '${bills.length}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: tokens.outColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
