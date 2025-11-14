import 'package:flutter/material.dart';
import '../repository/lot_repository.dart';

class LotProvider extends ChangeNotifier {
  final LotRepository repo;

  LotProvider(this.repo);

  bool loading = false;
  List<Map<String, dynamic>> lots = [];

  String companyId = ""; // Set from login or companyProvider

  // Load all lots
  Future<void> loadLots() async {
    loading = true;
    notifyListeners();

    lots = await repo.getLots(companyId);

    loading = false;
    notifyListeners();
  }

  // Add / Update
  Future<void> saveLot(Map<String, dynamic> lot) async {
    await repo.addOrUpdateLot(
      companyId: companyId,
      lotId: lot['lotId'],
      data: lot,
    );
    await loadLots();
  }

  // Delete
  Future<void> deleteLot(String lotId) async {
    await repo.deleteLot(companyId: companyId, lotId: lotId);
    await loadLots();
  }
}
