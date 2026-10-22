import 'package:flutter/material.dart';
import '../../../../shared/design_system/buttons/primary_button.dart';
import '../../../../shared/design_system/inputs/currency_amount_input.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../domain/entities/receivable_entity.dart';

/// Modal dialog for recording an incoming payment against a receivable item.
class LogReceivablePaymentDialog extends StatefulWidget {
  final ReceivableEntity receivable;
  final ValueChanged<double> onPaymentConfirmed;

  const LogReceivablePaymentDialog({
    super.key,
    required this.receivable,
    required this.onPaymentConfirmed,
  });

  @override
  State<LogReceivablePaymentDialog> createState() =>
      _LogReceivablePaymentDialogState();
}

class _LogReceivablePaymentDialogState
    extends State<LogReceivablePaymentDialog> {
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
                        'Record Received Payment',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                      AppSpacing.vXXS,
                      Text(
                        widget.receivable.debtor,
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
                  color: brandColors.receivable.withValues(alpha: 0.1),
                  borderRadius: AppBorderRadius.allM,
                  border: Border.all(
                    color: brandColors.receivable.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Outstanding Balance:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: AppFontWeight.medium,
                      ),
                    ),
                    Text(
                      FinancialNumberFormatter.format(
                        widget.receivable.remainingBalance,
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: AppFontWeight.bold,
                        color: brandColors.receivable,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.vL,
              Text(
                'Amount Received',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: AppFontWeight.semiBold,
                ),
              ),
              AppSpacing.vS,
              CurrencyAmountInput(
                labelText: 'Payment Amount',
                controller: _amountController,
                hintText: '0.00',
              ),
              if (_errorMessage != null) ...[
                AppSpacing.vXS,
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              AppSpacing.vM,
              Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  ActionChip(
                    label: const Text('25%'),
                    onPressed: () => _applyQuickAmount(
                      widget.receivable.remainingBalance * 0.25,
                    ),
                  ),
                  ActionChip(
                    label: const Text('50%'),
                    onPressed: () => _applyQuickAmount(
                      widget.receivable.remainingBalance * 0.50,
                    ),
                  ),
                  ActionChip(
                    label: const Text('Full Settlement'),
                    backgroundColor: brandColors.receivable.withValues(
                      alpha: 0.15,
                    ),
                    side: BorderSide(
                      color: brandColors.receivable.withValues(alpha: 0.4),
                    ),
                    onPressed: () => _applyQuickAmount(
                      widget.receivable.remainingBalance,
                    ),
                  ),
                ],
              ),
              AppSpacing.vXL,
              PrimaryButton(
                text: 'Confirm Payment',
                icon: Icons.check_circle_outline_rounded,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
