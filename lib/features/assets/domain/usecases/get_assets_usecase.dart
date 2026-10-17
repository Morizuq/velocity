import '../entities/assets.dart';
import '../repositories/assets_repository.dart';

class GetAssetsUseCase {
  final AssetsRepository repository;

  const GetAssetsUseCase(this.repository);

  Future<Assets> execute() {
    return repository.getAssets();
  }
}
