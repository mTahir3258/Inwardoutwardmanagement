import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inward_outward_management/providers/company_provider.dart';
import 'package:inward_outward_management/core/models/material_model.dart';
import 'package:inward_outward_management/utils/app_colors.dart';
import 'package:inward_outward_management/utils/responsive.dart';
import 'package:inward_outward_management/widgets/app_scaffold.dart';
import 'package:inward_outward_management/widgets/primary_button.dart';
import 'package:provider/provider.dart';

class SubmitWithoutRequestScreen extends StatefulWidget {
  const SubmitWithoutRequestScreen({super.key});

  @override
  State<SubmitWithoutRequestScreen> createState() =>
      _SubmitWithoutRequestScreenState();
}

class _EntryRowControllers {
  final TextEditingController primaryCtr;
  final TextEditingController secondaryCtr;
  String? materialName;

  _EntryRowControllers({double? primary, double? secondary})
      : primaryCtr = TextEditingController(
          text: primary != null ? primary.toStringAsFixed(1) : '',
        ),
        secondaryCtr = TextEditingController(
          text: secondary != null ? secondary.toStringAsFixed(1) : '',
        );

  void dispose() {
    primaryCtr.dispose();
    secondaryCtr.dispose();
  }

  double get primaryValue => double.tryParse(primaryCtr.text.trim()) ?? 0;
  double get secondaryValue => double.tryParse(secondaryCtr.text.trim()) ?? 0;
  double get resultValue => primaryValue + secondaryValue;
}

