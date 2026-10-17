import '../../domain/repositories/dashboard_repository.dart';
import '../models/dashboard_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl();

  @override
  Future<DashboardModel> getDashboard() async {
    return const DashboardModel();
  }
}
