// lib/models/material_request.dart
class MaterialRequest {
  final String id;
  final String materialName;
  final int quantity;
  final double weight; // in kg
  final String boxType;
  final String supplierId;
  final DateTime createdAt;
  String status; // pending, confirmed, dispatched

  MaterialRequest({
    required this.id,
    required this.materialName,
    required this.quantity,
    required this.weight,
    required this.boxType,
    required this.supplierId,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'materialName': materialName,
    'quantity': quantity,
    'weight': weight,
    'boxType': boxType,
    'supplierId': supplierId,
    'createdAt': createdAt.toIso8601String(),
    'status': status,
  };

  factory MaterialRequest.fromMap(Map<String, dynamic> map) {
    return MaterialRequest(
      id: map['id'],
      materialName: map['materialName'],
      quantity: map['quantity'],
      weight: map['weight'],
      boxType: map['boxType'],
      supplierId: map['supplierId'],
      createdAt: DateTime.parse(map['createdAt']),
      status: map['status'] ?? 'pending',
    );
  }
}