class _SubmitWithoutRequestScreenState
    extends State<SubmitWithoutRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_EntryRowControllers> _rows = [];
  final TextEditingController _totalWeightCtr = TextEditingController();
  final TextEditingController _boxCountCtr = TextEditingController();
  final List<Map<String, dynamic>> _recentSubmissions = [];
  String? _selectedMaterialName;
  String? _selectedUnitName;

  double get _entriesTotalWeight => _rows.fold<double>(
        0,
        (sum, r) => sum + r.resultValue,
      );

  @override
  void initState() {
    super.initState();
    // Load material master so dropdowns have data
    Future.microtask(() {
      final prov = Provider.of<CompanyProvider>(context, listen: false);
      prov.loadMaterials();
    });
  }

  @override
  void dispose() {
    _totalWeightCtr.dispose();
    _boxCountCtr.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _rows.add(_EntryRowControllers());
    });
  }

  void _removeRow(int index) {
    if (index < 0 || index >= _rows.length) return;
    setState(() {
      final row = _rows.removeAt(index);
      row.dispose();
    });
  }

  void _syncRowsWithBoxCount(int boxCount) {
    setState(() {
      final target = boxCount > 0 ? boxCount : 0;

      // Grow list
      while (_rows.length < target) {
        _rows.add(_EntryRowControllers());
      }

      // Shrink list and dispose removed controllers
      while (_rows.length > target) {
        final removed = _rows.removeLast();
        removed.dispose();
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final supplier = FirebaseAuth.instance.currentUser;
    if (supplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated as supplier')),
      );
      return;
    }

    final companyProv = Provider.of<CompanyProvider>(context, listen: false);
    if (companyProv.companyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company not configured')),
      );
      return;
    }

    // Capture current values
    final totalWeightField = double.tryParse(_totalWeightCtr.text.trim()) ?? 0;
    final boxCount = int.tryParse(_boxCountCtr.text.trim()) ?? _rows.length;
    final entriesTotal = _entriesTotalWeight;
    // Per-box values (each row's result)
    final boxValues = _rows.map((r) => r.resultValue).toList();

    // Ensure manual total weight matches entries total
    if (totalWeightField > 0 && entriesTotal > 0 &&
        (totalWeightField - entriesTotal).abs() > 0.1) {
      ScaffoldMessenger.of(context).showSnackBar(
        
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Wrong weights calculation: total weight and entries weight do not match'),
        ),
      );
      return;
    }

    // Build a simple aggregated items map for challan creation: one line item
    final items = <String, dynamic>{
      'weightEntry': {
        'qty': 1.0,
        'rate': 0.0,
        'materialKg': entriesTotal,
        'plasticKg': 0.0,
      },
    };

    final intimation = <String, dynamic>{
      'supplierId': supplier.uid,
      'companyId': companyProv.companyId,
      'totalWeightField': totalWeightField,
      'boxes': boxCount,
      'entriesTotalWeight': entriesTotal,
      'boxValues': boxValues,
      'items': items,
      if (_selectedMaterialName != null)
        'materialName': _selectedMaterialName!.trim(),
      if (_selectedUnitName != null)
        'unitName': _selectedUnitName!.trim(),
    };

    try {
      await companyProv.addStandaloneIntimation(intimation);

      setState(() {
        // Store recent submission (keep only a few latest)
        _recentSubmissions.insert(0, {
          'totalWeight': totalWeightField,
          'boxes': boxCount,
          'entriesTotal': entriesTotal,
        });
        if (_recentSubmissions.length > 5) {
          _recentSubmissions.removeLast();
        }

        // Reset inputs
        _totalWeightCtr.clear();
        _boxCountCtr.clear();

        for (final r in _rows) {
          r.dispose();
        }
        _rows.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Submitted entries as intimation'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final companyProv = Provider.of<CompanyProvider>(context);
    final materials = companyProv.materials;

    return AppScaffold(
      title: 'Send Material',
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(r.wp(4)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Single material dropdown (select once for all rows)
                      if (materials.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedMaterialName,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: r.hp(0.8),
                              horizontal: r.wp(2),
                            ),
                            filled: true,
                            fillColor: AppColors.greyBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          dropdownColor: AppColors.greyBackground,
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: r.sp(11),
                          ),
                          hint: Text(
                            'Select material',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: r.sp(11),
                            ),
                          ),
                          items: materials
                              .map<DropdownMenuItem<String>>((m) {
                            final material = m as MaterialModel;
                            return DropdownMenuItem<String>(
                              value: material.name,
                              child: Text(material.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedMaterialName = val;

                              // Also derive unit from selected material
                              final mat = materials.firstWhere(
                                (m) => m.name == val,
                                orElse: () => MaterialModel(
                                  name: '',
                                  unit: '',
                                  rate: 0,
                                ),
                              );
                              _selectedUnitName = mat.unit.trim().isNotEmpty
                                  ? mat.unit.trim()
                                  : null;
                            });
                          },
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please select a material';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: r.hp(0.8)),
                      ],

                      SizedBox(height: r.hp(0.8)),

                      Text(
                        'Enter total Unit',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: r.sp(11),
                        ),
                      ),
                      SizedBox(height: r.hp(0.5)),

                      TextFormField(
                        controller: _totalWeightCtr,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: r.sp(11),
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: r.hp(0.8),
                            horizontal: r.wp(2),
                          ),
                          filled: true,
                          fillColor: AppColors.greyBackground,
                          hintText: 'Total ',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: r.sp(11),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Required';
                          }
                          return double.tryParse(v.trim()) == null
                              ? 'Invalid'
                              : null;
                        },
                      ),
                      SizedBox(height: r.hp(0.8)),

                      Text(
                        'Enter total Box',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: r.sp(11),
                        ),
                      ),
                      SizedBox(height: r.hp(0.5)),

                      TextFormField(
                        controller: _boxCountCtr,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: false),
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: r.sp(11),
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: r.hp(0.8),
                            horizontal: r.wp(2),
                          ),
                          filled: true,
                          fillColor: AppColors.greyBackground,
                          hintText: 'Boxes',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: r.sp(11),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          final boxes = int.tryParse(value.trim()) ?? 0;
                          _syncRowsWithBoxCount(boxes);
                        },
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Required';
                          }
                          return int.tryParse(v.trim()) == null
                              ? 'Invalid'
                              : null;
                        },
                      ),
                      SizedBox(height: r.hp(1.2)),

                      Text(
                        'Enter the Count',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: r.sp(11),
                        ),
                      ),

                      _buildHeaderRow(r),
                      // SizedBox(height: r.hp(1)),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.greyBackground,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(
                              vertical: r.hp(1),
                              horizontal: r.wp(2),
                            ),
                            itemCount: _rows.length,
                            itemBuilder: (context, index) {
                              final rowWidget = _buildEntryRow(
                                r,
                                _rows[index],
                                index,
                              );

                              if (index == _rows.length - 1 &&
                                  _entriesTotalWeight > 0) {
                                final unitLabel =
                                    _selectedUnitName?.trim().isNotEmpty == true
                                        ? _selectedUnitName!.trim()
                                        : '';
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    rowWidget,
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: r.hp(0.6),
                                      ),
                                      child: Text(
                                        'Entries total :- ${_entriesTotalWeight.toStringAsFixed(1)} $unitLabel',
                                        style: TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: r.sp(11),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return rowWidget;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                r.wp(4),
                0,
                r.wp(4),
                r.hp(2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(
                    label: 'Submit',
                    onTap: _submit,
                  ),
                  if (_recentSubmissions.isNotEmpty) ...[
                    SizedBox(height: r.hp(1)),
                    Text(
                      'Recent requests',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600,
                        fontSize: r.sp(12),
                      ),
                    ),
                    SizedBox(height: r.hp(0.4)),
                    ..._recentSubmissions.map((s) {
                      final total = (s['totalWeight'] as double?) ?? 0;
                      final boxes = (s['boxes'] as int?) ?? 0;
                      final entries = (s['entriesTotal'] as double?) ?? 0;
                      return Padding(
                        padding: EdgeInsets.only(top: r.hp(0.2)),
                        child: Text(
                          'Weight: ${total.toStringAsFixed(1)} kg, Boxes: $boxes, Entries total: ${entries.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: r.sp(10),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(Responsive r) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            '',
            style: TextStyle(
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
              fontSize: r.sp(11),
            ),
          ),
        ),
        Expanded(
          child: Text(
            '',
            style: TextStyle(
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
              fontSize: r.sp(11),
            ),
          ),
        ),
        Expanded(
          child: Text(
            '',
            style: TextStyle(
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
              fontSize: r.sp(11),
            ),
          ),
        ),
        Expanded(
          child: Text(
            '',
            style: TextStyle(
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
              fontSize: r.sp(11),
            ),
          ),
        ),
        SizedBox(width: r.wp(8)),
      ],
    );
  }

  Widget _buildEntryRow(
    Responsive r,
    _EntryRowControllers controllers,
    int index,
  ) {
    final result = controllers.resultValue;

    return Container(
      margin: EdgeInsets.only(bottom: r.hp(0.8)),
      padding: EdgeInsets.symmetric(
        vertical: r.hp(0.8),
        horizontal: r.wp(2),
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _buildNumberField(
              r: r,
              controller: controllers.primaryCtr,
              hint: '0.0',
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(width: r.wp(2)),
          Expanded(
            child: _buildNumberField(
              r: r,
              controller: controllers.secondaryCtr,
              hint: '0.0',
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(width: r.wp(2)),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                result.toStringAsFixed(1),
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: r.sp(11),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _removeRow(index),
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required Responsive r,
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        color: AppColors.textLight,
        fontSize: r.sp(11),
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          vertical: r.hp(0.8),
          horizontal: r.wp(2),
        ),
        filled: true,
        fillColor: AppColors.greyBackground,
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontSize: r.sp(11),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: onChanged,
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Required';
        }
        return double.tryParse(v.trim()) == null ? 'Invalid' : null;
      },
    );
  }

  Widget _buildActionsRow(Responsive r) {
    return Row(
      children: [
        const Spacer(),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: _addRow,
            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
