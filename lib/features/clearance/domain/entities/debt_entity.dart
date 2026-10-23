import 'package:flutter/foundation.dart';

/// Pure domain entity representing a debt or liability in the Debts bucket.
@immutable
class DebtEntity {
  final String id;
  final String creditor;
  final double totalOwed;
  final double amountPaid;
  final double monthlyPayment;
  final bool isCleared;
  final DateTime? dueDate;
  final int sortIndex;

  const DebtEntity({
    required this.id,
    required this.creditor,
    required this.totalOwed,
    required this.amountPaid,
    this.monthlyPayment = 0.0,
    this.isCleared = false,
    this.dueDate,
    this.sortIndex = 0,
  });

  /// Remaining unpaid balance.
  double get remainingAmount => (totalOwed - amountPaid).clamp(0.0, totalOwed);

  /// Fraction completed between 0.0 and 1.0.
  double get progressRatio {
    if (totalOwed <= 0) return 1.0;
    return (amountPaid / totalOwed).clamp(0.0, 1.0);
  }

  /// Percentage completed formatted as integer.
  int get progressPercentage => (progressRatio * 100).round();

  /// Whether a due date is specified.
  bool get hasDueDate => dueDate != null;

  /// Whether the debt is past its due date and still uncleared.
  bool get isOverdue {
    if (!hasDueDate || isCleared || remainingAmount <= 0) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.isBefore(today);
  }

  /// Estimated months left to payoff at current monthly payment.
  int get monthsLeft {
    if (monthlyPayment <= 0 || remainingAmount <= 0) return 0;
    return (remainingAmount / monthlyPayment).ceil();
  }

  /// Days remaining until due date.
  int? get daysUntilDue {
    if (!hasDueDate) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.difference(today).inDays;
  }

  /// Whether the debt is due within the next 7 days.
  bool get isDueSoon {
    if (!hasDueDate || isCleared || remainingAmount <= 0) return false;
    final days = daysUntilDue;
    return days != null && days >= 0 && days <= 7;
  }

  DebtEntity copyWith({
    String? id,
    String? creditor,
    double? totalOwed,
    double? amountPaid,
    double? monthlyPayment,
    bool? isCleared,
    DateTime? dueDate,
    int? sortIndex,
    bool clearDueDate = false,
  }) {
    final updatedPaid = amountPaid ?? this.amountPaid;
    final updatedTotal = totalOwed ?? this.totalOwed;
    final automaticallyCleared =
        updatedPaid >= updatedTotal && updatedTotal > 0;

    return DebtEntity(
      id: id ?? this.id,
      creditor: creditor ?? this.creditor,
      totalOwed: updatedTotal,
      amountPaid: updatedPaid,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      isCleared: isCleared ?? automaticallyCleared,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      sortIndex: sortIndex ?? this.sortIndex,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'creditor': creditor,
    'totalOwed': totalOwed,
    'amountPaid': amountPaid,
    'monthlyPayment': monthlyPayment,
    'isCleared': isCleared,
    'dueDate': dueDate?.toIso8601String(),
    'sortIndex': sortIndex,
  };

  factory DebtEntity.fromMap(Map<String, dynamic> map) => DebtEntity(
    id: map['id'] as String,
    creditor: (map['creditor'] ?? map['name'] ?? '') as String,
    totalOwed: ((map['totalOwed'] ?? map['t'] ?? map['total']) as num)
        .toDouble(),
    amountPaid: ((map['amountPaid'] ?? map['p'] ?? map['paid'] ?? 0.0) as num)
        .toDouble(),
    monthlyPayment:
        ((map['monthlyPayment'] ?? map['m']) as num?)?.toDouble() ?? 0.0,
    isCleared: map['isCleared'] as bool? ?? false,
    dueDate: map['dueDate'] != null
        ? DateTime.tryParse(map['dueDate'] as String)
        : (map['d'] != null ? DateTime.tryParse(map['d'] as String) : null),
    sortIndex: (map['sortIndex'] as num?)?.toInt() ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          creditor == other.creditor &&
          totalOwed == other.totalOwed &&
          amountPaid == other.amountPaid &&
          monthlyPayment == other.monthlyPayment &&
          isCleared == other.isCleared &&
          dueDate == other.dueDate &&
          sortIndex == other.sortIndex;

  @override
  int get hashCode => Object.hash(
    id,
    creditor,
    totalOwed,
    amountPaid,
    monthlyPayment,
    isCleared,
    dueDate,
    sortIndex,
  );
}
