import '../entities/dashboard.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardUseCase {
  final DashboardRepository repository;

  const GetDashboardUseCase(this.repository);

  Future<Dashboard> execute() {
    return repository.getDashboard();
  }
}
