import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inward_outward_management/core/models/material_model.dart';

class CompanyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // MATERIAL CRUD SECTION
  // ---------------------------------------------------------------------------

  /// Add a new Material to Firestore
  Future<void> addMaterial(MaterialModel material) async {
    await _firestore.collection('materials').add(material.toMap());
  }

  /// Fetch all Materials from Firestore
  Future<List<MaterialModel>> fetchMaterials() async {
    final snapshot = await _firestore.collection('materials').get();
    return snapshot.docs
        .map((doc) => MaterialModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Update Material data
  Future<void> updateMaterial(String id, MaterialModel material) async {
    await _firestore.collection('materials').doc(id).update(material.toMap());
  }

  /// Delete Material
  Future<void> deleteMaterial(String id) async {
    await _firestore.collection('materials').doc(id).delete();
  }
}
