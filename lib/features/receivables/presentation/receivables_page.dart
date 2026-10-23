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
import '../domain/entities/receivable_entity.dart';
import '../domain/entities/receivable_type.dart';
import 'controllers/receivables_controller.dart';

/// Redesigned Owed workspace page tracking client invoices, loans, and receivables.
class ReceivablesPage extends ConsumerStatefulWidget {
  const ReceivablesPage({super.key});

  @override
  ConsumerState<ReceivablesPage> createState() => _ReceivablesPageState();
}

class _ReceivablesPageState extends ConsumerState<ReceivablesPage> {
  final _debtorController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDueDate;

  @override
  void dispose() {
    _debtorController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _addReceivable() {
    final debtor = _debtorController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0.0;

    if (debtor.isEmpty || amount <= 0) return;

    ref.read(receivablesControllerProvider.notifier).addReceivable(
          debtor: debtor,
          totalAmount: amount,
          initialReceived: 0.0,
          type: ReceivableType.freelanceInvoice,
          dueDate: _selectedDueDate,
        );

    _debtorController.clear();
    _amountController.clear();
    setState(() {
      _selectedDueDate = null;
    });
  }

  void _logPaymentReceived(ReceivableEntity receivable) {
    VelocityPaymentSheet.show(
      context,
      title: 'Log payment received: ${receivable.debtor}',
      subtitle: 'Outstanding balance: ${FinancialNumberFormatter.format(receivable.remainingBalance)}',
      maxAmount: receivable.remainingBalance,
      actionLabel: 'Log payment received',
      onConfirm: (amount, date) {
        ref
            .read(receivablesControllerProvider.notifier)
            .recordPayment(receivable.id, amount);
      },
    );
  }

  void _deleteWithUndo(ReceivableEntity receivable, int index) {
    ref
        .read(receivablesControllerProvider.notifier)
        .deleteReceivable(receivable.id);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${receivable.debtor}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref
                .read(receivablesControllerProvider.notifier)
                .restoreReceivable(receivable, index);
          },
        ),
      ),
    );
  }

  void _undoSettled(ReceivableEntity receivable) {
    ref.read(receivablesControllerProvider.notifier).undoSettled(receivable.id);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Restored ${receivable.debtor} to active receivables'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _editReceivable(ReceivableEntity receivable) {
    final tokens = context.tokens;
    final debtorController = TextEditingController(text: receivable.debtor);
    final totalController = TextEditingController(
      text: receivable.totalAmount.toStringAsFixed(receivable.totalAmount.truncateToDouble() == receivable.totalAmount ? 0 : 2),
    );
    final receivedController = TextEditingController(
      text: receivable.amountReceived.toStringAsFixed(receivable.amountReceived.truncateToDouble() == receivable.amountReceived ? 0 : 2),
    );
    DateTime? dueDate = receivable.dueDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final dateFormat = DateFormat('yyyy-MM-dd');

          return AlertDialog(
            backgroundColor: tokens.surfaceColor,
            shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.allCard),
            title: Text(
              'Edit Receivable',
              style: tokens.bricolage(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: debtorController,
                    decoration: InputDecoration(
                      labelText: 'Debtor / Payer',
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
                      labelText: 'Total Amount (₦)',
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
                    controller: receivedController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount Received (₦)',
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
                        initialDate: dueDate ?? DateTime.now().add(const Duration(days: 14)),
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
                  final debtor = debtorController.text.trim();
                  final total = double.tryParse(totalController.text.replaceAll(',', '').trim()) ?? receivable.totalAmount;
                  final received = double.tryParse(receivedController.text.replaceAll(',', '').trim()) ?? receivable.amountReceived;

                  if (debtor.isNotEmpty && total > 0) {
                    ref.read(receivablesControllerProvider.notifier).editReceivable(
                          id: receivable.id,
                          debtor: debtor,
                          totalAmount: total,
                          amountReceived: received,
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
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 14)),
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
    final receivables = ref.watch(receivablesControllerProvider);

    final tot = receivables.fold<double>(0.0, (s, x) => s + x.totalAmount);
    final got = receivables.fold<double>(0.0, (s, x) => s + x.amountReceived);
    final due = receivables
        .where((r) => !r.isSettled)
        .fold<double>(0.0, (s, x) => s + x.remainingBalance);
    final progress = tot > 0 ? (got / tot).clamp(0.0, 1.0) : 0.0;

    final dateFormat = DateFormat('yyyy-MM-dd');

    return VelocityScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary Card
            VelocityCard(
              child: Row(
                children: [
                  VelocityProgressRing(
                    progress: progress,
                    color: tokens.owedColor,
                    size: 88,
                  ),
                  AppSpacing.hM,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Still to collect',
                          style: tokens.figtree(fontSize: 14, color: tokens.muteColor),
                        ),
                        AppSpacing.vXXS,
                        Text(
                          FinancialNumberFormatter.format(due),
                          style: tokens.bricolage(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: tokens.owedColor,
                          ),
                        ),
                        AppSpacing.vXXS,
                        Text(
                          '${FinancialNumberFormatter.format(got)} received of ${FinancialNumberFormatter.format(tot)}.',
                          style: tokens.figtree(fontSize: 14, color: tokens.muteColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.vL,

            // Receivables List
            if (receivables.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
                child: Text(
                  'Nobody owes you yet.',
                  style: tokens.figtree(fontSize: 14, color: tokens.muteColor),
                ),
              )
            else
              for (int i = 0; i < receivables.length; i++) ...[
                _buildReceivableCard(receivables[i], i, receivables.length),
                AppSpacing.vCardGap,
              ],

            // Inline Add Form
            VelocityInlineAddSection(
              title: 'Add receivable',
              initiallyExpanded: receivables.isEmpty,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _debtorController,
                    decoration: InputDecoration(
                      labelText: 'Who owes you',
                      hintText: 'Client name',
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
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount (₦)',
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
                                ? 'Due date: ${dateFormat.format(_selectedDueDate!)}'
                                : 'Select due date (optional)',
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
                    onPressed: _addReceivable,
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

  Widget _buildReceivableCard(ReceivableEntity receivable, int index, int totalCount) {
    final tokens = context.tokens;
    final left = receivable.remainingBalance;
    final isSettled = receivable.isSettled || left <= 0;
    final progress = receivable.totalAmount > 0
        ? (receivable.amountReceived / receivable.totalAmount).clamp(0.0, 1.0)
        : 0.0;
    final daysLate = receivable.daysLate;

    final dateFormat = DateFormat('yyyy-MM-dd');

    return VelocityCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              VelocityAvatar(
                name: receivable.debtor,
                color: isSettled ? tokens.inColor : tokens.owedColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receivable.debtor,
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
                        if (isSettled)
                          const VelocityTag(label: 'Received')
                        else ...[
                          if (daysLate > 0)
                            VelocityTag(
                              label: '$daysLate days late',
                              variant: VelocityTagVariant.late,
                            ),
                          if (receivable.dueDate != null && daysLate <= 0)
                            VelocityTag(label: 'Due ${dateFormat.format(receivable.dueDate!)}'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'Edit receivable',
                child: InkWell(
                  onTap: () => _editReceivable(receivable),
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

          // Money Block (.mm): Received | Outstanding
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
                        'Received',
                        style: tokens.figtree(fontSize: 12, color: tokens.muteColor),
                      ),
                      AppSpacing.vXXS,
                      Text(
                        FinancialNumberFormatter.format(receivable.amountReceived),
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
                        'Outstanding',
                        style: tokens.figtree(fontSize: 12, color: tokens.muteColor),
                      ),
                      AppSpacing.vXXS,
                      Text(
                        FinancialNumberFormatter.format(math.max(0, left)),
                        style: tokens.bricolage(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: tokens.owedColor,
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
          VelocityProgressBar(progress: progress, color: tokens.owedColor),
          AppSpacing.vS,

          // Action Row
          VelocityActionRow(
            index: index,
            totalCount: totalCount,
            primaryActionLabel: isSettled ? 'Undo settled' : (left > 0 ? 'Log payment received' : null),
            onPrimaryAction: isSettled ? () => _undoSettled(receivable) : (left > 0 ? () => _logPaymentReceived(receivable) : null),
            onRemove: () => _deleteWithUndo(receivable, index),
            onMoveTop: () =>
                ref.read(receivablesControllerProvider.notifier).move(index, 'top'),
            onMoveUp: () =>
                ref.read(receivablesControllerProvider.notifier).move(index, 'up'),
            onMoveDown: () =>
                ref.read(receivablesControllerProvider.notifier).move(index, 'down'),
          ),
        ],
      ),
    );
  }
}
