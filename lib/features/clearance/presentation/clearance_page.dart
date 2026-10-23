import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

  void _editDebt(DebtEntity debt) {
    final tokens = context.tokens;
    final creditorController = TextEditingController(text: debt.creditor);
    final totalController = TextEditingController(
      text: debt.totalOwed.toStringAsFixed(debt.totalOwed.truncateToDouble() == debt.totalOwed ? 0 : 2),
    );
    final paidController = TextEditingController(
      text: debt.amountPaid.toStringAsFixed(debt.amountPaid.truncateToDouble() == debt.amountPaid ? 0 : 2),
    );
    final monthlyController = TextEditingController(
      text: debt.monthlyPayment > 0
          ? debt.monthlyPayment.toStringAsFixed(debt.monthlyPayment.truncateToDouble() == debt.monthlyPayment ? 0 : 2)
          : '',
    );
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

            // Debts List
            if (debts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
                child: Text(
                  'No debts. Add one below.',
                  style: tokens.figtree(fontSize: 14, color: tokens.muteColor),
                ),
              )
            else
              for (int i = 0; i < debts.length; i++) ...[
                _buildDebtCard(debts[i], i, debts.length),
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
          ],
        ),
    );
  }

  Widget _buildDebtCard(DebtEntity debt, int index, int totalCount) {
    final tokens = context.tokens;
    final left = debt.remainingAmount;
    final isCleared = debt.isCleared || left <= 0;
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
                color: isCleared ? tokens.inColor : tokens.outColor,
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
                        if (isCleared)
                          const VelocityTag(label: 'Cleared')
                        else ...[
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
                      ],
                    ),
                  ],
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
            primaryActionLabel: isCleared ? 'Undo cleared' : (left > 0 ? 'Log payment' : null),
            onPrimaryAction: isCleared ? () => _undoClearance(debt) : (left > 0 ? () => _logPayment(debt) : null),
            onEdit: () => _editDebt(debt),
            onRemove: () => _deleteWithUndo(debt, index),
            onMoveTop: () =>
                ref.read(clearanceControllerProvider.notifier).move(index, 'top'),
            onMoveUp: () =>
                ref.read(clearanceControllerProvider.notifier).move(index, 'up'),
            onMoveDown: () =>
                ref.read(clearanceControllerProvider.notifier).move(index, 'down'),
          ),
        ],
      ),
    );
  }
}
