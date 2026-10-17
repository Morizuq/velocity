import 'package:intl/intl.dart';

/// Formatter for financial currency values, ensuring consistent presentation.
class FinancialNumberFormatter {
  FinancialNumberFormatter._();

  static final NumberFormat _standardCurrency = NumberFormat.currency(
    symbol: '₦',
    decimalDigits: 0,
  );

  static final NumberFormat _compactCurrency = NumberFormat.compactCurrency(
    symbol: '₦',
    decimalDigits: 1,
  );

  /// Formats standard amount: e.g. 300000 -> "₦300,000"
  static String format(double amount, {String? customSymbol}) {
    if (customSymbol != null && customSymbol.isNotEmpty) {
      return NumberFormat.currency(
        symbol: customSymbol,
        decimalDigits: 0,
      ).format(amount);
    }
    return _standardCurrency.format(amount);
  }

  /// Formats compact amount: e.g. 1500000 -> "₦1.5M"
  static String formatCompact(double amount) {
    return _compactCurrency.format(amount);
  }

  /// Formats a percentage: e.g. 0.75 -> "75%"
  static String formatPercentage(double ratio) {
    return '${(ratio * 100).round()}%';
  }
}
