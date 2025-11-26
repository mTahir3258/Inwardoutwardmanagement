import 'package:flutter/material.dart';
import 'package:inward_outward_management/providers/company_provider.dart';
import 'package:inward_outward_management/utils/app_colors.dart';
import 'package:inward_outward_management/utils/responsive.dart';
import 'package:inward_outward_management/widgets/app_scaffold.dart';
import 'package:inward_outward_management/screens/company/dispatch_box_confirmation_screen.dart';
import 'package:provider/provider.dart';

class SupplierIntimationScreen extends StatefulWidget {
  final String requestId;
  final String? materialName;

  const SupplierIntimationScreen({
    super.key,
    required this.requestId,
    this.materialName,
  });

  @override
  State<SupplierIntimationScreen> createState() =>
      _SupplierIntimationScreenState();
}

class _SupplierIntimationScreenState extends State<SupplierIntimationScreen> {
  bool _loading = false;
  List<Map<String, dynamic>> _intimations = [];

  @override
  void initState() {
    super.initState();
    _loadIntimations();
  }

  Future<void> _loadIntimations() async {
    setState(() => _loading = true);
    final prov = Provider.of<CompanyProvider>(context, listen: false);
    final data = await prov.loadSupplierIntimations(widget.requestId);
    setState(() {
      _intimations = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return AppScaffold(
      title: 'Supplier Intimations',
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _intimations.isEmpty
            ? Center(
                child: Text(
                  'No intimations received yet.',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: r.sp(12),
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadIntimations,
                child: ListView.builder(
                  padding: EdgeInsets.all(r.wp(4)),
                  itemCount: _intimations.length,
                  itemBuilder: (context, index) {
                    final intimation = _intimations[index];
                    return _buildIntimationCard(r, intimation);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildIntimationCard(Responsive r, Map<String, dynamic> intimation) {
    final supplierId = intimation['supplierId']?.toString() ?? '-';
    final supplierName = intimation['supplierName']?.toString() ?? '';
    final status = intimation['status']?.toString() ?? 'intimated';
    final items = intimation['items'];
    final intimationId = intimation['id']?.toString() ?? '';

    return Card(
      color: AppColors.greyBackground,
      margin: EdgeInsets.only(bottom: r.hp(1.2)),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => DispatchBoxConfirmationScreen(
                requestId: widget.requestId,
                intimation: intimation,
                materialName: widget.materialName,
              ),
            ),
          );
          if (result == true) {
            await _loadIntimations();
          }
        },
        child: Padding(
          padding: EdgeInsets.all(r.wp(3)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Supplier: ${supplierName.isNotEmpty ? supplierName : supplierId}',
                style: const TextStyle(color: AppColors.textLight),
              ),
              SizedBox(height: r.hp(0.6)),
              if (items is Map<String, dynamic>) ...[
                Text(
                  'Tap to view ${items.length} boxes',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: r.sp(11),
                  ),
                ),
              ],
              SizedBox(height: r.hp(0.6)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status: $status',
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textLight,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
