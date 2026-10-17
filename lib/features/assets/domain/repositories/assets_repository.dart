import '../entities/assets.dart';

abstract class AssetsRepository {
  Future<Assets> getAssets();
}
