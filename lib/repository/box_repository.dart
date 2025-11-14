import 'package:cloud_firestore/cloud_firestore.dart';

class BoxRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addOrUpdateBox({
    required String companyId,
    required String boxId,
    required Map<String, dynamic> data,
  }) async {
    await _db
        .collection('companies')
        .doc(companyId)
        .collection('boxes')
        .doc(boxId)
        .set(data, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> getBoxes(String companyId) async {
    final res = await _db
        .collection('companies')
        .doc(companyId)
        .collection('boxes')
        .orderBy('createdAt', descending: true)
        .get();

    return res.docs.map((e) => e.data()).toList();
  }

  Future<void> deleteBox({
    required String companyId,
    required String boxId,
  }) async {
    await _db
        .collection('companies')
        .doc(companyId)
        .collection('boxes')
        .doc(boxId)
        .delete();
  }
}
