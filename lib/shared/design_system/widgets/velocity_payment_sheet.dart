import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/velocity_tokens.dart';
import '../buttons/velocity_button.dart';
import '../tokens/app_border_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/financial_number_formatter.dart';

/// Modal bottom sheet allowing partial payment or savings recording with an amount and date field.
class VelocityPaymentSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final double? maxAmount;
  final String actionLabel;
  final void Function(double amount, DateTime date) onConfirm;

  const VelocityPaymentSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.maxAmount,
    this.actionLabel = 'Log payment',
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    double? maxAmount,
    String actionLabel = 'Log payment',
    required void Function(double amount, DateTime date) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VelocityPaymentSheet(
        title: title,
        subtitle: subtitle,
        maxAmount: maxAmount,
        actionLabel: actionLabel,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<VelocityPaymentSheet> createState() => _VelocityPaymentSheetState();
}

class _VelocityPaymentSheetState extends State<VelocityPaymentSheet> {
  final _amountController = TextEditingController();
  late DateTime _selectedDate;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final rawText = _amountController.text.replaceAll(',', '').trim();
    final parsed = double.tryParse(rawText);
    if (parsed == null || parsed <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid amount greater than zero';
      });
      return;
    }

    if (widget.maxAmount != null && parsed > widget.maxAmount!) {
      setState(() {
        _errorMessage =
            'Amount cannot exceed ${FinancialNumberFormatter.format(widget.maxAmount!)}';
      });
      return;
    }

    widget.onConfirm(parsed, _selectedDate);
    Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.l,
        AppSpacing.l,
        AppSpacing.l + bottomInset,
      ),
      decoration: BoxDecoration(
        color: tokens.surfaceColor,
        borderRadius: AppBorderRadius.topSheet,
        border: Border(top: BorderSide(color: tokens.lineColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: tokens.bricolage(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: tokens.muteColor),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 20,
              ),
            ],
          ),
          if (widget.subtitle != null) ...[
            AppSpacing.vXXS,
            Text(
              widget.subtitle!,
              style: tokens.figtree(
                fontSize: 14,
                color: tokens.muteColor,
              ),
            ),
          ],
          AppSpacing.vM,

          // Amount Field
          Text(
            'Amount (₦)',
            style: tokens.figtree(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: tokens.muteColor,
            ),
          ),
          AppSpacing.vXS,
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: tokens.bricolage(fontSize: 18, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              prefixText: '₦ ',
              prefixStyle: tokens.bricolage(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: tokens.inkColor,
              ),
              hintText: '0',
              filled: true,
              fillColor: tokens.bgColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.s,
              ),
              border: OutlineInputBorder(
                borderRadius: AppBorderRadius.allInput,
                borderSide: BorderSide(color: tokens.lineColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppBorderRadius.allInput,
                borderSide: BorderSide(color: tokens.lineColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppBorderRadius.allInput,
                borderSide: BorderSide(color: tokens.accentColor, width: 2),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            AppSpacing.vXS,
            Text(
              _errorMessage!,
              style: tokens.figtree(
                fontSize: 12,
                color: tokens.outColor,
              ),
            ),
          ],
          AppSpacing.vS,

          // Date Field
          Text(
            'Payment Date',
            style: tokens.figtree(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: tokens.muteColor,
            ),
          ),
          AppSpacing.vXS,
          InkWell(
            onTap: _pickDate,
            borderRadius: AppBorderRadius.allInput,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.s,
              ),
              decoration: BoxDecoration(
                color: tokens.bgColor,
                border: Border.all(color: tokens.lineColor),
                borderRadius: AppBorderRadius.allInput,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(_selectedDate),
                    style: tokens.figtree(
                      fontSize: 15,
                      color: tokens.inkColor,
                    ),
                  ),
                  Icon(Icons.calendar_today_rounded, size: 18, color: tokens.muteColor),
                ],
              ),
            ),
          ),
          AppSpacing.vL,

          // Confirm Button
          VelocityButton.primary(
            onPressed: _submit,
            label: widget.actionLabel,
            isFullWidth: true,
            height: 44.0,
          ),
        ],
      ),
    );
  }
}
