import 'package:flutter/material.dart';
import '../tokens/app_border_radius.dart';
import '../tokens/app_font_weight.dart';
import '../tokens/app_spacing.dart';
import '../tokens/brand_colors.dart';
import '../tokens/financial_number_formatter.dart';
import 'primary_input.dart';
import 'thousands_separator_input_formatter.dart';

/// Specialized currency input field featuring real-time thousands formatting
/// and a visual scale tracer badge so users can instantly trace hundreds,
/// thousands, millions, and billions without miscounting zeroes.
class CurrencyAmountInput extends StatefulWidget {
  final String labelText;
  final String? hintText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Widget? prefixIcon;
  final String currencySymbol;
  final String? errorText;

  const CurrencyAmountInput({
    super.key,
    required this.labelText,
    this.hintText,
    required this.controller,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.currencySymbol = '₦',
    this.errorText,
  });

  @override
  State<CurrencyAmountInput> createState() => _CurrencyAmountInputState();
}

class _CurrencyAmountInputState extends State<CurrencyAmountInput> {
  String _scaleTrace = '';

  @override
  void initState() {
    super.initState();
    _updateScaleTrace(widget.controller.text);
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(covariant CurrencyAmountInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChange);
      widget.controller.addListener(_handleControllerChange);
      _updateScaleTrace(widget.controller.text);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    super.dispose();
  }

  void _handleControllerChange() {
    _updateScaleTrace(widget.controller.text);
  }

  void _updateScaleTrace(String text) {
    final clean = text.replaceAll(',', '').trim();
    final amount = double.tryParse(clean) ?? 0.0;
    final trace = FinancialNumberFormatter.formatScaleTrace(
      amount,
      symbol: widget.currencySymbol,
    );
    if (trace != _scaleTrace) {
      setState(() {
        _scaleTrace = trace;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandColors = context.brandColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryInput(
          labelText: widget.labelText,
          hintText: widget.hintText ?? 'e.g. 500,000',
          controller: widget.controller,
          validator: widget.validator,
          errorText: widget.errorText,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [ThousandsSeparatorInputFormatter()],
          onChanged: (val) {
            _updateScaleTrace(val);
            widget.onChanged?.call(val);
          },
          prefixIcon:
              widget.prefixIcon ??
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.m,
                  right: AppSpacing.xs,
                ),
                child: Center(
                  widthFactor: 1.0,
                  child: Text(
                    widget.currencySymbol,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: AppFontWeight.bold,
                      color: brandColors.accent,
                    ),
                  ),
                ),
              ),
        ),
        if (_scaleTrace.isNotEmpty) ...[
          AppSpacing.vXS,
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s + 2,
              vertical: AppSpacing.xxs + 2,
            ),
            decoration: BoxDecoration(
              color: brandColors.accent.withValues(alpha: 0.10),
              borderRadius: AppBorderRadius.pill,
              border: Border.all(
                color: brandColors.accent.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  size: 13,
                  color: brandColors.accent,
                ),
                AppSpacing.hXS,
                Text(
                  _scaleTrace,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: AppFontWeight.bold,
                    color: brandColors.accent,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
