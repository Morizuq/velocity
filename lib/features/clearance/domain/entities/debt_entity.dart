import 'package:flutter/foundation.dart';

/// Pure domain entity representing a debt or immediate due in the Clearance bucket.
@immutable
class DebtEntity {
  final String id;
  final String creditor;
  final double totalOwed;
  final double amountPaid;
  final bool isCleared;
  final DateTime? dueDate;

  const DebtEntity({
    required this.id,
    required this.creditor,
    required this.totalOwed,
    required this.amountPaid,
    this.isCleared = false,
    this.dueDate,
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
  bool get isOverdue =>
      hasDueDate && !isCleared && dueDate!.isBefore(DateTime.now());

  /// Whether the debt is due within the next 7 days.
  bool get isDueSoon {
    if (!hasDueDate || isCleared || isOverdue) return false;
    final diff = dueDate!.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 7;
  }

  /// Days remaining until due date.
  int? get daysUntilDue {
    if (!hasDueDate) return null;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  DebtEntity copyWith({
    String? id,
    String? creditor,
    double? totalOwed,
    double? amountPaid,
    bool? isCleared,
    DateTime? dueDate,
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
      isCleared: isCleared ?? automaticallyCleared,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'creditor': creditor,
    'totalOwed': totalOwed,
    'amountPaid': amountPaid,
    'isCleared': isCleared,
    'dueDate': dueDate?.toIso8601String(),
  };

  factory DebtEntity.fromMap(Map<String, dynamic> map) => DebtEntity(
    id: map['id'] as String,
    creditor: map['creditor'] as String,
    totalOwed: (map['totalOwed'] as num).toDouble(),
    amountPaid: (map['amountPaid'] as num).toDouble(),
    isCleared: map['isCleared'] as bool? ?? false,
    dueDate: map['dueDate'] != null
        ? DateTime.tryParse(map['dueDate'] as String)
        : null,
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
          isCleared == other.isCleared &&
          dueDate == other.dueDate;

  @override
  int get hashCode =>
      Object.hash(id, creditor, totalOwed, amountPaid, isCleared, dueDate);
}
