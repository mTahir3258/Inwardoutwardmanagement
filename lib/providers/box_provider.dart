import 'package:flutter/material.dart';
import '../repository/box_repository.dart';

class BoxProvider extends ChangeNotifier {
  final BoxRepository repo;

  BoxProvider(this.repo);

  bool loading = false;
  List<Map<String, dynamic>> boxes = [];

  String companyId = ""; // Assigned from Login or CompanyProvider.

  Future<void> loadBoxes() async {
    loading = true;
    notifyListeners();

    boxes = await repo.getBoxes(companyId);

    loading = false;
    notifyListeners();
  }

  Future<void> saveBox(Map<String, dynamic> box) async {
    await repo.addOrUpdateBox(
      companyId: companyId,
      boxId: box["boxId"],
      data: box,
    );
    await loadBoxes();
  }

  Future<void> deleteBox(String boxId) async {
    await repo.deleteBox(companyId: companyId, boxId: boxId);
    await loadBoxes();
  }
}
