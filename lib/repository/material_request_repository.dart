// lib/repositories/material_request_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inward_outward_management/core/models/material_request.dart';

class MaterialRequestRepository {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'material_requests',
  );

  Future<void> addRequest(MaterialRequest request) async {
    await _collection.doc(request.id).set(request.toMap());
  }

  Future<List<MaterialRequest>> fetchRequests() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map(
          (doc) => MaterialRequest.fromMap(doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> updateStatus(String requestId, String status) async {
    await _collection.doc(requestId).update({'status': status});
  }
}
