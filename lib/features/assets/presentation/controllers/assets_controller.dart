import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/shared_prefs_storage.dart';
import '../../domain/entities/asset_entity.dart';

/// State notifier managing high-value long-term wealth asset goals with local persistence.
class AssetsController extends Notifier<List<AssetEntity>> {
  static const _storageKey = 'velocity_assets';

  @override
  List<AssetEntity> build() {
    try {
      final storage = ref.watch(storageServiceProvider);
      final raw = storage.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((e) => AssetEntity.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    return const [];
  }

  void _persist(List<AssetEntity> updated) {
    try {
      final storage = ref.read(storageServiceProvider);
      final encoded = jsonEncode(updated.map((a) => a.toMap()).toList());
      storage.setString(_storageKey, encoded);
    } catch (_) {}
  }

  /// Allocates or adjusts capital towards long-term asset acquisition.
  void allocateCapital(String assetId, double amount) {
    adjustCapital(assetId, amount);
  }

  /// Adjusts capital by a positive or negative delta.
  void adjustCapital(String assetId, double delta) {
    final updated = [
      for (final asset in state)
        if (asset.id == assetId)
          asset.copyWith(
            currentAmount: (asset.currentAmount + delta).clamp(
              0.0,
              asset.targetAmount,
            ),
          )
        else
          asset,
    ];
    state = updated;
    _persist(updated);
  }

  /// Directly overrides the accumulated capital balance.
  void setAssetAmount(String assetId, double newAmount) {
    final updated = [
      for (final asset in state)
        if (asset.id == assetId)
          asset.copyWith(
            currentAmount: newAmount.clamp(0.0, asset.targetAmount),
          )
        else
          asset,
    ];
    state = updated;
    _persist(updated);
  }

  /// Marks an asset as purchased or acquired.
  void markPurchased(String assetId) {
    final updated = [
      for (final asset in state)
        if (asset.id == assetId)
          asset.copyWith(
            currentAmount: asset.targetAmount,
            isCompleted: true,
          )
        else
          asset,
    ];
    state = updated;
    _persist(updated);
  }

  /// Toggles purchased status.
  void togglePurchased(String assetId) {
    final updated = [
      for (final asset in state)
        if (asset.id == assetId)
          asset.copyWith(
            isCompleted: !asset.isCompleted,
            currentAmount: !asset.isCompleted ? asset.targetAmount : asset.currentAmount,
          )
        else
          asset,
    ];
    state = updated;
    _persist(updated);
  }

  /// Adds a new overarching wealth asset.
  void addAsset({
    required String title,
    required double targetAmount,
    double initialAmount = 0.0,
  }) {
    final newAsset = AssetEntity(
      id: 'asset_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      targetAmount: targetAmount,
      currentAmount: initialAmount,
      isCompleted: initialAmount >= targetAmount && targetAmount > 0,
    );
    final updated = [...state, newAsset];
    state = updated;
    _persist(updated);
  }

  /// Deletes an asset.
  void deleteAsset(String assetId) {
    final updated = state.where((a) => a.id != assetId).toList();
    state = updated;
    _persist(updated);
  }
}

final assetsControllerProvider =
    NotifierProvider<AssetsController, List<AssetEntity>>(
  AssetsController.new,
);

/// Provider computing overarching total asset portfolio target.
final totalAssetTargetProvider = Provider<double>((ref) {
  final assets = ref.watch(assetsControllerProvider);
  return assets.fold<double>(0.0, (sum, a) => sum + a.targetAmount);
});

/// Provider computing overarching accumulated asset capital.
final totalAssetSavedProvider = Provider<double>((ref) {
  final assets = ref.watch(assetsControllerProvider);
  return assets.fold<double>(0.0, (sum, a) => sum + a.currentAmount);
});
