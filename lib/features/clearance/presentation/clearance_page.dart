import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/velocity_tokens.dart';
import '../../../shared/design_system/buttons/velocity_button.dart';
import '../../../shared/design_system/inputs/thousands_separator_input_formatter.dart';
import '../../../shared/design_system/layout/velocity_scaffold.dart';
import '../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../../shared/design_system/widgets/velocity_action_row.dart';
import '../../../shared/design_system/widgets/velocity_avatar.dart';
import '../../../shared/design_system/widgets/velocity_card.dart';
import '../../../shared/design_system/widgets/velocity_inline_add.dart';
import '../../../shared/design_system/widgets/velocity_payment_sheet.dart';
import '../../../shared/design_system/widgets/velocity_progress_bar.dart';
import '../../../shared/design_system/widgets/velocity_progress_ring.dart';
import '../../../shared/design_system/widgets/velocity_tag.dart';
import '../domain/entities/debt_entity.dart';
import 'controllers/clearance_controller.dart';

/// Redesigned Debts workspace page tracking debt balances, payoff schedules, and partial payments.
class ClearancePage extends ConsumerStatefulWidget {
  const ClearancePage({super.key});

  @override
  ConsumerState<ClearancePage> createState() => _ClearancePageState();
}

class _ClearancePageState extends ConsumerState<ClearancePage> {
  final _creditorController = TextEditingController();
  final _totalController = TextEditingController();
  final _monthlyPaymentController = TextEditingController();
  DateTime? _selectedDueDate;
  bool _isClearedExpanded = false;

  @override
  void dispose() {
    _creditorController.dispose();
    _totalController.dispose();
    _monthlyPaymentController.dispose();
    super.dispose();
  }

  void _addDebt() {
    final creditor = _creditorController.text.trim();
    final total = double.tryParse(_totalController.text.replaceAll(',', '').trim()) ?? 0.0;
    final monthly = double.tryParse(_monthlyPaymentController.text.replaceAll(',', '').trim()) ?? 0.0;

    if (creditor.isEmpty || total <= 0) return;

    ref.read(clearanceControllerProvider.notifier).addDebt(
          creditor: creditor,
          totalOwed: total,
          initialPaid: 0.0,
          monthlyPayment: monthly,
          dueDate: _selectedDueDate,
        );

    _creditorController.clear();
    _totalController.clear();
    _monthlyPaymentController.clear();
    setState(() {
      _selectedDueDate = null;
    });
  }

  void _logPayment(DebtEntity debt) {
    VelocityPaymentSheet.show(
      context,
      title: 'Log payment: ${debt.creditor}',
      subtitle: 'Outstanding balance: ${FinancialNumberFormatter.format(debt.remainingAmount)}',
      maxAmount: debt.remainingAmount,
      actionLabel: 'Log payment',
      onConfirm: (amount, date) {
        ref.read(clearanceControllerProvider.notifier).logPayment(debt.id, amount);
      },
    );
  }

