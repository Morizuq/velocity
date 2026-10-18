import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formats numeric inputs with thousand separators (e.g. 500000 -> 500,000)
/// in real time, supporting optional decimals, maintaining accurate cursor positions,
/// and ensuring smooth backspace behavior.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static final NumberFormat _formatter = NumberFormat('#,###');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final hasDot = newValue.text.contains('.');
    final parts = newValue.text.split('.');
    if (parts.length > 2) {
      return oldValue;
    }

    final rawInteger = parts[0].replaceAll(RegExp(r'[^\d]'), '');
    final rawDecimal =
        hasDot ? parts[1].replaceAll(RegExp(r'[^\d]'), '') : null;

    if (rawInteger.isEmpty &&
        (rawDecimal == null || rawDecimal.isEmpty) &&
        !hasDot) {
      return const TextEditingValue(text: '');
    }

    // Handle smart backspace over comma in integer part
    String effectiveInteger = rawInteger;
    if (oldValue.text.length > newValue.text.length) {
      final oldSelectionEnd = oldValue.selection.end;
      if (oldSelectionEnd > 0 &&
          oldSelectionEnd <= oldValue.text.length &&
          oldValue.text[oldSelectionEnd - 1] == ',') {
        final oldDigitsBefore = oldValue.text
            .substring(0, oldSelectionEnd - 1)
            .replaceAll(RegExp(r'[^\d]'), '');
        final oldDigitsAfter = oldValue.text
            .substring(oldSelectionEnd)
            .replaceAll(RegExp(r'[^\d]'), '');
        if (oldDigitsBefore.isNotEmpty) {
          effectiveInteger =
              oldDigitsBefore.substring(0, oldDigitsBefore.length - 1) +
              oldDigitsAfter;
        }
      }
    }

    // Clamp integer to 15 digits (up to 999 Trillion)
    final clampedInteger = effectiveInteger.length > 15
        ? effectiveInteger.substring(0, 15)
        : effectiveInteger;

    String formattedInteger = '';
    if (clampedInteger.isNotEmpty) {
      final number = int.tryParse(clampedInteger);
      if (number != null) {
        formattedInteger = _formatter.format(number);
      }
    } else if (hasDot) {
      formattedInteger = '0';
    }

    String formattedText;
    if (hasDot) {
      final clampedDecimal = (rawDecimal != null && rawDecimal.length > 2)
          ? rawDecimal.substring(0, 2)
          : (rawDecimal ?? '');
      formattedText = '$formattedInteger.$clampedDecimal';
    } else {
      formattedText = formattedInteger;
    }

    // Compute cursor offset based on characters before cursor
    if (newValue.selection.end >= newValue.text.length) {
      return TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
    }

    // For mid-text editing, compute based on digit count before cursor
    final newDigitsBeforeCursor = newValue.text
        .substring(0, newValue.selection.end.clamp(0, newValue.text.length))
        .replaceAll(RegExp(r'[^\d.]'), '')
        .length;

    int cursorOffset = 0;
    int digitCount = 0;
    for (int i = 0; i < formattedText.length; i++) {
      if (formattedText[i] != ',') {
        digitCount++;
      }
      if (digitCount == newDigitsBeforeCursor) {
        cursorOffset = i + 1;
        break;
      }
    }

    if (cursorOffset == 0 && newDigitsBeforeCursor > 0) {
      cursorOffset = formattedText.length;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(
        offset: cursorOffset.clamp(0, formattedText.length),
      ),
    );
  }
}
