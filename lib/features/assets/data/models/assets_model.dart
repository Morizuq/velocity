import '../../domain/entities/assets.dart';

class AssetsModel extends Assets {
  const AssetsModel();

  factory AssetsModel.fromJson(Map<String, dynamic> json) {
    return const AssetsModel();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{};
  }
}
