import 'package:flutter/material.dart';
import '../../../../shared/design_system/buttons/primary_button.dart';
import '../../../../shared/design_system/inputs/primary_input.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';

/// Modal dialog for adding a new planned milestone goal.
class AddMilestoneDialog extends StatefulWidget {
  final void Function(String title, double targetAmount, double initialAmount) onAddConfirmed;

  const AddMilestoneDialog({super.key, required this.onAddConfirmed});

  @override
  State<AddMilestoneDialog> createState() => _AddMilestoneDialogState();
}

class _AddMilestoneDialogState extends State<AddMilestoneDialog> {
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  final _initialController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _initialController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final target = double.tryParse(_targetController.text.replaceAll(',', ''));
    final initial = double.tryParse(_initialController.text.replaceAll(',', '')) ?? 0.0;

    if (title.isEmpty) {
      setState(() => _errorMessage = 'Please enter a goal title');
      return;
    }
    if (target == null || target <= 0) {
      setState(() => _errorMessage = 'Please enter a valid target budget');
      return;
    }

    widget.onAddConfirmed(title, target, initial);
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
                    'Add Milestone Goal',
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
              labelText: 'Goal Title',
              hintText: 'e.g. Ergonomic Standing Desk, Gym Membership',
              controller: _titleController,
              prefixIcon: const Icon(Icons.flag_outlined),
            ),
            AppSpacing.vM,
            PrimaryInput(
              labelText: 'Target Budget (NGN)',
              hintText: 'e.g. 200000',
              controller: _targetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: const Icon(Icons.savings_outlined),
            ),
            AppSpacing.vM,
            PrimaryInput(
              labelText: 'Initial Capital Saved (Optional)',
              hintText: 'e.g. 50000',
              controller: _initialController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
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
                text: 'Create Milestone',
                icon: Icons.check_rounded,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
