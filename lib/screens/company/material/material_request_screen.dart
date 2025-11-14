// lib/screens/company/material_request_screen.dart
import 'package:flutter/material.dart';
import 'package:inward_outward_management/core/models/material_request.dart';
import 'package:inward_outward_management/providers/material_request_provider.dart';
import 'package:inward_outward_management/utils/responsive.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class MaterialRequestScreen extends StatefulWidget {
  const MaterialRequestScreen({super.key});

  @override
  State<MaterialRequestScreen> createState() => _MaterialRequestScreenState();
}

class _MaterialRequestScreenState extends State<MaterialRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController materialController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController boxController = TextEditingController();
  final TextEditingController supplierController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final provider = Provider.of<MaterialRequestProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Material Request'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(r.wp(4)),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: materialController,
                  decoration: const InputDecoration(labelText: 'Material Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: r.hp(1)),
                TextFormField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: r.hp(1)),
                TextFormField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Weight (kg)'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: r.hp(1)),
                TextFormField(
                  controller: boxController,
                  decoration: const InputDecoration(labelText: 'Box Type'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: r.hp(1)),
                TextFormField(
                  controller: supplierController,
                  decoration: const InputDecoration(labelText: 'Supplier ID'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: r.hp(2)),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final request = MaterialRequest(
                        id: const Uuid().v4(),
                        materialName: materialController.text,
                        quantity: int.parse(quantityController.text),
                        weight: double.parse(weightController.text),
                        boxType: boxController.text,
                        supplierId: supplierController.text,
                        createdAt: DateTime.now(),
                      );
                      await provider.addRequest(request);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Request Created')),
                      );
                      _formKey.currentState!.reset();
                    }
                  },
                  child: const Text('Submit Request'),
                ),
                const SizedBox(height: 20),
                provider.loading
                    ? const CircularProgressIndicator()
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.requests.length,
                        itemBuilder: (context, index) {
                          final r = provider.requests[index];
                          return ListTile(
                            title: Text(r.materialName),
                            subtitle: Text(
                              'Qty: ${r.quantity}, Weight: ${r.weight}kg, Status: ${r.status}',
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
