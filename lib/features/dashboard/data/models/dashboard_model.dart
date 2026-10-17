import '../../domain/entities/dashboard.dart';

class DashboardModel extends Dashboard {
  const DashboardModel();

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return const DashboardModel();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{};
  }
}
