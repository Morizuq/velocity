import 'package:flutter/material.dart';
import '../../../../shared/design_system/buttons/primary_button.dart';
import '../../../../shared/design_system/inputs/primary_input.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../../../shared/design_system/tokens/financial_number_formatter.dart';
import '../../domain/entities/milestone_entity.dart';

/// Comprehensive dialog allowing both adding, withdrawing, or directly overriding milestone funds.
class AdjustMilestoneFundDialog extends StatefulWidget {
  final MilestoneEntity milestone;
  final void Function(double delta) onAdjustDelta;
  final void Function(double newTotal) onSetExactTotal;

  const AdjustMilestoneFundDialog({
    super.key,
    required this.milestone,
    required this.onAdjustDelta,
    required this.onSetExactTotal,
  });

  @override
  State<AdjustMilestoneFundDialog> createState() => _AdjustMilestoneFundDialogState();
}

class _AdjustMilestoneFundDialogState extends State<AdjustMilestoneFundDialog> {
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
      widget.onAdjustDelta(delta);
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adjust Milestone Funds',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                    AppSpacing.vXXS,
                    Text(
                      widget.milestone.title,
                      style: theme.textTheme.bodySmall?.copyWith(
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

            // Current state banner
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: brandColors.subtle,
                borderRadius: AppBorderRadius.allM,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Saved',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: AppFontWeight.medium,
                    ),
                  ),
                  Text(
                    FinancialNumberFormatter.format(widget.milestone.currentAmount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: AppFontWeight.bold,
                      color: brandColors.milestone,
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
                  child: _ModeTab(
                    label: '+ Deposit',
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
                  child: _ModeTab(
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
                  child: _ModeTab(
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
                  ? 'New Total Balance (NGN)'
                  : (_isWithdraw ? 'Withdrawal Amount (NGN)' : 'Deposit Amount (NGN)'),
              hintText: _isDirectOverride ? 'e.g. 100000' : 'e.g. 25000',
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Icon(
                _isDirectOverride
                    ? Icons.tune_rounded
                    : (_isWithdraw ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded),
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

            // Quick Chips
            if (!_isDirectOverride) ...[
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _QuickAmountChip(
                    label: _isWithdraw ? '-₦10,000' : '+₦10,000',
                    onTap: () => _applyQuickAmount(10000, isWithdraw: _isWithdraw),
                  ),
                  _QuickAmountChip(
                    label: _isWithdraw ? '-₦50,000' : '+₦50,000',
                    onTap: () => _applyQuickAmount(50000, isWithdraw: _isWithdraw),
                  ),
                  if (_isWithdraw)
                    _QuickAmountChip(
                      label: 'Withdraw All',
                      onTap: () => _applyQuickAmount(widget.milestone.currentAmount, isWithdraw: true),
                      isHighlight: true,
                    )
                  else
                    _QuickAmountChip(
                      label: 'Fill Remaining',
                      onTap: () => _applyQuickAmount(widget.milestone.remainingAmount, isWithdraw: false),
                      isHighlight: true,
                    ),
                ],
              ),
              AppSpacing.vM,
            ],

            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: _isDirectOverride
                    ? 'Update Balance'
                    : (_isWithdraw ? 'Confirm Withdrawal' : 'Confirm Deposit'),
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

class _ModeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _ModeTab({
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
            color: isSelected ? selectedColor : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isHighlight;

  const _QuickAmountChip({
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
            color: isHighlight ? brandColors.accent : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
