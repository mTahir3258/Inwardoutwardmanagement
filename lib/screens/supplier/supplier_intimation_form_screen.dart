import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inward_outward_management/services/company_services.dart';
import 'package:inward_outward_management/utils/app_colors.dart';
import 'package:inward_outward_management/utils/responsive.dart';
import 'package:inward_outward_management/widgets/app_scaffold.dart';
import 'package:inward_outward_management/widgets/app_form_field.dart';
import 'package:inward_outward_management/widgets/primary_button.dart';

class SupplierIntimationFormScreen extends StatefulWidget {
  final String requestId;
  final String materialName;
  final String companyId;
  final String? baseQuantity; // required total unit from master data
  final String? baseWeight; // required total box count from master data
  final String? unit; // unit string (e.g., kg, liter)

  const SupplierIntimationFormScreen({
    super.key,
    required this.requestId,
    required this.materialName,
    required this.companyId,
    this.baseQuantity,
    this.baseWeight,
    this.unit,
  });

  @override
  State<SupplierIntimationFormScreen> createState() =>
      _SupplierIntimationFormScreenState();
}

class _Entry {
  final TextEditingController val1 = TextEditingController();
  final TextEditingController val2 = TextEditingController();

  double get result {
    final v1 = double.tryParse(val1.text.trim()) ?? 0.0;
    final v2 = double.tryParse(val2.text.trim()) ?? 0.0;
    return v1 + v2;
  }

  void dispose() {
    val1.dispose();
    val2.dispose();
  }
}

class _SupplierIntimationFormScreenState
    extends State<SupplierIntimationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _unitController = TextEditingController();
  final _boxController = TextEditingController();
  final List<_Entry> _entries = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.baseWeight != null) {
      _boxController.text = widget.baseWeight!;
      _syncRowsWithBoxCount(int.tryParse(widget.baseWeight!) ?? 0);
    }
    _boxController.addListener(_onBoxCountChanged);
  }

  @override
  void dispose() {
    _unitController.dispose();
    _boxController.removeListener(_onBoxCountChanged);
    _boxController.dispose();
    for (var e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  void _syncRowsWithBoxCount(int count) {
    while (_entries.length < count) {
      final entry = _Entry();
      _entries.add(entry);
    }
    while (_entries.length > count) {
      _entries.last.dispose();
      _entries.removeLast();
    }
    setState(() {});
  }

  void _onBoxCountChanged() {
    final count = int.tryParse(_boxController.text.trim()) ?? 0;
    if (count < 0) return;
    if (count > _entries.length) {
      final add = count - _entries.length;
      for (int i = 0; i < add; i++) {
        final entry = _Entry();
        _entries.add(entry);
      }
    } else if (count < _entries.length) {
      final remove = _entries.length - count;
      for (int i = 0; i < remove; i++) {
        _entries.last.dispose();
        _entries.removeLast();
      }
    }
    setState(() {});
  }

  void _removeEntry(int index) {
    setState(() {
      _entries[index].dispose();
      _entries.removeAt(index);
      _boxController.removeListener(_onBoxCountChanged);
      _boxController.text = _entries.length.toString();
      _boxController.addListener(_onBoxCountChanged);
    });
  }

  double get _totalResult => _entries.fold(0.0, (sum, e) => sum + e.result);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final requiredUnit = double.tryParse(widget.baseQuantity ?? '');
    final requiredBox = int.tryParse(widget.baseWeight ?? '');
    final enteredUnit = double.tryParse(_unitController.text.trim());
    final enteredBox = int.tryParse(_boxController.text.trim());

    if (requiredUnit != null &&
        (enteredUnit == null || (enteredUnit - requiredUnit).abs() > 0.1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Total Unit does not match required value'),
        ),
      );
      return;
    }
    if (requiredBox != null &&
        (enteredBox == null || enteredBox != requiredBox)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Total Box count does not match required value'),
        ),
      );
      return;
    }

    final supplier = FirebaseAuth.instance.currentUser;
    if (supplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated as supplier')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final items = <String, dynamic>{};
      for (int i = 0; i < _entries.length; i++) {
        final e = _entries[i];
        items['box_${i + 1}'] = {
          'qty': double.tryParse(e.val1.text.trim()) ?? 0,
          'deduction': double.tryParse(e.val2.text.trim()) ?? 0,
          'weight': e.result,
        };
      }

      final intimation = <String, dynamic>{
        'supplierId': supplier.uid,
        'companyId': widget.companyId,
        'materialName': widget.materialName,
        'unit': widget.unit,
        'totalUnit': enteredUnit,
        'totalBox': enteredBox,
        'items': items,
      };

      final service = CompanyService();
      await service.addSupplierIntimation(widget.requestId, intimation);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dispatch intimation submitted')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return AppScaffold(
      title: 'Send Material',
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(r.wp(4)),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Material display (read‑only)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: r.wp(3),
                    vertical: r.hp(1.5),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.greyBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.materialName,
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: r.sp(12),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.textLight,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: r.hp(2)),
                // Total Unit input (auto‑calculated, hint shows required)
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
                  controller: _unitController,
                  label: '',
                  hint: widget.baseQuantity != null
                      ? 'Required: ${widget.baseQuantity}'
                      : 'Enter total Unit',
                  isNumber: true,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                SizedBox(height: r.hp(1.8)),
                // Total Box input (editable, hint shows required)
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
                  controller: _boxController,
                  label: '',
                  hint: widget.baseWeight != null
                      ? 'Required: ${widget.baseWeight}'
                      : 'Enter total Box',
                  isNumber: true,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                SizedBox(height: r.hp(2.5)),
                // Entry list title
                Text(
                  'Enter the Count',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: r.sp(12),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: r.hp(1)),
                // Dynamic list of entries
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) => SizedBox(height: r.hp(1)),
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return Container(
                      padding: EdgeInsets.all(r.wp(2)),
                      decoration: BoxDecoration(
                        color: AppColors.greyBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppFormField(
                              controller: entry.val1,
                              label: '',
                              hint: '0.0',
                              isNumber: true,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          SizedBox(width: r.wp(2)),
                          Expanded(
                            child: AppFormField(
                              controller: entry.val2,
                              label: '',
                              hint: '0.0',
                              isNumber: true,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          SizedBox(width: r.wp(2)),
                          SizedBox(
                            width: r.wp(15),
                            child: Text(
                              entry.result.toStringAsFixed(1),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: r.sp(12),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _removeEntry(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: r.hp(2)),
                // Total display with unit
                Text(
                  'Entries total :- ${_totalResult.toStringAsFixed(1)} ${widget.unit ?? "Liter"}',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: r.sp(12),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: r.hp(4)),
                // Submit button
                PrimaryButton(
                  label: 'Submit',
                  loading: _submitting,
                  onTap: () => _submit(),
                  color: AppColors.primaryGreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
