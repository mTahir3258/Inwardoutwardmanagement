// CompanyProvider: exposes state for company screens and calls CompanyService.
// Use this provider in screens to load lists and trigger actions.

import 'package:flutter/material.dart';
import 'package:inward_outward_management/core/models/material_model.dart';
import 'package:inward_outward_management/repository/company_repository.dart';
import 'package:inward_outward_management/services/company_services.dart';

class CompanyProvider with ChangeNotifier {
  final CompanyService _service = CompanyService();

  final CompanyRepository _repository = CompanyRepository();

  List<MaterialModel> materials = [];
  bool isLoading = false;

  String companyId;
  CompanyProvider({required this.companyId}) {
    if (companyId.isNotEmpty) _initLoad();
  }

  void _initLoad() {
    loadMaterials();
    loadDashboardSummary();
    loadMaterialRequests();
    loadChallans();
    loadSupplierBills();
  }

  // -------------- Materials --------------
  List<MaterialModel> _materials = [];

  // List<MaterialModel> get materials => _materials;
  // bool loadingMaterials = false;

  // ---------------------------------------------------------------------------
  // LOAD MATERIALS
  // ---------------------------------------------------------------------------
  Future<void> loadMaterials() async {
    isLoading = true;
    notifyListeners();

    materials = await _repository.fetchMaterials();

    isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // ADD MATERIAL
  // ---------------------------------------------------------------------------
  Future<void> addMaterial(MaterialModel material) async {
    await _repository.addMaterial(material);
    await loadMaterials(); // refresh list
  }

  // ---------------------------------------------------------------------------
  // UPDATE MATERIAL
  // ---------------------------------------------------------------------------
  Future<void> updateMaterial(String id, MaterialModel material) async {
    await _repository.updateMaterial(id, material);
    await loadMaterials();
  }

  // ---------------------------------------------------------------------------
  // DELETE MATERIAL
  // ---------------------------------------------------------------------------
  Future<void> deleteMaterial(String id) async {
    await _repository.deleteMaterial(id);
    await loadMaterials();
  }

  // Future<void> loadMaterials() async {
  //   if (companyId.isEmpty) return;
  //   loadingMaterials = true;
  //   notifyListeners();
  //   try {
  //     _materials = await _service.getMaterials(companyId);
  //   } catch (e) {
  //     debugPrint('loadMaterials error: $e');
  //     _materials = [];
  //   } finally {
  //     loadingMaterials = false;
  //     notifyListeners();
  //   }
  // }

  // Future<void> addMaterial(MaterialModel m) async {
  //   if (companyId.isEmpty) throw Exception('Company ID not set');
  //   final id = await _service.createMaterial(companyId, m);
  //   m.id = id;
  //   _materials.add(m);
  //   notifyListeners();
  // }

  // Future<void> updateMaterial(MaterialModel m) async {
  //   if (companyId.isEmpty) throw Exception('Company ID not set');
  //   await _service.updateMaterial(companyId, m);
  //   final idx = _materials.indexWhere((e) => e.id == m.id);
  //   if (idx >= 0) {
  //     _materials[idx] = m;
  //     notifyListeners();
  //   }
  // }

  // Future<void> deleteMaterial(String materialId) async {
  //   if (companyId.isEmpty) throw Exception('Company ID not set');
  //   await _service.deleteMaterial(companyId, materialId);
  //   _materials.removeWhere((m) => m.id == materialId);
  //   notifyListeners();
  // }

  // -------------- Material Requests --------------
  bool loadingRequests = false;
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> get requests => _requests;

  Future<void> loadMaterialRequests() async {
    if (companyId.isEmpty) return;
    loadingRequests = true;
    notifyListeners();
    try {
      _requests = await _service.getMaterialRequests(companyId);
    } catch (e) {
      debugPrint('loadMaterialRequests error: $e');
      _requests = [];
    } finally {
      loadingRequests = false;
      notifyListeners();
    }
  }

  Future<String> createMaterialRequest(Map<String, dynamic> requestMap) async {
    if (companyId.isEmpty) throw Exception('Company ID not set');
    final id = await _service.createMaterialRequest(companyId, requestMap);
    await loadMaterialRequests();
    return id;
  }

  Future<List<Map<String, dynamic>>> loadSupplierIntimations(
    String requestId,
  ) async {
    return await _service.getSupplierIntimations(requestId);
  }

  Future<void> addSupplierIntimation(
    String requestId,
    Map<String, dynamic> intimation,
  ) async {
    await _service.addSupplierIntimation(requestId, intimation);
  }

  Future<String> confirmIntimationAndCreateChallan(
    String requestId,
    Map<String, dynamic> intimation,
  ) async {
    if (companyId.isEmpty) throw Exception('Company ID not set');
    final supplierId = intimation['supplierId']?.toString() ?? '';
    final challanId = await _service.createChallanFromIntimation(
      companyId,
      supplierId,
      intimation,
    );

    // Update request status to confirmed (best-effort)
    try {
      await _service.supplierRequests().doc(requestId).update({
        'status': 'confirmed',
        'confirmedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Could not update request status: $e');
    }

    // reload lists
    await loadChallans();
    await loadMaterialRequests();
    return challanId;
  }

  // -------------- Challans --------------
  bool loadingChallans = false;
  List<Map<String, dynamic>> _challans = [];
  List<Map<String, dynamic>> get challans => _challans;

  Future<void> loadChallans() async {
    if (companyId.isEmpty) return;
    loadingChallans = true;
    notifyListeners();
    try {
      _challans = await _service.getChallans(companyId);
    } catch (e) {
      debugPrint('loadChallans error: $e');
      _challans = [];
    } finally {
      loadingChallans = false;
      notifyListeners();
    }
  }

  Future<void> updateChallanStatus(String challanId, String status) async {
    if (companyId.isEmpty) throw Exception('Company ID not set');
    await _service.updateChallanStatus(companyId, challanId, status);
    await loadChallans();
    notifyListeners();
  }

  // -------------- Supplier bills --------------
  bool loadingBills = false;
  List<Map<String, dynamic>> _bills = [];
  List<Map<String, dynamic>> get bills => _bills;

  Future<void> loadSupplierBills() async {
    if (companyId.isEmpty) return;
    loadingBills = true;
    notifyListeners();
    try {
      _bills = await _service.getSupplierBills(companyId);
    } catch (e) {
      debugPrint('loadSupplierBills error: $e');
      _bills = [];
    } finally {
      loadingBills = false;
      notifyListeners();
    }
  }

  Future<String> generateBillFromChallan(String challanId) async {
    if (companyId.isEmpty) throw Exception('Company ID not set');
    final id = await _service.createSupplierBillFromChallan(
      companyId,
      challanId,
    );
    await loadSupplierBills();
    await loadChallans();
    return id;
  }

  // -------------- Dashboard summary --------------
  bool dashboardLoading = false;
  int pendingInward = 0;
  int pendingOutward = 0;
  int supplierRequests = 0;
  int openChallans = 0;
  int pendingBills = 0;
  double advanceReceiptsTotal = 0.0;

  Future<void> loadDashboardSummary() async {
    if (companyId.isEmpty) return;
    dashboardLoading = true;
    notifyListeners();
    try {
      final summary = await _service.getDashboardSummary(companyId);
      pendingInward = (summary['pendingInward'] ?? 0) is int
          ? summary['pendingInward']
          : (summary['pendingInward'] ?? 0).toInt();
      pendingOutward = (summary['pendingOutward'] ?? 0) is int
          ? summary['pendingOutward']
          : (summary['pendingOutward'] ?? 0).toInt();
      supplierRequests = (summary['supplierRequests'] ?? 0) is int
          ? summary['supplierRequests']
          : (summary['supplierRequests'] ?? 0).toInt();
      openChallans = (summary['openChallans'] ?? 0) is int
          ? summary['openChallans']
          : (summary['openChallans'] ?? 0).toInt();
      pendingBills = (summary['pendingBills'] ?? 0) is int
          ? summary['pendingBills']
          : (summary['pendingBills'] ?? 0).toInt();
      final adv = summary['advanceReceipts'] ?? 0.0;
      advanceReceiptsTotal = (adv is num)
          ? adv.toDouble()
          : double.tryParse('$adv') ?? 0.0;
    } catch (e) {
      debugPrint('loadDashboardSummary error: $e');
    } finally {
      dashboardLoading = false;
      notifyListeners();
    }
  }

  // -------------- Utilities --------------
  void updateCompanyId(String id) {
    final newId = id.trim();
    if (newId.isEmpty) return;
    if (companyId == newId) return;
    companyId = newId;
    _initLoad();
    notifyListeners();
  }
}
