// lib/providers/material_request_provider.dart
import 'package:flutter/material.dart';
import 'package:inward_outward_management/core/models/material_request.dart';
import 'package:inward_outward_management/repository/material_request_repository.dart';

class MaterialRequestProvider extends ChangeNotifier {
  final MaterialRequestRepository _repository = MaterialRequestRepository();
  List<MaterialRequest> _requests = [];
  bool loading = false;

  List<MaterialRequest> get requests => _requests;

  Future<void> fetchRequests() async {
    loading = true;
    notifyListeners();
    _requests = await _repository.fetchRequests();
    loading = false;
    notifyListeners();
  }

  Future<void> addRequest(MaterialRequest request) async {
    loading = true;
    notifyListeners();
    await _repository.addRequest(request);
    _requests.add(request);
    loading = false;
    notifyListeners();
  }

  Future<void> updateStatus(String requestId, String status) async {
    await _repository.updateStatus(requestId, status);
    int index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index].status = status;
      notifyListeners();
    }
  }
}
