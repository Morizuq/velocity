import '../../domain/repositories/assets_repository.dart';
import '../models/assets_model.dart';

class AssetsRepositoryImpl implements AssetsRepository {
  const AssetsRepositoryImpl();

  @override
  Future<AssetsModel> getAssets() async {
    return const AssetsModel();
  }
}
