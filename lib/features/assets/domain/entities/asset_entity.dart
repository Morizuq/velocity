import 'package:flutter/foundation.dart';

/// Pure domain entity representing overarching long-term wealth goals.
@immutable
class AssetEntity {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final bool isCompleted;

  const AssetEntity({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    this.isCompleted = false,
  });

  /// Fractional progress between 0.0 and 1.0.
  double get progressRatio {
    if (targetAmount <= 0) return 1.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  /// Percentage completed formatted as integer.
  int get progressPercentage => (progressRatio * 100).round();

  AssetEntity copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    bool? isCompleted,
  }) {
    final updatedCurrent = currentAmount ?? this.currentAmount;
    final updatedTarget = targetAmount ?? this.targetAmount;

    return AssetEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: updatedTarget,
      currentAmount: updatedCurrent,
      isCompleted: isCompleted ?? (updatedCurrent >= updatedTarget && updatedTarget > 0),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          targetAmount == other.targetAmount &&
          currentAmount == other.currentAmount &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode => Object.hash(id, title, targetAmount, currentAmount, isCompleted);
}
