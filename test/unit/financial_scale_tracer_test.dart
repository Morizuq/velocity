import 'package:flutter_test/flutter_test.dart';
import 'package:velocity/shared/design_system/tokens/financial_number_formatter.dart';
import 'package:velocity/shared/design_system/inputs/thousands_separator_input_formatter.dart';
import 'package:flutter/services.dart';

void main() {
  group('FinancialNumberFormatter.formatScaleTrace', () {
    test('returns empty for non-positive amounts', () {
      expect(FinancialNumberFormatter.formatScaleTrace(0), isEmpty);
      expect(FinancialNumberFormatter.formatScaleTrace(-500), isEmpty);
    });

    test('traces hundreds correctly', () {
      expect(
        FinancialNumberFormatter.formatScaleTrace(50),
        equals('₦50 • Tens'),
      );
      expect(
        FinancialNumberFormatter.formatScaleTrace(500),
        equals('₦500 • Hundreds'),
      );
      expect(
        FinancialNumberFormatter.formatScaleTrace(999),
        equals('₦999 • Hundreds'),
      );
    });

    test('traces thousands correctly with readable magnitude', () {
      expect(
        FinancialNumberFormatter.formatScaleTrace(1000),
        equals('₦1,000 • 1 Thousand'),
      );
      expect(
        FinancialNumberFormatter.formatScaleTrace(50000),
        equals('₦50,000 • 50 Thousand'),
      );
      expect(
        FinancialNumberFormatter.formatScaleTrace(500000),
        equals('₦500,000 • 500 Thousand'),
      );
      expect(
        FinancialNumberFormatter.formatScaleTrace(750000),
        equals('₦750,000 • 750 Thousand'),
      );
    });

    test('traces millions correctly with decimal precision when needed', () {
      expect(
        FinancialNumberFormatter.formatScaleTrace(1000000),
        equals('₦1,000,000 • 1 Million'),
      );
      expect(
        FinancialNumberFormatter.formatScaleTrace(5000000),
        equals('₦5,000,000 • 5 Million'),
      );
      expect(
        FinancialNumberFormatter.formatScaleTrace(2500000),
        equals('₦2,500,000 • 2.5 Million'),
      );
      expect(
        FinancialNumberFormatter.formatScaleTrace(15000000),
        equals('₦15,000,000 • 15 Million'),
      );
    });

    test('traces billions correctly', () {
      expect(
        FinancialNumberFormatter.formatScaleTrace(1000000000),
        equals('₦1,000,000,000 • 1 Billion'),
      );
      expect(
        FinancialNumberFormatter.formatScaleTrace(1200000000),
        equals('₦1,200,000,000 • 1.2 Billion'),
      );
    });
  });

  group('ThousandsSeparatorInputFormatter', () {
    final formatter = ThousandsSeparatorInputFormatter();

    test('formats unformatted digits with thousands separators', () {
      const oldValue = TextEditingValue(text: '50000');
      const newValue = TextEditingValue(
        text: '500000',
        selection: TextSelection.collapsed(offset: 6),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, equals('500,000'));
    });

    test('preserves decimals properly', () {
      const oldValue = TextEditingValue(text: '5000');
      const newValue = TextEditingValue(
        text: '5000.50',
        selection: TextSelection.collapsed(offset: 7),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, equals('5,000.50'));
    });

    test('handles backspacing over comma seamlessly', () {
      // User is at 1,|000 and presses backspace
      const oldValue = TextEditingValue(
        text: '1,000',
        selection: TextSelection.collapsed(offset: 2),
      );
      // Backspace deleted the comma: text becomes '1000' with cursor at 1
      const newValue = TextEditingValue(
        text: '1000',
        selection: TextSelection.collapsed(offset: 1),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      // Smart backspace should delete the preceding digit '1' -> '000'
      expect(result.text, equals('0'));
    });
  });
}
