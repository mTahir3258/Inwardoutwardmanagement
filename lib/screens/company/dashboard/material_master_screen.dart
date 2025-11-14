import 'package:flutter/material.dart';
import 'package:inward_outward_management/core/models/material_model.dart';
import 'package:inward_outward_management/providers/company_provider.dart';
import 'package:provider/provider.dart';

class MaterialMasterScreen extends StatefulWidget {
  const MaterialMasterScreen({super.key});

  @override
  State<MaterialMasterScreen> createState() => _MaterialMasterScreenState();
}

class _MaterialMasterScreenState extends State<MaterialMasterScreen> {
  @override
  void initState() {
    super.initState();

    /// Load materials when screen opens
    Future.microtask(
      () =>
          Provider.of<CompanyProvider>(context, listen: false).loadMaterials(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CompanyProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Material Master")),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMaterialDialog(context),
        child: const Icon(Icons.add),
      ),

      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.materials.isEmpty
          ? const Center(child: Text("No Materials Added Yet"))
          : ListView.builder(
              itemCount: provider.materials.length,
              itemBuilder: (context, index) {
                final material = provider.materials[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(material.name),
                    subtitle: Text(
                      "Unit: ${material.unit}    Rate: ₹${material.rate}",
                    ),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// EDIT BUTTON
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _showEditMaterialDialog(context, material),
                        ),

                        /// DELETE BUTTON
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _showDeleteConfirmation(context, material),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // -----------------------------------------------------------------------------
  // ADD MATERIAL DIALOG
  // -----------------------------------------------------------------------------

  void _showAddMaterialDialog(BuildContext context) {
    final nameController = TextEditingController();
    final unitController = TextEditingController();
    final rateController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Add Material"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _customTextField(nameController, "Material Name"),
              const SizedBox(height: 10),
              _customTextField(unitController, "Unit (kg / pcs / box)"),
              const SizedBox(height: 10),
              _customTextField(rateController, "Rate", isNumber: true),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Save"),
              onPressed: () {
                final material = MaterialModel(
                  name: nameController.text.trim(),
                  unit: unitController.text.trim(),
                  rate: double.tryParse(rateController.text) ?? 0,
                );

                Provider.of<CompanyProvider>(
                  context,
                  listen: false,
                ).addMaterial(material);

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // -----------------------------------------------------------------------------
  // EDIT MATERIAL DIALOG
  // -----------------------------------------------------------------------------

  void _showEditMaterialDialog(BuildContext context, MaterialModel material) {
    final nameController = TextEditingController(text: material.name);
    final unitController = TextEditingController(text: material.unit);
    final rateController = TextEditingController(
      text: material.rate.toString(),
    );

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Edit Material"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _customTextField(nameController, "Material Name"),
              const SizedBox(height: 10),
              _customTextField(unitController, "Unit"),
              const SizedBox(height: 10),
              _customTextField(rateController, "Rate", isNumber: true),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Update"),
              onPressed: () {
                final updatedMaterial = MaterialModel(
                  id: material.id,
                  name: nameController.text.trim(),
                  unit: unitController.text.trim(),
                  rate: double.tryParse(rateController.text) ?? 0,
                );

                Provider.of<CompanyProvider>(
                  context,
                  listen: false,
                ).updateMaterial(material.id!, updatedMaterial);

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // -----------------------------------------------------------------------------
  // DELETE CONFIRMATION DIALOG
  // -----------------------------------------------------------------------------

  void _showDeleteConfirmation(BuildContext context, MaterialModel material) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Delete Material"),
          content: Text("Are you sure you want to delete '${material.name}'?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Delete"),
              onPressed: () {
                Provider.of<CompanyProvider>(
                  context,
                  listen: false,
                ).deleteMaterial(material.id!);

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // -----------------------------------------------------------------------------
  // REUSABLE CUSTOM TEXTFIELD (So UI does not break)
  // -----------------------------------------------------------------------------

  Widget _customTextField(
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
