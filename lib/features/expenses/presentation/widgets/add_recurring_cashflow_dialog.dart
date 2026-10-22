import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/design_system/buttons/primary_button.dart';
import '../../../../shared/design_system/buttons/velocity_pill_filter.dart';
import '../../../../shared/design_system/inputs/currency_amount_input.dart';
import '../../../../shared/design_system/inputs/primary_input.dart';
import '../../../../shared/design_system/tokens/app_border_radius.dart';
import '../../../../shared/design_system/tokens/app_font_weight.dart';
import '../../../../shared/design_system/tokens/app_spacing.dart';
import '../../../../shared/design_system/tokens/brand_colors.dart';
import '../../domain/entities/cashflow_direction.dart';

/// Modal dialog for recording a new recurring monthly subscription, bill, or salary
/// featuring pinned header layout and pill selection filters.
class AddRecurringCashflowDialog extends StatefulWidget {
  final CashflowDirection? initialDirection;
  final void Function({
    required String title,
    required double amount,
    required CashflowDirection direction,
    required int dayOfMonth,
    required String category,
    DateTime? endDate,
    String? notes,
  })
  onAddConfirmed;

  const AddRecurringCashflowDialog({
    super.key,
    this.initialDirection,
    required this.onAddConfirmed,
  });

  @override
  State<AddRecurringCashflowDialog> createState() =>
      _AddRecurringCashflowDialogState();
}

class _AddRecurringCashflowDialogState
    extends State<AddRecurringCashflowDialog> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  late CashflowDirection _selectedDirection;
  int _selectedDay = 1;
  String _selectedCategory = 'Subscription';
  String? _errorMessage;

  final List<String> _commonOutflowCategories = const [
    'Subscription',
    'Utility',
    'Housing',
    'Software',
    'Telecom',
  ];

  final List<String> _commonInflowCategories = const [
    'Salary',
    'Retainer',
    'Rental Income',
    'Stipend',
  ];

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDirection =
        widget.initialDirection ?? CashflowDirection.outflowPayable;
    _selectedCategory = _selectedDirection == CashflowDirection.outflowPayable
        ? 'Subscription'
        : 'Salary';
    _selectedDay = _selectedDate.day;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedDay = picked.day;
      });
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));

    if (title.isEmpty) {
      setState(() => _errorMessage = 'Please enter a title or service name');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid monthly amount');
      return;
    }

    widget.onAddConfirmed(
      title: title,
      amount: amount,
      direction: _selectedDirection,
      dayOfMonth: _selectedDay,
      category: _selectedCategory,
      notes: _notesController.text.trim(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final maxDialogHeight = MediaQuery.sizeOf(context).height * 0.88;
    final activeCategories =
        _selectedDirection == CashflowDirection.outflowPayable
        ? _commonOutflowCategories
        : _commonInflowCategories;

    final activeThemeColor =
        _selectedDirection == CashflowDirection.outflowPayable
        ? brandColors.debt
        : brandColors.progress;

    return Dialog(
      backgroundColor: brandColors.surfaceCard,
      shape: const RoundedRectangleBorder(borderRadius: AppBorderRadius.allXL),
      child: Container(
        constraints: BoxConstraints(maxWidth: 460, maxHeight: maxDialogHeight),
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pinned Header (Always visible, never clipped)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedDirection == CashflowDirection.outflowPayable
                        ? 'Add Subscription / Bill'
                        : 'Add Recurring Income',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                ),
              ],
            ),
            AppSpacing.vXXS,
            Text(
              'Track monthly recurring commitments (Spotify, Internet, Rent) or recurring income (Salary, Retainers).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.vM,

            // Scrollable Form Body
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pill Direction Switcher
                    Row(
                      children: [
                        Expanded(
                          child: VelocityPillFilter(
                            label: 'Monthly Payable / Bill',
                            icon: Icons.credit_card_rounded,
                            isSelected:
                                _selectedDirection ==
                                CashflowDirection.outflowPayable,
                            activeColor: brandColors.debt,
                            onTap: () {
                              setState(() {
                                _selectedDirection =
                                    CashflowDirection.outflowPayable;
                                _selectedCategory = 'Subscription';
                              });
                            },
                          ),
                        ),
                        AppSpacing.hS,
                        Expanded(
                          child: VelocityPillFilter(
                            label: 'Monthly Inflow / Income',
                            icon: Icons.payments_rounded,
                            isSelected:
                                _selectedDirection ==
                                CashflowDirection.inflowReceivable,
                            activeColor: brandColors.progress,
                            onTap: () {
                              setState(() {
                                _selectedDirection =
                                    CashflowDirection.inflowReceivable;
                                _selectedCategory = 'Salary';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vM,

                    // Commitment Title (Single clean headline)
                    PrimaryInput(
                      labelText:
                          _selectedDirection == CashflowDirection.outflowPayable
                          ? 'Commitment / Service Name'
                          : 'Income Source / Employer',
                      hintText:
                          _selectedDirection == CashflowDirection.outflowPayable
                          ? 'e.g. Spotify, Internet (Fiber), Rent'
                          : 'e.g. Primary Tech Salary, Client Retainer',
                      controller: _titleController,
                    ),
                    AppSpacing.vM,

                    // Monthly Amount (Single clean headline)
                    CurrencyAmountInput(
                      labelText: 'Monthly Amount',
                      controller: _amountController,
                      hintText: '0.00',
                    ),
                    AppSpacing.vM,

                    // Billing / Due Date Selector
                    Text(
                      _selectedDirection == CashflowDirection.outflowPayable
                          ? 'Billing / Due Date'
                          : 'Payment / Deposit Date',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.vXXS,
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: AppBorderRadius.allM,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                          vertical: AppSpacing.s + 3,
                        ),
                        decoration: BoxDecoration(
                          color: brandColors.subtle,
                          borderRadius: AppBorderRadius.allM,
                          border: Border.all(
                            color: activeThemeColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: activeThemeColor,
                            ),
                            AppSpacing.hS,
                            Expanded(
                              child: Text(
                                'Due Date: ${DateFormat.yMMMd().format(_selectedDate)} (Day $_selectedDay of month)',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: AppFontWeight.semiBold,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.edit_calendar_rounded,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AppSpacing.vM,

                    // Category Pill Chips
                    Text(
                      'Category',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: AppFontWeight.semiBold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.vXS,
                    Wrap(
                      spacing: AppSpacing.s,
                      runSpacing: AppSpacing.xs,
                      children: activeCategories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return VelocityPillFilter(
                          label: cat,
                          isSelected: isSelected,
                          activeColor: activeThemeColor,
                          onTap: () => setState(() => _selectedCategory = cat),
                        );
                      }).toList(),
                    ),
                    AppSpacing.vM,

                    // Optional Notes
                    PrimaryInput(
                      labelText: 'Notes (Optional)',
                      hintText: 'e.g. Plan renewed annually, family plan split',
                      controller: _notesController,
                    ),

                    if (_errorMessage != null) ...[
                      AppSpacing.vM,
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
                        text:
                            _selectedDirection ==
                                CashflowDirection.outflowPayable
                            ? 'Save Subscription / Bill'
                            : 'Save Recurring Income',
                        icon: Icons.check_circle_outline_rounded,
                        onPressed: _submit,
                      ),
                    ),
                    AppSpacing.vS,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
