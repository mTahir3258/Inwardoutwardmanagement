import 'package:flutter/material.dart';
import 'package:inward_outward_management/providers/company_provider.dart';
import 'package:inward_outward_management/utils/app_colors.dart';
import 'package:inward_outward_management/utils/responsive.dart';
import 'package:inward_outward_management/screens/company/material_billing_screen.dart';
import 'package:provider/provider.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final prov = Provider.of<CompanyProvider>(context);
    // Standalone confirmed intimations (no challan created)
    final confirmedStandalone = prov.standaloneIntimations
        .where((it) => (it['status']?.toString() ?? '') == 'confirmed')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory',style: TextStyle(fontSize: 23 , fontWeight: FontWeight.w600 ,color: AppColors.textLight),),
        backgroundColor: AppColors.greyBackground,
      ),
      backgroundColor: AppColors.primaryDark,
      body: Padding(
        padding: EdgeInsets.all(r.wp(4)),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (confirmedStandalone.isNotEmpty) ...[
                SizedBox(height: r.hp(3)),
                Text(
                  'Available Materials',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: r.sp(13),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: r.hp(1)),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: confirmedStandalone.length,
                  separatorBuilder: (_, __) => SizedBox(height: r.hp(0.8)),
                  itemBuilder: (context, index) {
                    final it = confirmedStandalone[index];
                    final materialName =
                        it['materialName']?.toString() ?? 'Unknown';
                    final unitName = it['unitName']?.toString() ?? '';
                    final totalVal = it['remainingWeight'] ??
                        it['entriesTotalWeight'] ?? it['totalWeightField'];
                    final total = (totalVal is num)
                        ? totalVal.toDouble()
                        : double.tryParse('${totalVal ?? 0}') ?? 0.0;
                    final intimationId = it['id']?.toString() ?? '';

                    return Container(
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
                                color: AppColors.textLight.withOpacity(0.8),
                                fontSize: r.sp(10),
                              ),
                            ),
                            SizedBox(height: r.hp(0.2)),
                            Text(
                              'Total: ${total.toStringAsFixed(1)} $unitName',
                              style: TextStyle(
                                color: AppColors.textLight.withOpacity(0.8),
                                fontSize: r.sp(10),
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.textLight,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MaterialBillingScreen(),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ] else ...[
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: r.hp(2)),
                    child: Text(
                      'No confirmed standalone dispatches.',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: r.sp(12),
                      ),
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
