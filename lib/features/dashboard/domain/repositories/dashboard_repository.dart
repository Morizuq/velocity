import '../entities/dashboard.dart';

abstract class DashboardRepository {
  Future<Dashboard> getDashboard();
}
