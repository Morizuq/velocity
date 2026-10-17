import '../../domain/entities/milestones.dart';

class MilestonesModel extends Milestones {
  const MilestonesModel();

  factory MilestonesModel.fromJson(Map<String, dynamic> json) {
    return const MilestonesModel();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{};
  }
}
