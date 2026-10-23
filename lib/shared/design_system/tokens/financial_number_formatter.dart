import 'package:intl/intl.dart';

/// Formatter for Nigerian Naira (₦) currency values with strict en-NG locale formatting.
class FinancialNumberFormatter {
  FinancialNumberFormatter._();

  static final NumberFormat _nairaCurrency = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 0,
  );

  static final NumberFormat _compactCurrency = NumberFormat.compactCurrency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 1,
  );

  /// Formats standard amount: e.g. 650000 -> "₦650,000"
  static String format(num amount, {String? customSymbol}) {
    if (customSymbol != null && customSymbol.isNotEmpty) {
      return NumberFormat.currency(
        locale: 'en_NG',
        symbol: customSymbol,
        decimalDigits: 0,
      ).format(amount);
    }
    return _nairaCurrency.format(amount);
  }

  /// Formats compact amount: e.g. 1500000 -> "₦1.5M"
  static String formatCompact(num amount) {
    return _compactCurrency.format(amount);
  }

  /// Formats a percentage: e.g. 0.75 -> "75%"
  static String formatPercentage(double ratio) {
    return '${(ratio * 100).round()}%';
  }

  /// Formats numeric input into a human-readable scale tracer:
  /// e.g. 500 -> "₦500  •  Hundreds"
  /// e.g. 50000 -> "₦50,000  •  50 Thousand"
  /// e.g. 500000 -> "₦500,000  •  500 Thousand"
  /// e.g. 5000000 -> "₦5,000,000  •  5 Million"
  static String formatScaleTrace(double amount, {String symbol = '₦'}) {
    if (amount <= 0) return '';
    final formatted = format(amount, customSymbol: symbol);
    if (amount < 100) {
      return '$formatted • Tens';
    } else if (amount < 1000) {
      return '$formatted • Hundreds';
    } else if (amount < 1000000) {
      final thousands = amount / 1000;
      final text = thousands % 1 == 0
          ? '${thousands.toInt()} Thousand'
          : '${thousands.toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '')} Thousand';
      return '$formatted • $text';
    } else if (amount < 1000000000) {
      final millions = amount / 1000000;
      final text = millions % 1 == 0
          ? '${millions.toInt()} Million'
          : '${millions.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')} Million';
      return '$formatted • $text';
    } else {
      final billions = amount / 1000000000;
      final text = billions % 1 == 0
          ? '${billions.toInt()} Billion'
          : '${billions.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')} Billion';
      return '$formatted • $text';
    }
  }
}