  void _deleteWithUndo(DebtEntity debt, int index) {
    ref.read(clearanceControllerProvider.notifier).deleteDebt(debt.id);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${debt.creditor}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref
                .read(clearanceControllerProvider.notifier)
                .restoreDebt(debt, index);
          },
        ),
      ),
    );
  }

  void _undoClearance(DebtEntity debt) {
    ref.read(clearanceControllerProvider.notifier).undoCleared(debt.id);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Restored ${debt.creditor} to active debts'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _quickClear(DebtEntity debt) {
    ref.read(clearanceControllerProvider.notifier).toggleCleared(debt.id);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cleared ${debt.creditor}! Moved to Cleared section.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _undoClearance(debt),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _editDebt(DebtEntity debt) {
    final tokens = context.tokens;
    final creditorController = TextEditingController(text: debt.creditor);

    String formatInitial(double val) {
      if (val <= 0) return '';
      final isInt = val.truncateToDouble() == val;
      return isInt
          ? NumberFormat('#,###').format(val.toInt())
          : NumberFormat('#,###.##').format(val);
    }

    final totalController = TextEditingController(text: formatInitial(debt.totalOwed));
    final paidController = TextEditingController(text: formatInitial(debt.amountPaid));
    final monthlyController = TextEditingController(text: formatInitial(debt.monthlyPayment));
    DateTime? dueDate = debt.dueDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final dateFormat = DateFormat('yyyy-MM-dd');

          return AlertDialog(
            backgroundColor: tokens.surfaceColor,
            shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.allCard),
            title: Text(
              'Edit Debt',
              style: tokens.bricolage(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: creditorController,
                    decoration: InputDecoration(
                      labelText: 'Creditor',
                      filled: true,
                      fillColor: tokens.bgColor,
                      border: OutlineInputBorder(
                        borderRadius: AppBorderRadius.allInput,
                        borderSide: BorderSide(color: tokens.lineColor),
                      ),
                    ),
                  ),
                  AppSpacing.vXS,
                  TextField(
                    controller: totalController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: InputDecoration(
                      labelText: 'Total Owed (₦)',
                      filled: true,
                      fillColor: tokens.bgColor,
                      border: OutlineInputBorder(
                        borderRadius: AppBorderRadius.allInput,
                        borderSide: BorderSide(color: tokens.lineColor),
                      ),
                    ),
                  ),
                  AppSpacing.vXS,
                  TextField(
                    controller: paidController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: InputDecoration(
                      labelText: 'Amount Paid (₦)',
                      filled: true,
                      fillColor: tokens.bgColor,
                      border: OutlineInputBorder(
                        borderRadius: AppBorderRadius.allInput,
                        borderSide: BorderSide(color: tokens.lineColor),
                      ),
                    ),
                  ),
                  AppSpacing.vXS,
                  TextField(
                    controller: monthlyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: InputDecoration(
                      labelText: 'Monthly Payment (₦)',
                      filled: true,
                      fillColor: tokens.bgColor,
                      border: OutlineInputBorder(
                        borderRadius: AppBorderRadius.allInput,
                        borderSide: BorderSide(color: tokens.lineColor),
                      ),
                    ),
                  ),
                  AppSpacing.vXS,
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setDialogState(() => dueDate = picked);
                      }
                    },
                    borderRadius: AppBorderRadius.allInput,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardGap, vertical: AppSpacing.cardGap),
                      decoration: BoxDecoration(
                        color: tokens.bgColor,
                        border: Border.all(color: tokens.lineColor),
                        borderRadius: AppBorderRadius.allInput,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dueDate != null ? 'Due: ${dateFormat.format(dueDate!)}' : 'No due date (optional)',
                            style: tokens.figtree(
                              fontSize: 14,
                              color: dueDate != null ? tokens.inkColor : tokens.muteColor,
                            ),
                          ),
                          if (dueDate != null)
                            GestureDetector(
                              onTap: () => setDialogState(() => dueDate = null),
                              child: Icon(Icons.clear, size: 16, color: tokens.muteColor),
                            )
                          else
                            Icon(Icons.calendar_today_rounded, size: 18, color: tokens.muteColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Cancel', style: tokens.figtree(color: tokens.muteColor)),
              ),
              VelocityButton.primary(
                onPressed: () {
                  final creditor = creditorController.text.trim();
                  final total = double.tryParse(totalController.text.replaceAll(',', '').trim()) ?? debt.totalOwed;
                  final paid = double.tryParse(paidController.text.replaceAll(',', '').trim()) ?? debt.amountPaid;
                  final monthly = double.tryParse(monthlyController.text.replaceAll(',', '').trim()) ?? debt.monthlyPayment;

                  if (creditor.isNotEmpty && total > 0) {
                    ref.read(clearanceControllerProvider.notifier).editDebt(
                          debtId: debt.id,
                          creditor: creditor,
                          totalOwed: total,
                          amountPaid: paid,
                          monthlyPayment: monthly,
                          dueDate: dueDate,
                          clearDueDate: dueDate == null,
                        );
                    Navigator.of(ctx).pop();
                  }
                },
                label: 'Save',
                height: 36,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final debts = ref.watch(clearanceControllerProvider);
    final dm = ref.watch(totalDebtMonthlyPaymentProvider);

    final tot = debts.fold<double>(0.0, (s, x) => s + x.totalOwed);
    final paid = debts.fold<double>(0.0, (s, x) => s + x.amountPaid);
    final owe = debts
        .where((d) => !d.isCleared)
        .fold<double>(0.0, (s, x) => s + x.remainingAmount);
    final progress = tot > 0 ? (paid / tot).clamp(0.0, 1.0) : 0.0;

    final dateFormat = DateFormat('yyyy-MM-dd');

    final activeDebts =
        debts.where((d) => !d.isCleared && d.remainingAmount > 0).toList();
    final clearedDebts =
        debts.where((d) => d.isCleared || d.remainingAmount <= 0).toList();

    return VelocityScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Summary Card
          VelocityCard(
            child: Row(
              children: [
                VelocityProgressRing(
                  progress: progress,
                  color: tokens.inColor,
                  size: 88,
                ),
                AppSpacing.hM,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Still owed',
                        style: tokens.figtree(fontSize: 14, color: tokens.muteColor),
                      ),
                      AppSpacing.vXXS,
                      Text(
                        FinancialNumberFormatter.format(owe),
                        style: tokens.bricolage(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: tokens.outColor,
                        ),
                      ),
                      AppSpacing.vXXS,
                      Text(
                        '${FinancialNumberFormatter.format(paid)} paid of ${FinancialNumberFormatter.format(tot)}. ${FinancialNumberFormatter.format(dm)} goes out each month.',
                        style: tokens.figtree(fontSize: 14, color: tokens.muteColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vL,

          // Active Debts List
          if (activeDebts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
              child: Text(
                debts.isEmpty
                    ? 'No debts. Add one below.'
                    : 'All debts cleared! Amazing job.',
                style: tokens.figtree(fontSize: 14, color: tokens.muteColor),
              ),
            )
          else
            for (int i = 0; i < activeDebts.length; i++) ...[
              _buildActiveDebtCard(activeDebts[i], i, activeDebts.length),
              AppSpacing.vCardGap,
            ],

          // Inline Add Debt Form
          VelocityInlineAddSection(
            title: 'Add debt',
            initiallyExpanded: debts.isEmpty,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _creditorController,
                  decoration: InputDecoration(
                    labelText: 'Who or what',
                    hintText: 'Bank loan',
                    filled: true,
                    fillColor: tokens.bgColor,
                    border: OutlineInputBorder(
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
                        controller: _totalController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [ThousandsSeparatorInputFormatter()],
                        decoration: InputDecoration(
                          labelText: 'Total (₦)',
                          filled: true,
                          fillColor: tokens.bgColor,
                          border: OutlineInputBorder(
                            borderRadius: AppBorderRadius.allInput,
                            borderSide: BorderSide(color: tokens.lineColor),
                          ),
                        ),
                      ),
                    ),
                    AppSpacing.hXS,
                    Expanded(
                      child: TextField(
                        controller: _monthlyPaymentController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [ThousandsSeparatorInputFormatter()],
                        decoration: InputDecoration(
                          labelText: 'Monthly payment (₦)',
                          filled: true,
                          fillColor: tokens.bgColor,
                          border: OutlineInputBorder(
                            borderRadius: AppBorderRadius.allInput,
                            borderSide: BorderSide(color: tokens.lineColor),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vXS,
                InkWell(
                  onTap: _pickDueDate,
                  borderRadius: AppBorderRadius.allInput,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.cardGap,
                      vertical: AppSpacing.cardGap,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.bgColor,
                      border: Border.all(color: tokens.lineColor),
                      borderRadius: AppBorderRadius.allInput,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDueDate != null
                              ? 'Next due date: ${dateFormat.format(_selectedDueDate!)}'
                              : 'Select next due date (optional)',
                          style: tokens.figtree(
                            fontSize: 14,
                            color: _selectedDueDate != null ? tokens.inkColor : tokens.muteColor,
                          ),
                        ),
                        Icon(Icons.calendar_today_rounded, size: 18, color: tokens.muteColor),
                      ],
                    ),
                  ),
                ),
                AppSpacing.vCardGap,
                VelocityButton.primary(
                  onPressed: _addDebt,
                  label: 'Add',
                  isFullWidth: true,
                ),
              ],
            ),
          ),

          // Collapsible Cleared Section at the bottom of the screen
          if (clearedDebts.isNotEmpty) ...[
            AppSpacing.vL,
            _buildClearedSection(clearedDebts),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveDebtCard(DebtEntity debt, int index, int totalCount) {
    final tokens = context.tokens;
    final left = debt.remainingAmount;
    final progress = debt.totalOwed > 0 ? (debt.amountPaid / debt.totalOwed).clamp(0.0, 1.0) : 0.0;
    final months = debt.monthsLeft;
    final dateFormat = DateFormat('yyyy-MM-dd');

    return VelocityCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              VelocityAvatar(
                name: debt.creditor,
                color: tokens.outColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.creditor,
                      style: tokens.figtree(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: tokens.inkColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (debt.isOverdue)
                          const VelocityTag(
                            label: 'Overdue',
                            variant: VelocityTagVariant.late,
                          ),
                        if (debt.hasDueDate)
                          VelocityTag(label: 'Due ${dateFormat.format(debt.dueDate!)}'),
                        if (months > 0)
                          VelocityTag(label: '$months mo left'),
                      ],
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'Edit debt',
                child: InkWell(
                  onTap: () => _editDebt(debt),
                  borderRadius: AppBorderRadius.allButton,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: tokens.muteColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vCardGap,

          // Money Block (.mm): Paid | Left
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: tokens.bgColor,
                    borderRadius: AppBorderRadius.allButton,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paid',
                        style: tokens.figtree(fontSize: 12, color: tokens.muteColor),
                      ),
                      AppSpacing.vXXS,
                      Text(
                        FinancialNumberFormatter.format(debt.amountPaid),
                        style: tokens.bricolage(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: tokens.inColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.hXS,
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: tokens.bgColor,
                    borderRadius: AppBorderRadius.allButton,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Left',
                        style: tokens.figtree(fontSize: 12, color: tokens.muteColor),
                      ),
                      AppSpacing.vXXS,
                      Text(
                        FinancialNumberFormatter.format(math.max(0, left)),
                        style: tokens.bricolage(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: tokens.outColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vS,

          // Progress Bar
          VelocityProgressBar(progress: progress, color: tokens.inColor),
          if (debt.monthlyPayment > 0 && left > 0) ...[
            AppSpacing.vXXS,
            Text(
              '${FinancialNumberFormatter.format(math.min(debt.monthlyPayment, left))} per month',
              style: tokens.figtree(fontSize: 14, color: tokens.muteColor),
            ),
          ],
          AppSpacing.vS,

          // Action Row
          VelocityActionRow(
            index: index,
            totalCount: totalCount,
            primaryActionLabel: 'Log payment',
            onPrimaryAction: () => _logPayment(debt),
            secondaryActionLabel: 'Clear all',
            onSecondaryAction: () => _quickClear(debt),
            onRemove: () => _deleteWithUndo(debt, index),
            onMoveTop: () =>
                ref.read(clearanceControllerProvider.notifier).moveActive(debt.id, 'top'),
            onMoveUp: () =>
                ref.read(clearanceControllerProvider.notifier).moveActive(debt.id, 'up'),
            onMoveDown: () =>
                ref.read(clearanceControllerProvider.notifier).moveActive(debt.id, 'down'),
          ),
        ],
      ),
    );
  }

  Widget _buildClearedSection(List<DebtEntity> clearedDebts) {
    final tokens = context.tokens;
    final totalCleared = clearedDebts.fold<double>(0.0, (s, d) => s + d.totalOwed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isClearedExpanded = !_isClearedExpanded;
            });
          },
          borderRadius: AppBorderRadius.allCard,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: tokens.surfaceColor,
              borderRadius: AppBorderRadius.allCard,
              border: Border.all(color: tokens.lineColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: tokens.inColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, size: 16, color: tokens.inColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Cleared debts',
                            style: tokens.bricolage(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: tokens.inkColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                            decoration: BoxDecoration(
                              color: tokens.bgColor,
                              borderRadius: AppBorderRadius.allPill,
                              border: Border.all(color: tokens.lineColor),
                            ),
                            child: Text(
                              '${clearedDebts.length}',
                              style: tokens.figtree(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: tokens.inColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${FinancialNumberFormatter.format(totalCleared)} total cleared',
                        style: tokens.figtree(
                          fontSize: 12,
                          color: tokens.muteColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _isClearedExpanded ? 'Hide' : 'Show',
                  style: tokens.figtree(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: tokens.muteColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isClearedExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: tokens.muteColor,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Column(
              children: [
                for (int i = 0; i < clearedDebts.length; i++) ...[
                  _buildClearedDebtCard(clearedDebts[i], i, clearedDebts.length),
                  if (i < clearedDebts.length - 1) AppSpacing.vCardGap,
                ],
              ],
            ),
          ),
          crossFadeState: _isClearedExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  Widget _buildClearedDebtCard(DebtEntity debt, int index, int totalCount) {
    final tokens = context.tokens;
    return VelocityCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              VelocityAvatar(
                name: debt.creditor,
                color: tokens.inColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.creditor,
                      style: tokens.figtree(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: tokens.inkColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const VelocityTag(label: 'Cleared'),
                  ],
                ),
              ),
              Tooltip(
                message: 'Edit debt',
                child: InkWell(
                  onTap: () => _editDebt(debt),
                  borderRadius: AppBorderRadius.allButton,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: tokens.muteColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vCardGap,

          // Money Block (.mm): Paid | Left
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: tokens.bgColor,
                    borderRadius: AppBorderRadius.allButton,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paid',
                        style: tokens.figtree(fontSize: 12, color: tokens.muteColor),
                      ),
                      AppSpacing.vXXS,
                      Text(
                        FinancialNumberFormatter.format(debt.totalOwed),
                        style: tokens.bricolage(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: tokens.inColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.hXS,
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: tokens.bgColor,
                    borderRadius: AppBorderRadius.allButton,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Left',
                        style: tokens.figtree(fontSize: 12, color: tokens.muteColor),
                      ),
                      AppSpacing.vXXS,
                      Text(
                        '₦0',
                        style: tokens.bricolage(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: tokens.muteColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vS,

          // 100% Progress Bar
          VelocityProgressBar(progress: 1.0, color: tokens.inColor),
          AppSpacing.vS,

          // Action row with Undo cleared and Remove
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VelocityButton.soft(
                onPressed: () => _undoClearance(debt),
                label: 'Undo cleared',
                height: 28.0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              ),
              VelocityButton.subtle(
                onPressed: () => _deleteWithUndo(debt, index),
                label: 'Remove',
                height: 28.0,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
