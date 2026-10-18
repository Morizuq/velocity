import 'package:flutter/material.dart';
import '../../../../shared/design_system/buttons/primary_button.dart';
import '../../../../shared/design_system/inputs/currency_amount_input.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../domain/entities/milestone_entity.dart';

/// Dialog to allocate liquid capital towards a target milestone goal.
class FundMilestoneDialog extends StatefulWidget {
  final MilestoneEntity milestone;
  final ValueChanged<double> onFundConfirmed;

  const FundMilestoneDialog({
    super.key,
    required this.milestone,
    required this.onFundConfirmed,
  });

  @override
  State<FundMilestoneDialog> createState() => _FundMilestoneDialogState();
}

class _FundMilestoneDialogState extends State<FundMilestoneDialog> {
  final TextEditingController _amountController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (parsed == null || parsed <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount');
      return;
    }
    widget.onFundConfirmed(parsed);
    Navigator.of(context).pop();
  }

  void _applyQuickAmount(double amount) {
    _amountController.text = FinancialNumberFormatter.format(amount)
        .replaceAll('₦', '')
        .trim();
    setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;

    return Dialog(
      backgroundColor: brandColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: AppBorderRadius.allXL,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(AppSpacing.l),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fund Milestone',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                      AppSpacing.vXXS,
                      Text(
                        widget.milestone.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              AppSpacing.vM,
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: brandColors.milestone.withValues(alpha: 0.1),
                  borderRadius: AppBorderRadius.allM,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Remaining Needed',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: brandColors.milestone,
                        fontWeight: AppFontWeight.medium,
                      ),
                    ),
                    Text(
                      FinancialNumberFormatter.format(widget.milestone.remainingAmount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: brandColors.milestone,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.vM,
              CurrencyAmountInput(
                labelText: 'Allocation Amount (NGN)',
                hintText: 'e.g. 25,000',
                controller: _amountController,
                prefixIcon: const Icon(Icons.savings_outlined),
              ),
              if (_errorMessage != null) ...[
                AppSpacing.vXXS,
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              AppSpacing.vS,
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _AllocationChip(
                    label: '+₦10,000',
                    onTap: () => _applyQuickAmount(10000),
                  ),
                  _AllocationChip(
                    label: '+₦50,000',
                    onTap: () => _applyQuickAmount(50000),
                  ),
                  _AllocationChip(
                    label: 'Complete Goal',
                    onTap: () => _applyQuickAmount(widget.milestone.remainingAmount),
                    highlight: true,
                  ),
                ],
              ),
              AppSpacing.vXL,
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'Allocate Capital',
                  icon: Icons.add_task_rounded,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllocationChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  const _AllocationChip({
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;

    return InkWell(
      onTap: onTap,
      borderRadius: AppBorderRadius.pill,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s,
          vertical: AppSpacing.xxs + 2,
        ),
        decoration: BoxDecoration(
          color: highlight
              ? brandColors.milestone.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: AppBorderRadius.pill,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: AppFontWeight.medium,
            color: highlight ? brandColors.milestone : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
