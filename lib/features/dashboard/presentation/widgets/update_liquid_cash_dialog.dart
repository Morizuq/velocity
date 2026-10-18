import 'package:flutter/material.dart';
import '../../../../shared/design_system/buttons/primary_button.dart';
import '../../../../shared/design_system/inputs/currency_amount_input.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../../shared/design_system/tokens/financial_number_formatter.dart';

/// Modal dialog for updating or recording initial liquid cash balance.
class UpdateLiquidCashDialog extends StatefulWidget {
  final double currentBalance;
  final void Function(double newBalance) onBalanceConfirmed;

  const UpdateLiquidCashDialog({
    super.key,
    required this.currentBalance,
    required this.onBalanceConfirmed,
  });

  @override
  State<UpdateLiquidCashDialog> createState() => _UpdateLiquidCashDialogState();
}

class _UpdateLiquidCashDialogState extends State<UpdateLiquidCashDialog> {
  late final TextEditingController _amountController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.currentBalance > 0
          ? FinancialNumberFormatter.format(
              widget.currentBalance,
            ).replaceAll('₦', '').trim()
          : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = double.tryParse(
      _amountController.text.replaceAll(',', '').trim(),
    );
    if (parsed == null || parsed < 0) {
      setState(() => _errorMessage = 'Please enter a valid cash amount');
      return;
    }

    widget.onBalanceConfirmed(parsed);
    Navigator.of(context).pop();
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
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Available Liquid Cash',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              AppSpacing.vXXS,
              Text(
                'Set your readily spendable capital across checking and physical reserves.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              AppSpacing.vL,
              CurrencyAmountInput(
                labelText: 'Total Liquid Balance (₦)',
                hintText: 'e.g. 500,000',
                controller: _amountController,
                prefixIcon: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 18,
                ),
              ),
              if (_errorMessage != null) ...[
                AppSpacing.vS,
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: brandColors.debt,
                  ),
                ),
              ],
              AppSpacing.vXL,
              PrimaryButton(text: 'Save Available Cash', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
