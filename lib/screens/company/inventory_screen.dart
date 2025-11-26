import 'package:flutter/material.dart';
import 'package:inward_outward_management/providers/company_provider.dart';
import 'package:inward_outward_management/services/company_services.dart';
import 'package:inward_outward_management/utils/app_colors.dart';
import 'package:inward_outward_management/utils/responsive.dart';
import 'package:provider/provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> _allIntimations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Defer loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllIntimations();
    });
  }

  Future<void> _loadAllIntimations() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final prov = Provider.of<CompanyProvider>(context, listen: false);

    // Reload fresh data from Firestore
    await prov.loadMaterialRequests();
    await prov.loadStandaloneIntimations();

    // Collect all intimations
    final allIntimations = <Map<String, dynamic>>[];

    // Add standalone intimations
    for (var intimation in prov.standaloneIntimations) {
      final status = intimation['status']?.toString() ?? '';
      if (status == 'intimated' || status == 'confirmed') {
        allIntimations.add({...intimation, 'source': 'standalone'});
      }
    }

    // Add request-based intimations
    final service = CompanyService();
    for (var request in prov.requests) {
      final requestStatus = request['status']?.toString() ?? '';
      if (requestStatus == 'intimated' || requestStatus == 'confirmed') {
        final requestId = request['id']?.toString() ?? '';
        if (requestId.isNotEmpty) {
          try {
            final intimations = await service.getSupplierIntimations(requestId);
            for (var intimation in intimations) {
              allIntimations.add({
                ...intimation,
                'source': 'request-based',
                'requestId': requestId,
                if (intimation['materialName'] == null)
                  'materialName': request['materialName'],
                if (intimation['unit'] == null) 'unit': request['unit'],
              });
            }
          } catch (e) {
            debugPrint('Error loading intimations for request $requestId: $e');
          }
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _allIntimations = allIntimations;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inventory',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w600,
            color: AppColors.textLight,
          ),
        ),
        backgroundColor: AppColors.greyBackground,
      ),
      backgroundColor: AppColors.primaryDark,
      body: RefreshIndicator(
        onRefresh: _loadAllIntimations,
        child: Padding(
          padding: EdgeInsets.all(r.wp(4)),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    if (_allIntimations.isNotEmpty) ...[
                      SizedBox(height: r.hp(2)),
                      Text(
                        'Available Materials',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: r.sp(13),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: r.hp(1)),
                      ...List.generate(_allIntimations.length, (index) {
                        final it = _allIntimations[index];
                        final materialName =
                            it['materialName']?.toString() ?? 'Unknown';
                        final unitName =
                            it['unit']?.toString() ??
                            it['unitName']?.toString() ??
                            '';
                        final source = it['source']?.toString() ?? '';

                        // Calculate total
                        final totalVal =
                            it['remainingWeight'] ??
                            it['entriesTotalWeight'] ??
                            it['totalWeightField'] ??
                            it['totalUnit'];
                        final total = (totalVal is num)
                            ? totalVal.toDouble()
                            : double.tryParse('$totalVal') ?? 0.0;

                        return Padding(
                          padding: EdgeInsets.only(bottom: r.hp(0.8)),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.greyBackground,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              title: Text(
                                materialName,
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w600,
                                  fontSize: r.sp(10),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: r.hp(0.3)),
                                  Text(
                                    'Unit: $unitName',
                                    style: TextStyle(
                                      color: AppColors.textLight.withOpacity(
                                        0.8,
                                      ),
                                      fontSize: r.sp(10),
                                    ),
                                  ),
                                  SizedBox(height: r.hp(0.2)),
                                  Text(
                                    'Total: ${total.toStringAsFixed(1)} $unitName',
                                    style: TextStyle(
                                      color: AppColors.textLight.withOpacity(
                                        0.8,
                                      ),
                                      fontSize: r.sp(10),
                                    ),
                                  ),
                                  if (source.isNotEmpty) ...[
                                    SizedBox(height: r.hp(0.2)),
                                    Text(
                                      'Source: ${source == 'standalone' ? 'Direct' : 'Request'}',
                                      style: TextStyle(
                                        color: AppColors.primaryGreen
                                            .withOpacity(0.7),
                                        fontSize: r.sp(9),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ] else ...[
                      SizedBox(height: r.hp(10)),
                      Center(
                        child: Text(
                          'No intimated materials.\nPull down to refresh.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: r.sp(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
