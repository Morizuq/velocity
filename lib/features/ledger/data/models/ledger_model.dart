import '../../domain/entities/ledger.dart';

class LedgerModel extends Ledger {
  const LedgerModel();

  factory LedgerModel.fromJson(Map<String, dynamic> json) {
    return const LedgerModel();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{};
  }
}
