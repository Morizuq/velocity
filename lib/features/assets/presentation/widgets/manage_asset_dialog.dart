import 'package:flutter/material.dart';
import '../../../../shared/design_system/buttons/primary_button.dart';
import '../../../../shared/design_system/inputs/currency_amount_input.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../domain/entities/asset_entity.dart';
import 'asset_mode_tab.dart';

/// Modal dialog allowing the user to deposit capital, withdraw, set balance, or mark asset as purchased.
class ManageAssetDialog extends StatefulWidget {
  final AssetEntity asset;
  final void Function(double delta) onAdjustCapital;
  final void Function(double newTotal) onSetExactTotal;
  final VoidCallback onTogglePurchased;
  final VoidCallback onDelete;

  const ManageAssetDialog({
    super.key,
    required this.asset,
    required this.onAdjustCapital,
    required this.onSetExactTotal,
    required this.onTogglePurchased,
    required this.onDelete,
  });

  @override
  State<ManageAssetDialog> createState() => _ManageAssetDialogState();
}

class _ManageAssetDialogState extends State<ManageAssetDialog> {
  bool _isWithdraw = false;
  bool _isDirectOverride = false;
  final _amountController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (parsed == null || parsed < 0) {
      setState(() => _errorMessage = 'Please enter a valid amount');
      return;
    }

    if (_isDirectOverride) {
      widget.onSetExactTotal(parsed);
    } else {
      final delta = _isWithdraw ? -parsed : parsed;
      widget.onAdjustCapital(delta);
    }
    Navigator.of(context).pop();
  }

  void _applyQuickAmount(double amount, {bool isWithdraw = false}) {
    setState(() {
      _isDirectOverride = false;
      _isWithdraw = isWithdraw;
      _amountController.text =
          FinancialNumberFormatter.format(amount).replaceAll('₦', '').trim();
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;

    final remaining = (widget.asset.targetAmount - widget.asset.currentAmount)
        .clamp(0.0, widget.asset.targetAmount);

    return Dialog(
      backgroundColor: brandColors.surfaceCard,
      shape: const RoundedRectangleBorder(borderRadius: AppBorderRadius.allXL),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(AppSpacing.l),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Wealth Asset',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                      AppSpacing.vXXS,
                      Text(
                        widget.asset.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            AppSpacing.vM,

            // Quick Purchased Status Toggle Banner
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: widget.asset.isCompleted
                    ? brandColors.progress.withValues(alpha: 0.12)
                    : brandColors.subtle,
                borderRadius: AppBorderRadius.allM,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.asset.isCompleted
                            ? 'Asset Acquired / Purchased'
                            : 'Secured Capital',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: widget.asset.isCompleted
                              ? brandColors.progress
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: AppFontWeight.medium,
                        ),
                      ),
                      AppSpacing.vXXS,
                      Text(
                        FinancialNumberFormatter.format(
                          widget.asset.currentAmount,
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: AppFontWeight.bold,
                          color: widget.asset.isCompleted
                              ? brandColors.progress
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      widget.onTogglePurchased();
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      widget.asset.isCompleted
                          ? Icons.undo_rounded
                          : Icons.verified_rounded,
                      size: 16,
                    ),
                    label: Text(
                      widget.asset.isCompleted
                          ? 'Mark Pending'
                          : 'Mark Purchased',
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.asset.isCompleted
                          ? brandColors.subtle
                          : brandColors.progress.withValues(alpha: 0.18),
                      foregroundColor: widget.asset.isCompleted
                          ? theme.colorScheme.onSurface
                          : brandColors.progress,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppBorderRadius.pill,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s + 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.vM,

            // Operation selector tab
            Row(
              children: [
                Expanded(
                  child: AssetModeTab(
                    label: '+ Add Money',
                    isSelected: !_isWithdraw && !_isDirectOverride,
                    selectedColor: brandColors.progress,
                    onTap: () => setState(() {
                      _isWithdraw = false;
                      _isDirectOverride = false;
                    }),
                  ),
                ),
                AppSpacing.hS,
                Expanded(
                  child: AssetModeTab(
                    label: '- Withdraw',
                    isSelected: _isWithdraw && !_isDirectOverride,
                    selectedColor: brandColors.debt,
                    onTap: () => setState(() {
                      _isWithdraw = true;
                      _isDirectOverride = false;
                    }),
                  ),
                ),
                AppSpacing.hS,
                Expanded(
                  child: AssetModeTab(
                    label: '= Set Total',
                    isSelected: _isDirectOverride,
                    selectedColor: brandColors.accent,
                    onTap: () => setState(() {
                      _isDirectOverride = true;
                    }),
                  ),
                ),
              ],
            ),
            AppSpacing.vM,

            CurrencyAmountInput(
              labelText: _isDirectOverride
                  ? 'New Total Secured Capital (NGN)'
                  : (_isWithdraw
                        ? 'Withdrawal / Reallocation Amount (NGN)'
                        : 'Deposit / Addition Amount (NGN)'),
              hintText: _isDirectOverride ? '5,000,000' : '1,000,000',
              controller: _amountController,
              errorText: _errorMessage,
              prefixIcon: Icon(
                _isDirectOverride
                    ? Icons.tune_rounded
                    : (_isWithdraw
                          ? Icons.remove_circle_outline_rounded
                          : Icons.add_circle_outline_rounded),
                color: _isDirectOverride
                    ? brandColors.accent
                    : (_isWithdraw ? brandColors.debt : brandColors.progress),
              ),
            ),
            AppSpacing.vS,

            // Quick Preset Chips
            if (!_isDirectOverride) ...[
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final amount in const [200000.0, 500000.0, 1000000.0])
                    AssetQuickChip(
                      label:
                          '${_isWithdraw ? '-' : '+'}₦${FinancialNumberFormatter.format(amount).replaceAll('₦', '').trim()}',
                      onTap: () =>
                          _applyQuickAmount(amount, isWithdraw: _isWithdraw),
                    ),
                  if (!_isWithdraw && remaining > 0)
                    AssetQuickChip(
                      label: 'Complete Horizon',
                      onTap: () =>
                          _applyQuickAmount(remaining, isWithdraw: false),
                      isHighlight: true,
                    ),
                ],
              ),
              AppSpacing.vM,
            ],

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: _isDirectOverride
                    ? 'Update Capital Balance'
                    : (_isWithdraw
                          ? 'Confirm Capital Withdrawal'
                          : 'Confirm Capital Addition'),
                icon: Icons.check_circle_outline_rounded,
                onPressed: _submit,
              ),
            ),
            AppSpacing.vS,

            // Delete action
            Center(
              child: TextButton.icon(
                onPressed: () {
                  widget.onDelete();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text(
                  'Delete Asset Goal',
                  style: TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
