import 'package:cloud_firestore/cloud_firestore.dart';

class LotRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -------------------------------
  // CREATE OR UPDATE LOT
  // -------------------------------
  Future<void> addOrUpdateLot({
    required String companyId,
    required String lotId,
    required Map<String, dynamic> data,
  }) async {
    await _db
        .collection('companies')
        .doc(companyId)
        .collection('lots')
        .doc(lotId)
        .set(data, SetOptions(merge: true));
  }

  // -------------------------------
  // GET ALL LOTS
  // -------------------------------
  Future<List<Map<String, dynamic>>> getLots(String companyId) async {
    final res = await _db
        .collection('companies')
        .doc(companyId)
        .collection('lots')
        .orderBy('createdAt', descending: true)
        .get();

    return res.docs.map((e) => e.data()).toList();
  }

  // -------------------------------
  // DELETE LOT
  // -------------------------------
  Future<void> deleteLot({
    required String companyId,
    required String lotId,
  }) async {
    await _db
        .collection('companies')
        .doc(companyId)
        .collection('lots')
        .doc(lotId)
        .delete();
  }
}
