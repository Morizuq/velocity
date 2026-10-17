import '../entities/clearance.dart';

abstract class ClearanceRepository {
  Future<Clearance> getClearance();
}
