// CompanyService: handles all Firestore reads/writes and pure calculations
// Keep this file focused on data operations only.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inward_outward_management/core/models/material_model.dart';

class CompanyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Root paths
  CollectionReference<Map<String, dynamic>> companies() =>
      _firestore.collection('companies');

  CollectionReference<Map<String, dynamic>> materials(String companyId) =>
      companies().doc(companyId).collection('materials');

  CollectionReference<Map<String, dynamic>> challans(String companyId) =>
      companies().doc(companyId).collection('challans');

  CollectionReference<Map<String, dynamic>> bills(String companyId) =>
      companies().doc(companyId).collection('bills');

  CollectionReference<Map<String, dynamic>> receipts(String companyId) =>
      companies().doc(companyId).collection('advance_receipts');

  // Global collections for workflow
  CollectionReference<Map<String, dynamic>> supplierRequests() =>
      _firestore.collection('supplier_requests');

  CollectionReference<Map<String, dynamic>> inwardRequests() =>
      _firestore.collection('inward_requests');

  CollectionReference<Map<String, dynamic>> outwardRequests() =>
      _firestore.collection('outward_requests');

  // ---------------- Material CRUD ----------------
  Future<String> createMaterial(String companyId, MaterialModel m) async {
    final ref = await materials(companyId).add(m.toMap());
    return ref.id;
  }

  Future<void> updateMaterial(String companyId, MaterialModel m) async {
    await materials(companyId).doc(m.id).update(m.toMap());
  }

  Future<void> deleteMaterial(String companyId, String materialId) async {
    await materials(companyId).doc(materialId).delete();
  }

  // Future<List<MaterialModel>> getMaterials(String companyId) async {
  //   final snap = await materials(companyId).get();
  //   return snap.docs.map((d) => MaterialModel.fromMap(d.id, d.data())).toList();
  // }

  // ---------------- Material Requests ----------------
  /// Company raises a new material request (stored under global `supplier_requests`)
  Future<String> createMaterialRequest(
    String companyId,
    Map<String, dynamic> requestMap,
  ) async {
    final doc = {
      ...requestMap,
      'companyId': companyId,
      'status': 'requested',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
    final ref = await supplierRequests().add(doc);
    return ref.id;
  }

  Future<List<Map<String, dynamic>>> getMaterialRequests(
    String companyId,
  ) async {
    final q = await supplierRequests()
        .where('companyId', isEqualTo: companyId)
        .orderBy('createdAt', descending: true)
        .get();
    return q.docs.map((d) {
      final map = Map<String, dynamic>.from(d.data());
      map['id'] = d.id;
      return map;
    }).toList();
  }

  Future<void> addSupplierIntimation(
    String requestId,
    Map<String, dynamic> intimation,
  ) async {
    final sub = supplierRequests()
        .doc(requestId)
        .collection('supplier_intimations');
    await sub.add({
      ...intimation,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'status': 'intimated',
    });
  }

  Future<List<Map<String, dynamic>>> getSupplierIntimations(
    String requestId,
  ) async {
    final snap = await supplierRequests()
        .doc(requestId)
        .collection('supplier_intimations')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) {
      final m = Map<String, dynamic>.from(d.data());
      m['id'] = d.id;
      return m;
    }).toList();
  }

  // ---------------- Challan creation (company confirms intimation) ----------------
  /// Accepts an intimation map that contains items: materialId -> { qty, rate, materialKg, plasticKg }
  /// Computes totals and creates a challan under companies/{companyId}/challans
  Future<String> createChallanFromIntimation(
    String companyId,
    String supplierId,
    Map<String, dynamic> intimation,
  ) async {
    final items = Map<String, dynamic>.from(intimation['items'] ?? {});
    double totalAmount = 0.0;
    double totalMaterialKg = 0.0;
    double totalPlasticKg = 0.0;

    items.forEach((materialId, entryRaw) {
      final entry = Map<String, dynamic>.from(entryRaw ?? {});
      final qty = (entry['qty'] is num)
          ? (entry['qty'] as num).toDouble()
          : double.tryParse('${entry['qty']}') ?? 0.0;
      final rate = (entry['rate'] is num)
          ? (entry['rate'] as num).toDouble()
          : double.tryParse('${entry['rate']}') ?? 0.0;
      final materialKg = (entry['materialKg'] is num)
          ? (entry['materialKg'] as num).toDouble()
          : double.tryParse('${entry['materialKg']}') ?? 0.0;
      final plasticKg = (entry['plasticKg'] is num)
          ? (entry['plasticKg'] as num).toDouble()
          : double.tryParse('${entry['plasticKg']}') ?? 0.0;

      final totalCost = qty * rate;
      entry['qty'] = qty;
      entry['rate'] = rate;
      entry['materialKg'] = materialKg;
      entry['plasticKg'] = plasticKg;
      entry['totalCost'] = totalCost;

      items[materialId] = entry;

      totalAmount += totalCost;
      totalMaterialKg += materialKg * qty;
      totalPlasticKg += plasticKg * qty;
    });

    final challanNo = _generateUniqueNumber(prefix: 'CH');

    final doc = {
      'supplierId': supplierId,
      'companyId': companyId,
      'items': items,
      'totalAmount': totalAmount,
      'totalMaterialKg': totalMaterialKg,
      'totalPlasticKg': totalPlasticKg,
      'status': 'open',
      'challanNo': challanNo,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };

    final ref = await challans(companyId).add(doc);
    return ref.id;
  }

  Future<void> updateChallanStatus(
    String companyId,
    String challanId,
    String status,
  ) async {
    await challans(companyId).doc(challanId).update({
      'status': status,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getChallans(String companyId) async {
    final snap = await challans(
      companyId,
    ).orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) {
      final m = Map<String, dynamic>.from(d.data());
      m['id'] = d.id;
      return m;
    }).toList();
  }

  // ---------------- Supplier bills ----------------
  Future<String> createSupplierBillFromChallan(
    String companyId,
    String challanId,
  ) async {
    final chDoc = await challans(companyId).doc(challanId).get();
    if (!chDoc.exists) throw Exception('Challan not found');
    final data = chDoc.data()!;
    final amountRaw = data['totalAmount'] ?? 0;
    final amount = (amountRaw is num)
        ? (amountRaw as num).toDouble()
        : double.tryParse('$amountRaw') ?? 0.0;
    final billNo = _generateUniqueNumber(prefix: 'B');

    final billDoc = {
      'challanId': challanId,
      'supplierId': data['supplierId'] ?? '',
      'companyId': companyId,
      'amount': amount,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'status': 'unpaid',
      'billNo': billNo,
    };

    final ref = await bills(companyId).add(billDoc);
    return ref.id;
  }

  Future<List<Map<String, dynamic>>> getSupplierBills(String companyId) async {
    final snap = await bills(
      companyId,
    ).orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) {
      final m = Map<String, dynamic>.from(d.data());
      m['id'] = d.id;
      return m;
    }).toList();
  }

  // ---------------- Dashboard summary ----------------
  Future<Map<String, dynamic>> getDashboardSummary(String companyId) async {
    // run queries in parallel
    final futures = await Future.wait([
      inwardRequests()
          .where('companyId', isEqualTo: companyId)
          .where('status', isEqualTo: 'pending')
          .get(),
      outwardRequests()
          .where('companyId', isEqualTo: companyId)
          .where('status', isEqualTo: 'pending')
          .get(),
      supplierRequests().where('companyId', isEqualTo: companyId).get(),
      challans(companyId).where('status', isEqualTo: 'open').get(),
      bills(companyId).where('status', isEqualTo: 'unpaid').get(),
      receipts(companyId).get(),
    ]);

    final pendingInward = futures[0] as QuerySnapshot<Map<String, dynamic>>;
    final pendingOutward = futures[1] as QuerySnapshot<Map<String, dynamic>>;
    final supplierReq = futures[2] as QuerySnapshot<Map<String, dynamic>>;
    final openChallans = futures[3] as QuerySnapshot<Map<String, dynamic>>;
    final pendingBills = futures[4] as QuerySnapshot<Map<String, dynamic>>;
    final receiptsSnap = futures[5] as QuerySnapshot<Map<String, dynamic>>;

    double totalAdvance = 0.0;
    for (var doc in receiptsSnap.docs) {
      final data = doc.data();
      final amtRaw = data['amount'] ?? 0;
      final amt = (amtRaw is num)
          ? (amtRaw as num).toDouble()
          : double.tryParse('$amtRaw') ?? 0.0;
      totalAdvance += amt;
    }

    return {
      'pendingInward': pendingInward.docs.length,
      'pendingOutward': pendingOutward.docs.length,
      'supplierRequests': supplierReq.docs.length,
      'openChallans': openChallans.docs.length,
      'pendingBills': pendingBills.docs.length,
      'advanceReceipts': totalAdvance,
    };
  }

  // ---------------- Helpers ----------------
  String _generateUniqueNumber({required String prefix}) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '$prefix$ts';
  }
}
