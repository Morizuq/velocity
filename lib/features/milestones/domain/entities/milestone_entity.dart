import 'package:flutter/foundation.dart';

/// Pure domain entity representing a savings goal or milestone in the Goals bucket.
@immutable
class MilestoneEntity {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final bool isCompleted;
  final int sortIndex;

  const MilestoneEntity({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    this.isCompleted = false,
    this.sortIndex = 0,
  });

  /// Remaining amount needed to fulfill this goal.
  double get remainingAmount =>
      (targetAmount - currentAmount).clamp(0.0, targetAmount);

  /// Fractional progress between 0.0 and 1.0.
  double get progressRatio {
    if (targetAmount <= 0) return 1.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  /// Percentage completed formatted as integer.
  int get progressPercentage => (progressRatio * 100).round();

  MilestoneEntity copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    bool? isCompleted,
    int? sortIndex,
  }) {
    final updatedCurrent = currentAmount ?? this.currentAmount;
    final updatedTarget = targetAmount ?? this.targetAmount;
    final automaticallyCompleted =
        updatedCurrent >= updatedTarget && updatedTarget > 0;

    return MilestoneEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: updatedTarget,
      currentAmount: updatedCurrent,
      isCompleted: isCompleted ?? automaticallyCompleted,
      sortIndex: sortIndex ?? this.sortIndex,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'targetAmount': targetAmount,
    'currentAmount': currentAmount,
    'isCompleted': isCompleted,
    'sortIndex': sortIndex,
  };

  factory MilestoneEntity.fromMap(Map<String, dynamic> map) => MilestoneEntity(
    id: map['id'] as String,
    title: (map['title'] ?? map['n'] ?? map['name'] ?? '') as String,
    targetAmount: ((map['targetAmount'] ?? map['t'] ?? map['target'] ?? 0.0) as num).toDouble(),
    currentAmount: ((map['currentAmount'] ?? map['p'] ?? map['saved'] ?? 0.0) as num).toDouble(),
    isCompleted: map['isCompleted'] as bool? ?? false,
    sortIndex: (map['sortIndex'] as num?)?.toInt() ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MilestoneEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          targetAmount == other.targetAmount &&
          currentAmount == other.currentAmount &&
          isCompleted == other.isCompleted &&
          sortIndex == other.sortIndex;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    targetAmount,
    currentAmount,
    isCompleted,
    sortIndex,
  );
}
