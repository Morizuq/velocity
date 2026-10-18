import 'package:flutter/material.dart';
import '../../../../shared/design_system/buttons/primary_button.dart';
import '../../../../shared/design_system/inputs/currency_amount_input.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../domain/entities/debt_entity.dart';

/// Modal dialog for logging a payment towards an active debt.
class LogPaymentDialog extends StatefulWidget {
  final DebtEntity debt;
  final ValueChanged<double> onPaymentConfirmed;

  const LogPaymentDialog({
    super.key,
    required this.debt,
    required this.onPaymentConfirmed,
  });

  @override
  State<LogPaymentDialog> createState() => _LogPaymentDialogState();
}

class _LogPaymentDialogState extends State<LogPaymentDialog> {
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
    widget.onPaymentConfirmed(parsed);
    Navigator.of(context).pop();
  }

  void _applyQuickAmount(double amount) {
    _amountController.text = FinancialNumberFormatter.format(
      amount,
    ).replaceAll('₦', '').trim();
    setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;

    return Dialog(
      backgroundColor: brandColors.surfaceCard,
      shape: const RoundedRectangleBorder(borderRadius: AppBorderRadius.allXL),
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
                        'Log Payment',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                      AppSpacing.vXXS,
                      Text(
                        widget.debt.creditor,
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
                  color: brandColors.debt.withValues(alpha: 0.1),
                  borderRadius: AppBorderRadius.allM,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Remaining Dues',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: brandColors.debt,
                        fontWeight: AppFontWeight.medium,
                      ),
                    ),
                    Text(
                      FinancialNumberFormatter.format(
                        widget.debt.remainingAmount,
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: brandColors.debt,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.vM,
              CurrencyAmountInput(
                labelText: 'Payment Amount (NGN)',
                hintText: 'e.g. 15,000',
                controller: _amountController,
                prefixIcon: const Icon(Icons.payments_outlined),
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
              // Quick preset chips
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _QuickChip(
                    label: '+₦5,000',
                    onTap: () => _applyQuickAmount(5000),
                  ),
                  _QuickChip(
                    label: '+₦10,000',
                    onTap: () => _applyQuickAmount(10000),
                  ),
                  _QuickChip(
                    label: '+₦20,000',
                    onTap: () => _applyQuickAmount(20000),
                  ),
                  _QuickChip(
                    label: 'Clear All',
                    onTap: () => _applyQuickAmount(widget.debt.remainingAmount),
                    highlight: true,
                  ),
                ],
              ),
              AppSpacing.vXL,
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'Record Payment',
                  icon: Icons.check_circle_outline_rounded,
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

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  const _QuickChip({
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
              ? brandColors.progress.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: AppBorderRadius.pill,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: AppFontWeight.medium,
            color: highlight
                ? brandColors.progress
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
