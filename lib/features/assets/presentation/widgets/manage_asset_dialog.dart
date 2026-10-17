import 'package:flutter/material.dart';
import '../../../../shared/design_system/buttons/primary_button.dart';
import '../../../../shared/design_system/inputs/primary_input.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../domain/entities/asset_entity.dart';

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
      _amountController.text = amount.toStringAsFixed(0);
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
                  child: _AssetModeTab(
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
                  child: _AssetModeTab(
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
                  child: _AssetModeTab(
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

            PrimaryInput(
              labelText: _isDirectOverride
                  ? 'New Total Secured Capital (NGN)'
                  : (_isWithdraw
                        ? 'Withdrawal / Reallocation Amount (NGN)'
                        : 'Deposit / Addition Amount (NGN)'),
              hintText: _isDirectOverride ? 'e.g. 5000000' : 'e.g. 1000000',
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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

            // Quick Preset Chips
            if (!_isDirectOverride) ...[
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _QuickAssetChip(
                    label: _isWithdraw ? '-₦200,000' : '+₦200,000',
                    onTap: () =>
                        _applyQuickAmount(200000, isWithdraw: _isWithdraw),
                  ),
                  _QuickAssetChip(
                    label: _isWithdraw ? '-₦500,000' : '+₦500,000',
                    onTap: () =>
                        _applyQuickAmount(500000, isWithdraw: _isWithdraw),
                  ),
                  _QuickAssetChip(
                    label: _isWithdraw ? '-₦1,000,000' : '+₦1,000,000',
                    onTap: () =>
                        _applyQuickAmount(1000000, isWithdraw: _isWithdraw),
                  ),
                  if (!_isWithdraw && remaining > 0)
                    _QuickAssetChip(
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
    );
  }
}

class _AssetModeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _AssetModeTab({
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AppBorderRadius.allM,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: AppBorderRadius.allM,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: isSelected ? AppFontWeight.bold : AppFontWeight.medium,
            color: isSelected
                ? selectedColor
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _QuickAssetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isHighlight;

  const _QuickAssetChip({
    required this.label,
    required this.onTap,
    this.isHighlight = false,
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
          color: isHighlight
              ? brandColors.subtle
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: AppBorderRadius.pill,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: AppFontWeight.medium,
            color: isHighlight
                ? brandColors.accent
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
