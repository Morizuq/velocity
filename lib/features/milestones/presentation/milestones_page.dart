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
import '../../../shared/design_system/widgets/velocity_card.dart';
import '../../../shared/design_system/widgets/velocity_inline_add.dart';
import '../../../shared/design_system/widgets/velocity_payment_sheet.dart';
import '../../../shared/design_system/widgets/velocity_progress_ring.dart';
import '../../../shared/design_system/widgets/velocity_tag.dart';
import '../../clearance/presentation/controllers/clearance_controller.dart';
import '../../expenses/presentation/controllers/recurring_cashflow_controller.dart';
import '../domain/entities/milestone_entity.dart';
import 'controllers/milestones_controller.dart';

/// Redesigned Goals workspace page tracking target purchases, down payments, and surplus timeline projection.
class MilestonesPage extends ConsumerStatefulWidget {
  const MilestonesPage({super.key});

  @override
  ConsumerState<MilestonesPage> createState() => _MilestonesPageState();
}

class _MilestonesPageState extends ConsumerState<MilestonesPage> {
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  final _savedController = TextEditingController(text: '0');

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _savedController.dispose();
    super.dispose();
  }

  void _addGoal() {
    final title = _titleController.text.trim();
    final target = double.tryParse(_targetController.text.replaceAll(',', '').trim()) ?? 0.0;
    final saved = double.tryParse(_savedController.text.replaceAll(',', '').trim()) ?? 0.0;

    if (title.isEmpty || target <= 0) return;

    ref.read(milestonesControllerProvider.notifier).addMilestone(
          title: title,
          targetAmount: target,
          initialAmount: saved,
        );

    _titleController.clear();
    _targetController.clear();
    _savedController.text = '0';
  }

  void _addSavings(MilestoneEntity goal) {
    VelocityPaymentSheet.show(
      context,
      title: 'Add savings: ${goal.title}',
      subtitle: 'Remaining to reach target: ${FinancialNumberFormatter.format(goal.remainingAmount)}',
      maxAmount: goal.remainingAmount,
      actionLabel: 'Add savings',
      onConfirm: (amount, date) {
        ref.read(milestonesControllerProvider.notifier).adjustFunds(goal.id, amount);
      },
    );
  }

  void _deleteWithUndo(MilestoneEntity goal, int index) {
    ref.read(milestonesControllerProvider.notifier).deleteMilestone(goal.id);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${goal.title}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref
                .read(milestonesControllerProvider.notifier)
                .restoreMilestone(goal, index);
          },
        ),
      ),
    );
  }

  void _editGoal(MilestoneEntity goal) {
    final tokens = context.tokens;
    final titleController = TextEditingController(text: goal.title);

    String formatInitial(double val) {
      if (val <= 0) return '';
      final isInt = val.truncateToDouble() == val;
      return isInt
          ? NumberFormat('#,###').format(val.toInt())
          : NumberFormat('#,###.##').format(val);
    }

    final targetController = TextEditingController(text: formatInitial(goal.targetAmount));
    final savedController = TextEditingController(text: formatInitial(goal.currentAmount));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.allCard),
        title: Text(
          'Edit Goal',
          style: tokens.bricolage(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Goal Title',
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
                controller: targetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'Target Budget (₦)',
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
                controller: savedController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'Saved so far (₦)',
                  filled: true,
                  fillColor: tokens.bgColor,
                  border: OutlineInputBorder(
                    borderRadius: AppBorderRadius.allInput,
                    borderSide: BorderSide(color: tokens.lineColor),
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
              final title = titleController.text.trim();
              final target = double.tryParse(targetController.text.replaceAll(',', '').trim()) ?? goal.targetAmount;
              final saved = double.tryParse(savedController.text.replaceAll(',', '').trim()) ?? goal.currentAmount;

              if (title.isNotEmpty && target > 0) {
                ref.read(milestonesControllerProvider.notifier).editMilestone(
                      milestoneId: goal.id,
                      title: title,
                      targetAmount: target,
                      currentAmount: saved,
                    );
                Navigator.of(ctx).pop();
              }
            },
            label: 'Save',
            height: 36,
          ),
        ],
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
    final free = math.max(0.0, inc - fixed - dm);

    final goals = ref.watch(milestonesControllerProvider);

    return VelocityScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Summary Card
            VelocityCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly surplus',
                    style: tokens.figtree(fontSize: 14, color: tokens.muteColor),
                  ),
                  AppSpacing.vXXS,
                  Text(
                    FinancialNumberFormatter.format(free),
                    style: tokens.bricolage(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: tokens.inColor,
                    ),
                  ),
                  AppSpacing.vXXS,
                  Text(
                    free > 0
                        ? 'Timelines below assume all of it goes to that one goal.'
                        : 'No surplus yet, so timelines can’t be estimated.',
                    style: tokens.figtree(fontSize: 14, color: tokens.muteColor),
                  ),
                ],
              ),
            ),
            AppSpacing.vL,

            // Goals List
            if (goals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
                child: Text(
                  'No goals yet.',
                  style: tokens.figtree(fontSize: 14, color: tokens.muteColor),
                ),
              )
            else
              for (int i = 0; i < goals.length; i++) ...[
                _buildGoalCard(goals[i], i, goals.length, free),
                AppSpacing.vCardGap,
              ],

            // Inline Add Form
            VelocityInlineAddSection(
              title: 'Add goal',
              initiallyExpanded: goals.isEmpty,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Goal',
                      hintText: 'House deposit',
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
                          controller: _targetController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [ThousandsSeparatorInputFormatter()],
                          decoration: InputDecoration(
                            labelText: 'Target (₦)',
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
                          controller: _savedController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [ThousandsSeparatorInputFormatter()],
                          decoration: InputDecoration(
                            labelText: 'Saved so far (₦)',
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
                  AppSpacing.vCardGap,
                  VelocityButton.primary(
                    onPressed: _addGoal,
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

  Widget _buildGoalCard(MilestoneEntity goal, int index, int totalCount, double surplus) {
    final tokens = context.tokens;
    final left = goal.remainingAmount;
    final isReached = goal.isCompleted || left <= 0;
    final progress = goal.progressRatio;
    final months = (surplus > 0 && left > 0) ? (left / surplus).ceil() : 0;

    return VelocityCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              VelocityProgressRing(
                progress: progress,
                color: tokens.accentColor,
                size: 84,
              ),
              AppSpacing.hM,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: tokens.figtree(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: tokens.inkColor,
                      ),
                    ),
                    AppSpacing.vXXS,
                    Text(
                      '${FinancialNumberFormatter.format(goal.currentAmount)} of ${FinancialNumberFormatter.format(goal.targetAmount)}',
                      style: tokens.figtree(fontSize: 14, color: tokens.muteColor),
                    ),
                    AppSpacing.vXXS,
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (isReached)
                          const VelocityTag(label: 'Reached')
                        else ...[
                          VelocityTag(label: '${FinancialNumberFormatter.format(left)} to go'),
                          if (months > 0)
                            VelocityTag(label: 'About $months mo'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'Edit goal',
                child: InkWell(
                  onTap: () => _editGoal(goal),
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
          AppSpacing.vS,

          // Action Row
          VelocityActionRow(
            index: index,
            totalCount: totalCount,
            primaryActionLabel: left > 0 ? 'Add savings' : null,
            onPrimaryAction: left > 0 ? () => _addSavings(goal) : null,
            onRemove: () => _deleteWithUndo(goal, index),
            onMoveTop: () =>
                ref.read(milestonesControllerProvider.notifier).move(index, 'top'),
            onMoveUp: () =>
                ref.read(milestonesControllerProvider.notifier).move(index, 'up'),
            onMoveDown: () =>
                ref.read(milestonesControllerProvider.notifier).move(index, 'down'),
          ),
        ],
      ),
    );
  }
}
