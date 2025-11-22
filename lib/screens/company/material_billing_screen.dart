import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inward_outward_management/core/models/customer_model.dart';
import 'package:inward_outward_management/core/models/material_model.dart';
import 'package:inward_outward_management/providers/company_provider.dart';
import 'package:inward_outward_management/utils/app_colors.dart';
import 'package:inward_outward_management/utils/responsive.dart';
import 'package:inward_outward_management/widgets/app_scaffold.dart';
import 'package:inward_outward_management/widgets/app_form_field.dart';
import 'package:inward_outward_management/widgets/primary_button.dart';
import 'package:provider/provider.dart';

class MaterialBillingScreen extends StatefulWidget {
  const MaterialBillingScreen({super.key});

  @override
  State<MaterialBillingScreen> createState() => _MaterialBillingScreenState();
}

class _BillLine {
  final String materialName;
  final String unitName;
  final double quantity;
  final double rate;

  const _BillLine({
    required this.materialName,
    required this.unitName,
    required this.quantity,
    required this.rate,
  });

  double get amount => quantity * rate;
}

class _MaterialBillingScreenState extends State<MaterialBillingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _materialCtr = TextEditingController();
  final _unitCtr = TextEditingController();
  final _rateCtr = TextEditingController();
  final _qtyCtr = TextEditingController();

  CustomerModel? _selectedCustomer;

  MaterialModel? _selectedMaterial;

  bool _submitting = false;

  final List<_BillLine> _lines = [];

  @override
  void dispose() {
    _materialCtr.dispose();
    _unitCtr.dispose();
    _rateCtr.dispose();
    _qtyCtr.dispose();
    super.dispose();
  }

  double get _billTotal =>
      _lines.fold(0.0, (prev, e) => prev + e.amount);

  void _addLine() {
    final material = _selectedMaterial;
    final qtyText = _qtyCtr.text.trim();
    final rateText = _rateCtr.text.trim();

    final qty = double.tryParse(qtyText) ?? 0.0;
    final rate = double.tryParse(rateText) ?? 0.0;

    if (material == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a material.')),
      );
      return;
    }

    if (qty <= 0 || rate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid quantity and rate.')),
      );
      return;
    }

    // Check inventory availability for this material at add-time
    final companyProv = Provider.of<CompanyProvider>(context, listen: false);
    final stockList = companyProv.standaloneIntimations
        .where((it) => (it['status']?.toString() ?? '') == 'confirmed')
        .toList();

    final key = '${material.name}|${material.unit}';
    double available = 0.0;
    for (final itm in stockList) {
      final matName = itm['materialName']?.toString() ?? '';
      final unitName = itm['unitName']?.toString() ?? '';
      if ('$matName|$unitName' != key) continue;

      final totalVal =
          itm['remainingWeight'] ?? itm['entriesTotalWeight'] ?? itm['totalWeightField'];
      final rem = (totalVal is num)
          ? totalVal.toDouble()
          : double.tryParse('${totalVal ?? 0}') ?? 0.0;
      available += rem;
    }

    // subtract already added quantity for this material in current bill
    double alreadyAdded = 0.0;
    for (final l in _lines) {
      if (l.materialName == material.name && l.unitName == material.unit) {
        alreadyAdded += l.quantity;
      }
    }

    final remainingForThisMaterial = available - alreadyAdded;

    if (remainingForThisMaterial <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Material "${material.name}" is not available in inventory or already fully used.',
          ),
        ),
      );
      _qtyCtr.clear();
      _rateCtr.clear();
      _selectedMaterial = null;
      return;
    }

    if (qty > remainingForThisMaterial) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Quantity for "${material.name}" exceeds remaining stock. '
            'You can add up to ${remainingForThisMaterial.toStringAsFixed(2)} ${material.unit}.',
          ),
        ),
      );
      _qtyCtr.clear();
      _rateCtr.clear();
      return;
    }

    setState(() {
      _lines.add(_BillLine(
        materialName: material.name,
        unitName: material.unit,
        quantity: qty,
        rate: rate,
      ));
      _qtyCtr.clear();
      _rateCtr.clear();
      _materialCtr.clear();
      _unitCtr.clear();
      _selectedMaterial = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final companyProv = Provider.of<CompanyProvider>(context);

    return AppScaffold(
      title: 'Create Bill',
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: r.wp(4),
                vertical: r.hp(2.5),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.greyBackground,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: r.wp(4),
                  vertical: r.hp(2.5),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Customer',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: r.sp(12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: r.hp(1)),
                      DropdownButtonFormField<CustomerModel>(
                        value: _selectedCustomer,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.primaryDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: r.wp(3),
                            vertical: r.hp(1.2),
                          ),
                        ),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.textLight,
                        ),
                        dropdownColor: AppColors.primaryDark,
                        items: companyProv.customers
                            .map(
                              (c) => DropdownMenuItem<CustomerModel>(
                                value: c,
                                child: Text(
                                  c.name,
                                  style: TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: r.sp(9),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCustomer = val;
                          });
                        },
                        validator: (val) {
                          if (val == null) {
                            return 'Select a customer';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: r.hp(1.8)),
                      Divider(
                        color: AppColors.primaryDark.withOpacity(0.4),
                        height: r.hp(2),
                      ),
                      SizedBox(height: r.hp(0.2)),
                      Text(
                        'Materials',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: r.sp(13),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: r.hp(1.2)),
                      if (_lines.isEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: r.wp(3.2),
                            vertical: r.hp(1.4),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'No materials added yet.',
                            style: TextStyle(
                              color: AppColors.textLight.withOpacity(0.8),
                              fontSize: r.sp(10),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            ..._lines.asMap().entries.map((entry) {
                              final index = entry.key;
                              final line = entry.value;
                              return Container(
                                margin: EdgeInsets.only(bottom: r.hp(0.8)),
                                padding: EdgeInsets.symmetric(
                                  horizontal: r.wp(3.2),
                                  vertical: r.hp(1.2),
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            line.materialName,
                                            style: TextStyle(
                                              color: AppColors.textLight,
                                              fontSize: r.sp(12),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: r.hp(0.3)),
                                          Text(
                                            '${line.quantity.toStringAsFixed(2)} ${line.unitName} @ ₹ ${line.rate.toStringAsFixed(2)}/${line.unitName}',
                                            style: TextStyle(
                                              color: AppColors.textLight.withOpacity(0.85),
                                              fontSize: r.sp(10),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹ ${line.amount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: AppColors.textLight,
                                            fontSize: r.sp(12),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _lines.removeAt(index);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      SizedBox(height: r.hp(2.8)),
                      Text(
                        'Add Material',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: r.sp(12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: r.hp(1)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: r.wp(3.2),
                          vertical: r.hp(1.6),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Material',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: r.sp(11),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: r.hp(0.6)),
                            DropdownButtonFormField<MaterialModel>(
                              isExpanded: true,
                              value: _selectedMaterial,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.greyBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Colors.transparent,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Colors.transparent,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: r.wp(3),
                                  vertical: r.hp(1),
                                ),
                              ),
                              dropdownColor: AppColors.greyBackground,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.textLight,
                              ),
                              items: companyProv.materials
                                  .map(
                                    (m) => DropdownMenuItem<MaterialModel>(
                                      value: m,
                                      child: Text(
                                        m.name,
                                        style: TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: r.sp(10),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedMaterial = val;
                                });
                              },
                            ),
                            SizedBox(height: r.hp(0.8)),
                            Text(
                              _selectedMaterial == null
                                  ? 'Unit: -'
                                  : 'Unit: ${_selectedMaterial!.unit}',
                              style: TextStyle(
                                color: AppColors.textLight.withOpacity(0.85),
                                fontSize: r.sp(10),
                              ),
                            ),
                            SizedBox(height: r.hp(1)),
                            Row(
                              children: [
                                Expanded(
                                  child: AppFormField(
                                    controller: _qtyCtr,
                                    label: 'Quantity',
                                    isNumber: true,
                                    validator: (_) => null,
                                    onChanged: (_) {
                                      setState(() {});
                                    },
                                  ),
                                ),
                                SizedBox(width: r.wp(2)),
                                Expanded(
                                  child: AppFormField(
                                    controller: _rateCtr,
                                    label: 'Rate per unit',
                                    isNumber: true,
                                    validator: (_) => null,
                                    onChanged: (_) {
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: r.hp(1.4)),
                            SizedBox(
                              width: double.infinity,
                              child: PrimaryButton(
                                label: 'Add Material',
                                onTap: _addLine,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: r.hp(2.8)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: r.wp(3.2),
                          vertical: r.hp(1.6),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Bill Amount',
                              style: TextStyle(
                                color: AppColors.textLight.withOpacity(0.9),
                                fontSize: r.sp(12),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '₹ ${_billTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: r.sp(15),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: r.hp(3)),
                      PrimaryButton(
                        label: 'Generate Invoice',
                        loading: _submitting,
                        onTap: () {
                          if (_submitting) return;
                          _createBill();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createBill() async {
    if (!_formKey.currentState!.validate()) return;

    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one material line.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      if (!mounted) return;
      final customer = _selectedCustomer;
      if (customer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a customer')),
        );
        return;
      }

      final totalQty = _lines.fold(0.0, (p, l) => p + l.quantity);
      final amount = _billTotal;
      final effectiveRate = totalQty == 0 ? 0.0 : amount / totalQty;

      final now = DateTime.now();
      final invoiceNumber =
          'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';

      // Validate against inventory (standalone intimations) and prepare updates
      final companyProv = Provider.of<CompanyProvider>(context, listen: false);
      final companyId = companyProv.companyId;
      final Map<String, double> remainingUpdatesById = {};

      if (companyId.isNotEmpty) {
        final stockList = companyProv.standaloneIntimations;

        // Build stock map: key = materialName|unitName -> list of intimation maps
        final Map<String, List<Map<String, dynamic>>> stockByKey = {};
        for (final itm in stockList) {
          final materialName = itm['materialName']?.toString() ?? '';
          final unitName = itm['unitName']?.toString() ?? '';
          if (materialName.isEmpty || unitName.isEmpty) continue;

          final key = '$materialName|$unitName';
          final totalVal = itm['remainingWeight'] ??
              itm['entriesTotalWeight'] ??
              itm['totalWeightField'];
          final remaining = (totalVal is num)
              ? totalVal.toDouble()
              : double.tryParse('${totalVal ?? 0}') ?? 0.0;
          final id = itm['id']?.toString() ?? '';
          if (id.isEmpty || remaining <= 0) continue;

          stockByKey.putIfAbsent(key, () => []).add(itm);
        }

        // Group lines per material/unit and validate required qty
        final Map<String, double> requiredByKey = {};
        for (final l in _lines) {
          final key = '${l.materialName}|${l.unitName}';
          requiredByKey[key] = (requiredByKey[key] ?? 0.0) + l.quantity;
        }

        for (final entry in requiredByKey.entries) {
          final key = entry.key;
          final requiredQty = entry.value;
          final stockEntries = stockByKey[key] ?? [];

          double available = 0.0;
          for (final itm in stockEntries) {
            final totalVal = itm['remainingWeight'] ??
                itm['entriesTotalWeight'] ??
                itm['totalWeightField'];
            final rem = (totalVal is num)
                ? totalVal.toDouble()
                : double.tryParse('${totalVal ?? 0}') ?? 0.0;
            available += rem;
          }

          if (available <= 0) {
            final parts = key.split('|');
            final matName = parts.isNotEmpty ? parts.first : 'material';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Material "$matName" not available in inventory.'),
              ),
            );
            return;
          }

          if (requiredQty > available) {
            final parts = key.split('|');
            final matName = parts.isNotEmpty ? parts.first : 'material';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Quantity for "$matName" exceeds available stock. Required: '
                  '${requiredQty.toStringAsFixed(2)}, Available: '
                  '${available.toStringAsFixed(2)}',
                ),
              ),
            );
            return;
          }

          // Simulate deduction across stock entries and record new remainingWeight
          double remainingNeed = requiredQty;
          for (final itm in stockEntries) {
            if (remainingNeed <= 0) break;
            final totalVal = itm['remainingWeight'] ??
                itm['entriesTotalWeight'] ??
                itm['totalWeightField'];
            final current = (totalVal is num)
                ? totalVal.toDouble()
                : double.tryParse('${totalVal ?? 0}') ?? 0.0;
            if (current <= 0) continue;

            final take = remainingNeed > current ? current : remainingNeed;
            final newRemaining = (current - take).clamp(0.0, current);
            final id = itm['id']?.toString() ?? '';
            if (id.isNotEmpty) {
              remainingUpdatesById[id] = newRemaining;
            }
            remainingNeed -= take;
          }
        }
      }

      final primaryMaterialName = _lines.length == 1
          ? _lines.first.materialName
          : 'Multiple Items';
      final primaryUnitName = _lines.isNotEmpty ? _lines.first.unitName : '';

      final invoiceData = <String, dynamic>{
        'customerId': customer.mobile,
        'customerName': customer.name,
        'invoiceNumber': invoiceNumber,
        'materialName': primaryMaterialName,
        'quantity': totalQty,
        'unitName': primaryUnitName,
        'ratePerUnit': effectiveRate,
        'amount': amount,
        'availableQuantity': totalQty,
        'remainingQuantity': 0.0,
        'lines': _lines
            .map(
              (l) => {
                'materialName': l.materialName,
                'unitName': l.unitName,
                'quantity': l.quantity,
                'ratePerUnit': l.rate,
                'amount': l.amount,
              },
            )
            .toList(),
        'status': 'pending',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      await FirebaseFirestore.instance
          .collection('customers')
          .doc(customer.mobile)
          .collection('invoices')
          .add(invoiceData);

      // Apply inventory updates (best-effort)
      if (companyId.isNotEmpty && remainingUpdatesById.isNotEmpty) {
        try {
          final companies = FirebaseFirestore.instance
              .collection('companies')
              .doc(companyId)
              .collection('standalone_intimations');
          for (final entry in remainingUpdatesById.entries) {
            await companies.doc(entry.key).update({
              'remainingWeight': entry.value,
            });
          }
          await companyProv.loadStandaloneIntimations();
        } catch (_) {
          // ignore inventory update failures
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invoice generated for ${customer.name}'),
        ),
      );

      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}
