// lib/screens/company/material_request_screen.dart
import 'package:flutter/material.dart';
import 'package:inward_outward_management/providers/company_provider.dart';
import 'package:inward_outward_management/utils/app_colors.dart';
import 'package:inward_outward_management/utils/responsive.dart';
import 'package:inward_outward_management/widgets/app_scaffold.dart';
import 'package:inward_outward_management/widgets/app_form_field.dart';
import 'package:inward_outward_management/widgets/primary_button.dart';
import 'package:provider/provider.dart';

class MaterialRequestScreen extends StatefulWidget {
  const MaterialRequestScreen({super.key});

  @override
  State<MaterialRequestScreen> createState() => _MaterialRequestScreenState();
}

class _MaterialRequestScreenState extends State<MaterialRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  bool _submitting = false;

  String? _selectedMaterialName;
  String? _selectedSupplierId;
  String? _selectedMaterialUnit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CompanyProvider>(context, listen: false);
      if (!provider.loadingRequests && provider.requests.isEmpty) {
        provider.loadMaterialRequests();
      }
    });
  }

  @override
  void dispose() {
    quantityController.dispose();
    weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final provider = Provider.of<CompanyProvider>(context);

    return AppScaffold(
      title: 'Create Material Request',
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(r.wp(4)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: r.wp(4),
                      vertical: r.hp(3),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Material',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: r.sp(12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: r.hp(0.6)),
                          DropdownButtonFormField<String>(
                            value: _selectedMaterialName,
                            isExpanded: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.greyBackground,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: Colors.transparent),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryGreen,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            style:
                                const TextStyle(color: AppColors.textLight),
                            dropdownColor: AppColors.greyBackground,
                            items: provider.materials
                                .map(
                                  (m) => DropdownMenuItem<String>(
                                    value: m.name,
                                    child: Text(m.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val == null) {
                                setState(() {
                                  _selectedMaterialName = null;
                                  _selectedMaterialUnit = null;
                                });
                                return;
                              }

                              String? unit;
                              for (final m in provider.materials) {
                                if (m.name == val) {
                                  unit = m.unit;
                                  break;
                                }
                              }

                              setState(() {
                                _selectedMaterialName = val;
                                _selectedMaterialUnit = unit;
                              });
                            },
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Select material'
                                : null,
                          ),
                          SizedBox(height: r.hp(1.8)),
                          Text(
                            'Enter total Unit',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: r.sp(12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: r.hp(0.6)),
                          AppFormField(
                            controller: quantityController,
                            label: 'Enter total Unit',
                            isNumber: true,
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          SizedBox(height: r.hp(1.8)),
                          Text(
                            'Enter total Box',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: r.sp(12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: r.hp(0.6)),
                          AppFormField(
                            controller: weightController,
                            label: 'Enter total Box',
                            isNumber: true,
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                          SizedBox(height: r.hp(1.8)),
                          Text(
                            'Select Supplier',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: r.sp(12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: r.hp(0.6)),
                          DropdownButtonFormField<String>(
                            value: _selectedSupplierId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.greyBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.transparent,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryGreen,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            items: provider.suppliers
                                .map(
                                  (s) => DropdownMenuItem<String>(
                                    value: s.id,
                                    child: Text(
                                      s.name,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedSupplierId = val;
                              });
                            },
                            validator: (_) => _selectedSupplierId == null
                                ? 'Select supplier'
                                : null,
                          ),
                          SizedBox(height: r.hp(3)),
                          SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(
                              label: 'Submit Request',
                              loading: _submitting,
                              onTap: () async {
                                if (!_formKey.currentState!.validate()) return;
                                setState(() => _submitting = true);
                                try {
                                  // Derive supplier login email (mobile@supplier.local) from master data
                                  String? supplierEmail;
                                  for (final s in provider.suppliers) {
                                    if (s.id == _selectedSupplierId &&
                                        s.mobile.isNotEmpty) {
                                      supplierEmail =
                                          '${s.mobile}@supplier.local';
                                      break;
                                    }
                                  }

                                  final reqMap = {
                                    'materialName': _selectedMaterialName,
                                    'unit': _selectedMaterialUnit ?? '',
                                    'quantity': int.tryParse(
                                            quantityController.text.trim()) ??
                                        0,
                                    // Store total boxes separately; also
                                    // keep weight for backward compatibility
                                    'boxes': int.tryParse(
                                            weightController.text.trim()) ??
                                        0,
                                    'weight': double.tryParse(
                                            weightController.text.trim()) ??
                                        0.0,
                                    // For supplier side we link by login email
                                    'supplierId':
                                        supplierEmail ?? _selectedSupplierId,
                                    'supplierEmail': supplierEmail ?? '',
                                  };
                                  await provider.createMaterialRequest(reqMap);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Request Created')),
                                  );
                                  _formKey.currentState!.reset();
                                  quantityController.clear();
                                  weightController.clear();
                                  setState(() {
                                    _selectedMaterialName = null;
                                    _selectedMaterialUnit = null;
                                    _selectedSupplierId = null;
                                  });
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Failed to create request: $e'),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _submitting = false);
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Existing Requests',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: r.sp(14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: r.hp(1)),
              provider.loadingRequests
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.requests.length,
                      itemBuilder: (context, index) {
                        final req = provider.requests[index];
                        final materialName =
                            req['materialName']?.toString() ?? '-';
                        final qty = req['quantity']?.toString() ?? '0';
                        final boxes =
                            (req['boxes'] ?? req['weight'])?.toString() ?? '0';
                        final unit = req['unit']?.toString() ?? '';
                        final status =
                            req['status']?.toString() ?? 'requested';
                        return Card(
                          color: AppColors.greyBackground,
                          margin: EdgeInsets.only(bottom: r.hp(1.2)),
                          child: ListTile(
                            title: Text(
                              materialName,
                              style: const TextStyle(
                                color: AppColors.textLight,
                              ),
                            ),
                            subtitle: Text(
                              unit.isNotEmpty
                                  ? 'Qty: $qty $unit, Boxes: $boxes, Status: $status'
                                  : 'Qty: $qty, Boxes: $boxes, Status: $status',
                              style: const TextStyle(
                                color: AppColors.textLight,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
            ],
          ),
        ),
      ),
    );
  }
}
