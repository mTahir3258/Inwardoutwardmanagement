class MaterialModel {
  final String? id;
  final String name;
  final String unit; // kg, pcs, box etc
  final double rate;

  MaterialModel({
    this.id,
    required this.name,
    required this.unit,
    required this.rate,
  });

  // Convert to Map (for Firebase)
  Map<String, dynamic> toMap() {
    return {'name': name, 'unit': unit, 'rate': rate};
  }

  // Convert From Firebase
  factory MaterialModel.fromMap(Map<String, dynamic> data, String id) {
    return MaterialModel(
      id: id,
      name: data['name'] ?? '',
      unit: data['unit'] ?? '',
      rate: (data['rate'] ?? 0).toDouble(),
    );
  }
}
