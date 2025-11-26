import 'package:flutter/material.dart';
import 'package:inward_outward_management/providers/company_provider.dart';
import 'package:inward_outward_management/utils/app_colors.dart';
import 'package:inward_outward_management/utils/responsive.dart';
import 'package:inward_outward_management/widgets/app_scaffold.dart';
import 'package:inward_outward_management/widgets/primary_button.dart';
import 'package:provider/provider.dart';

class DispatchBoxConfirmationScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> intimation;
  final String? materialName;

  const DispatchBoxConfirmationScreen({
    super.key,
    required this.requestId,
    required this.intimation,
    this.materialName,
  });

  @override
  State<DispatchBoxConfirmationScreen> createState() =>
      _DispatchBoxConfirmationScreenState();
}

class _DispatchBoxConfirmationScreenState
    extends State<DispatchBoxConfirmationScreen> {
  late final List<MapEntry<String, Map<String, dynamic>>> _boxes;
  late List<bool> _confirmed;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final rawItems = widget.intimation['items'];
    Map<String, dynamic> itemsMap;
    if (rawItems is Map<String, dynamic>) {
      itemsMap = rawItems;
    } else {
      itemsMap = {};
    }
    final entries = itemsMap.entries
        .map((e) => MapEntry(e.key.toString(), Map<String, dynamic>.from(e.value ?? {})))
        .toList();
    entries.sort((a, b) => a.key.compareTo(b.key));
    _boxes = entries;
    _confirmed = List<bool>.filled(_boxes.length, false);
  }

  Future<void> _confirm() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final prov = Provider.of<CompanyProvider>(context, listen: false);
      final challanId = await prov.confirmIntimationAndCreateChallan(
        widget.requestId,
        widget.intimation,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Challan created successfully (ID: $challanId)'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final supplierId = widget.intimation['supplierId']?.toString() ?? '-';
    final supplierName = widget.intimation['supplierName']?.toString() ?? '';
    final displaySupplier =
        supplierName.isNotEmpty ? supplierName : supplierId;
    final materialName =
        widget.intimation['materialName']?.toString() ?? widget.materialName ?? '';
    final unitName = (widget.intimation['unit'] ??
            widget.intimation['unitName'] ??
            '')
        .toString();
    final totalUnit = widget.intimation['totalUnit'] ??
        widget.intimation['entriesTotalWeight'] ??
        widget.intimation['totalWeightField'];
    final totalBox = widget.intimation['totalBox'] ??
        widget.intimation['boxes'];

    final totalUnits = _boxes.fold<double>(
      0,
      (sum, e) {
        final v = e.value;
        final raw = (v['weight'] ?? v['materialKg'] ?? v['qty'] ?? 0) as num;
        return sum + raw.toDouble();
      },
    );

    return AppScaffold(
      title: 'Box Confirmation',
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(r.wp(4)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(r.wp(3)),
                decoration: BoxDecoration(
                  color: AppColors.greyBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Supplier',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: r.sp(10),
                              ),
                            ),
                            Text(
                              displaySupplier,
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: r.sp(12),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Material',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: r.sp(10),
                              ),
                            ),
                            Text(
                              materialName,
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: r.sp(12),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: r.hp(0.8)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unit',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: r.sp(10),
                              ),
                            ),
                            Text(
                              unitName,
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: r.sp(12),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: r.sp(10),
                              ),
                            ),
                            Text(
                              totalUnit != null
                                  ? '${totalUnit.toString()} ${unitName.isNotEmpty ? unitName : ''}'
                                  : '-',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: r.sp(12),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: r.hp(2)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Confirm Boxes',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: r.sp(12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Total: ${totalBox ?? _boxes.length}',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: r.sp(11),
                    ),
                  ),
                ],
              ),
              SizedBox(height: r.hp(1)),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.greyBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    itemCount: _boxes.length,
                    itemBuilder: (context, index) {
                      final entry = _boxes[index];
                      final label =
                          entry.key.isNotEmpty ? entry.key : 'Box ${index + 1}';
                      final v = entry.value;
                      final raw =
                          (v['weight'] ?? v['materialKg'] ?? v['qty'] ?? 0) as num;
                      final value = raw.toDouble();
                      final checked = _confirmed[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.textLight,
                        ),
                        title: Text(
                          label,
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: r.sp(11),
                          ),
                        ),
                        subtitle: Text(
                          '${value.toStringAsFixed(1)} ${unitName.isNotEmpty ? unitName : ''}',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: r.sp(10),
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            checked
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: checked
                                ? AppColors.primaryGreen
                                : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _confirmed[index] = !checked;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: r.hp(1.5)),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(bottom: r.hp(0.5)),
                  child: Text(
                    'Total boxes: ${totalBox ?? _boxes.length}, Total unit: ${totalUnits.toStringAsFixed(1)} ${unitName.isNotEmpty ? unitName : ''}',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: r.sp(11),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              PrimaryButton(
                label: 'Confirm',
                loading: _submitting,
                onTap: _confirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
