import 'package:flutter/material.dart';
import '../../../../shared/design_system/buttons/primary_button.dart';
import '../../../../shared/design_system/inputs/primary_input.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';

/// Modal dialog for recording a new debt or due account in Clearance bucket.
class AddDebtDialog extends StatefulWidget {
  final void Function(String creditor, double totalOwed, double initialPaid) onAddConfirmed;

  const AddDebtDialog({super.key, required this.onAddConfirmed});

  @override
  State<AddDebtDialog> createState() => _AddDebtDialogState();
}

class _AddDebtDialogState extends State<AddDebtDialog> {
  final _creditorController = TextEditingController();
  final _totalController = TextEditingController();
  final _paidController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _creditorController.dispose();
    _totalController.dispose();
    _paidController.dispose();
    super.dispose();
  }

  void _submit() {
    final creditor = _creditorController.text.trim();
    final total = double.tryParse(_totalController.text.replaceAll(',', ''));
    final paid = double.tryParse(_paidController.text.replaceAll(',', '')) ?? 0.0;

    if (creditor.isEmpty) {
      setState(() => _errorMessage = 'Please enter creditor or party name');
      return;
    }
    if (total == null || total <= 0) {
      setState(() => _errorMessage = 'Please enter a valid total debt amount');
      return;
    }

    widget.onAddConfirmed(creditor, total, paid);
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
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Add Clearance Debt',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            AppSpacing.vM,
            PrimaryInput(
              labelText: 'Creditor / Recipient',
              hintText: 'e.g. Kuda, Justin, Palmpay, Mom',
              controller: _creditorController,
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            AppSpacing.vM,
            PrimaryInput(
              labelText: 'Total Debt Owed (NGN)',
              hintText: 'e.g. 100000',
              controller: _totalController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: const Icon(Icons.money_off_rounded),
            ),
            AppSpacing.vM,
            PrimaryInput(
              labelText: 'Amount Already Paid (Optional)',
              hintText: 'e.g. 20000',
              controller: _paidController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: const Icon(Icons.payments_outlined),
            ),
            if (_errorMessage != null) ...[
              AppSpacing.vS,
              Text(
                _errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            AppSpacing.vXL,
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: 'Record Debt Account',
                icon: Icons.check_circle_outline_rounded,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
