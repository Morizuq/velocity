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
import '../../domain/entities/receivable_type.dart';

/// Modal dialog for recording a new receivable (freelance invoice, personal loan, reimbursement)
/// with structured, sensible fields and pinned header layout.
class AddReceivableDialog extends StatefulWidget {
  final void Function({
    required String debtor,
    required double totalAmount,
    required double initialReceived,
    required ReceivableType type,
    DateTime? dueDate,
    String? description,
    String? invoiceNumber,
    String? notes,
  })
  onAddConfirmed;

  const AddReceivableDialog({super.key, required this.onAddConfirmed});

  @override
  State<AddReceivableDialog> createState() => _AddReceivableDialogState();
}

class _AddReceivableDialogState extends State<AddReceivableDialog> {
  final _debtorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalController = TextEditingController();
  final _receivedController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _notesController = TextEditingController();
  ReceivableType _selectedType = ReceivableType.freelanceInvoice;
  DateTime? _selectedDueDate;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDueDate = DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _debtorController.dispose();
    _descriptionController.dispose();
    _totalController.dispose();
    _receivedController.dispose();
    _invoiceNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now.add(const Duration(days: 30)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  void _submit() {
    final debtor = _debtorController.text.trim();
    final total = double.tryParse(_totalController.text.replaceAll(',', ''));
    final received =
        double.tryParse(_receivedController.text.replaceAll(',', '')) ?? 0.0;

    if (debtor.isEmpty) {
      setState(
        () => _errorMessage = _selectedType == ReceivableType.freelanceInvoice
            ? 'Please enter client or company name'
            : 'Please enter borrower / debtor name',
      );
      return;
    }
    if (total == null || total <= 0) {
      setState(() => _errorMessage = 'Please enter a valid total amount');
      return;
    }

    widget.onAddConfirmed(
      debtor: debtor,
      totalAmount: total,
      initialReceived: received,
      type: _selectedType,
      dueDate: _selectedDueDate,
      description: _descriptionController.text.trim(),
      invoiceNumber: _invoiceNumberController.text.trim(),
      notes: _notesController.text.trim(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;
    final maxDialogHeight = MediaQuery.sizeOf(context).height * 0.88;

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
            // Pinned Header (Never scrolled or pushed out of view)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedType == ReceivableType.freelanceInvoice
                        ? 'New Freelance Invoice'
                        : _selectedType == ReceivableType.personalLoan
                        ? 'Record Personal Loan'
                        : 'Record Reimbursement',
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
              _selectedType == ReceivableType.freelanceInvoice
                  ? 'Record a client invoice, track project scope, milestone payments, and due dates.'
                  : 'Track money owed to you with expected return dates and settlement history.',
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
                    // Claim Type Pill Selector
                    Text(
                      'Claim Type',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: AppFontWeight.semiBold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.vXS,
                    Wrap(
                      spacing: AppSpacing.s,
                      runSpacing: AppSpacing.xs,
                      children: ReceivableType.values.map((type) {
                        final isSelected = _selectedType == type;
                        return VelocityPillFilter(
                          label: type.displayName,
                          isSelected: isSelected,
                          activeColor: brandColors.receivable,
                          onTap: () => setState(() => _selectedType = type),
                        );
                      }).toList(),
                    ),
                    AppSpacing.vM,

                    // Client / Debtor Name
                    PrimaryInput(
                      labelText:
                          _selectedType == ReceivableType.freelanceInvoice
                          ? 'Client / Company Name'
                          : _selectedType == ReceivableType.personalLoan
                          ? 'Borrower / Debtor Name'
                          : 'Owed By (Company / Person)',
                      hintText: _selectedType == ReceivableType.freelanceInvoice
                          ? 'e.g. Acme Studio LLC'
                          : 'e.g. John Doe',
                      controller: _debtorController,
                    ),
                    AppSpacing.vM,

                    // Project / Service Description
                    PrimaryInput(
                      labelText:
                          _selectedType == ReceivableType.freelanceInvoice
                          ? 'Project / Scope Description'
                          : 'Purpose / Description (Optional)',
                      hintText: _selectedType == ReceivableType.freelanceInvoice
                          ? 'e.g. Mobile App UI/UX Redesign & API Integration'
                          : 'e.g. Emergency laptop repair loan',
                      controller: _descriptionController,
                    ),
                    AppSpacing.vM,

                    // Optional Invoice Reference
                    if (_selectedType == ReceivableType.freelanceInvoice) ...[
                      PrimaryInput(
                        labelText: 'Invoice Number / Reference (Optional)',
                        hintText: 'e.g. INV-2026-001',
                        controller: _invoiceNumberController,
                      ),
                      AppSpacing.vM,
                    ],

                    // Total Amount
                    CurrencyAmountInput(
                      labelText:
                          _selectedType == ReceivableType.freelanceInvoice
                          ? 'Total Invoiced Amount'
                          : 'Total Amount Lent / Claimed',
                      controller: _totalController,
                      hintText: '0.00',
                    ),
                    AppSpacing.vM,

                    // Deposit / Already Received
                    CurrencyAmountInput(
                      labelText:
                          _selectedType == ReceivableType.freelanceInvoice
                          ? 'Deposit / Upfront Paid (Optional)'
                          : 'Amount Repaid So Far (Optional)',
                      controller: _receivedController,
                      hintText: '0.00',
                    ),
                    AppSpacing.vM,

                    // Expected Due Date
                    Text(
                      _selectedType == ReceivableType.freelanceInvoice
                          ? 'Payment Due Date'
                          : 'Target Repayment Date',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.vXXS,
                    InkWell(
                      onTap: _pickDueDate,
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
                            color: _selectedDueDate != null
                                ? brandColors.receivable.withValues(alpha: 0.5)
                                : theme.dividerColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: _selectedDueDate != null
                                  ? brandColors.receivable
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            AppSpacing.hS,
                            Expanded(
                              child: Text(
                                _selectedDueDate != null
                                    ? 'Due Date: ${DateFormat.yMMMd().format(_selectedDueDate!)}'
                                    : 'Set Due Date (Optional)',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _selectedDueDate != null
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.7),
                                  fontWeight: _selectedDueDate != null
                                      ? AppFontWeight.semiBold
                                      : AppFontWeight.regular,
                                ),
                              ),
                            ),
                            if (_selectedDueDate != null)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16),
                                onPressed: () =>
                                    setState(() => _selectedDueDate = null),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      ),
                    ),
                    AppSpacing.vM,

                    // Terms / Notes
                    PrimaryInput(
                      labelText:
                          _selectedType == ReceivableType.freelanceInvoice
                          ? 'Payment Terms / Notes (Optional)'
                          : 'Additional Notes (Optional)',
                      hintText: _selectedType == ReceivableType.freelanceInvoice
                          ? 'e.g. Net 15 days, 50% upon delivery'
                          : 'e.g. Repayment via bank transfer',
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
                        text: _selectedType == ReceivableType.freelanceInvoice
                            ? 'Save Freelance Invoice'
                            : 'Save Claim',
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
