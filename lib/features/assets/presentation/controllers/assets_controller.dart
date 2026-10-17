import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/asset_entity.dart';

/// State notifier managing high-value long-term wealth asset goals.
class AssetsController extends Notifier<List<AssetEntity>> {
  @override
  List<AssetEntity> build() {
    return const [
      AssetEntity(
        id: 'asset_land',
        title: 'Plot of Land (Epe / Ibeju Lekki)',
        targetAmount: 15000000,
        currentAmount: 4500000,
        isCompleted: false,
      ),
      AssetEntity(
        id: 'asset_mac',
        title: 'Apple MacBook Pro M4 Max',
        targetAmount: 3500000,
        currentAmount: 1400000,
        isCompleted: false,
      ),
    ];
  }

  /// Allocates capital towards long term asset acquisition.
  void allocateCapital(String assetId, double amount) {
    state = [
      for (final asset in state)
        if (asset.id == assetId)
          asset.copyWith(
            currentAmount: (asset.currentAmount + amount).clamp(
              0.0,
              asset.targetAmount,
            ),
          )
        else
          asset,
    ];
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
