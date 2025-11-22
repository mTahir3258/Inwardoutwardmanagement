// lib/screens/company/company_dashboard.dart

import 'package:flutter/material.dart';
import 'package:inward_outward_management/screens/company/advanced_recieptscreen.dart';
import 'package:inward_outward_management/screens/company/lot/lot_listscreen.dart';
import 'package:inward_outward_management/screens/company/box/box_list_screen.dart';
import 'package:inward_outward_management/screens/company/inventory_screen.dart';
import 'package:inward_outward_management/screens/company/material_billing_screen.dart';
import 'package:inward_outward_management/screens/company/inward_history_screen.dart';
import 'package:inward_outward_management/screens/company/open_challanScreen.dart';
import 'package:inward_outward_management/screens/company/pending_billsscreen.dart';
import 'package:inward_outward_management/screens/company/pending_inward_screen.dart';
import 'package:inward_outward_management/screens/company/pending_outward_screen.dart';
import 'package:inward_outward_management/screens/company/supplier_request_screen.dart';
import 'package:inward_outward_management/screens/company/supplier_intimation_screen.dart';
import 'package:inward_outward_management/screens/company/standalone_box_confirmation_screen.dart';
import 'package:inward_outward_management/screens/company/user/create_user_screen.dart';
import 'package:inward_outward_management/providers/lot_provider.dart';
import 'package:inward_outward_management/providers/box_provider.dart';
import 'package:inward_outward_management/repository/lot_repository.dart';
import 'package:inward_outward_management/repository/box_repository.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inward_outward_management/providers/company_provider.dart';
import 'package:inward_outward_management/providers/nav_provider.dart';
import 'package:inward_outward_management/utils/responsive.dart';
import 'package:inward_outward_management/widgets/dashboard_card.dart';
import 'package:inward_outward_management/widgets/app_scaffold.dart';
import 'package:inward_outward_management/utils/app_colors.dart';
import 'package:inward_outward_management/widgets/primary_button.dart';

/// CompanyDashboardScreen:
/// - Displays dashboard summary cards
/// - Quick Access tiles for Master Data, Material Requests, Reports
/// - Navigation handled with NavProvider
/// - Floating action button for creating new materials/challans
class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load company data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<CompanyProvider>(context, listen: false);
      if (prov.companyId.isNotEmpty) {
        prov.loadDashboardSummary();
        prov.loadMaterials();
        prov.loadMaterialRequests();
      }
    });
  }

  Future<void> _handleConfirmStandaloneIntimation(
    Map<String, dynamic> intimation,
  ) async {
    // Navigate to box confirmation screen instead of directly creating challan
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StandaloneBoxConfirmationScreen(
          intimation: intimation,
        ),
      ),
    );

    // If confirmed, just refresh dashboard data (no challan creation)
    if (result == true && mounted) {
      final prov = Provider.of<CompanyProvider>(context, listen: false);
      await prov.loadStandaloneIntimations();
      await prov.loadDashboardSummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final user = FirebaseAuth.instance.currentUser;

    return Consumer<NavProvider>(
      builder: (context, nav, _) {
        // Screens for bottom navigation
        final screens = [
          _dashboardScreen(r, user),
          SupplierRequestScreen(),
          PendingBillsscreen(),
          OpenChallanscreen(),
        ];

        return AppScaffold(
          title: 'Company Dashboard',
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: AppColors.textLight),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ],
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primaryGreen,
            onPressed: () {
              Navigator.of(context).pushNamed('/materials');
            },
            child: const Icon(Icons.add, color: AppColors.textDark),
          ),
          body: screens[nav.index],
        );
      },
    );
  }

  Widget _standaloneIntimationsSection(Responsive r, CompanyProvider prov) {
    if (prov.loadingStandaloneIntimations) {
      return const Center(child: CircularProgressIndicator());
    }

    final list = prov.standaloneIntimations;
    if (list.isEmpty) {
      return Text(
        'No standalone intimations yet.',
        style: TextStyle(
          color: AppColors.textLight,
          fontSize: r.sp(11),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final itm = list[index];
        final supplierId = itm['supplierId']?.toString() ?? '-';
        final supplierName = itm['supplierName']?.toString() ?? '';
        final materialName = itm['materialName']?.toString() ?? '';
        final totalWeight =
            (itm['entriesTotalWeight'] ?? itm['totalWeightField'])?.toString() ?? '-';
        final boxes = itm['boxes']?.toString() ?? '-';
        final unitName = itm['unitName']?.toString() ?? '';
        final status = itm['status']?.toString() ?? 'intimated';

        return Card(
          color: AppColors.greyBackground,
          margin: EdgeInsets.only(bottom: r.hp(1.2)),
          child: Padding(
            padding: EdgeInsets.all(r.wp(3)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supplier : ${supplierName.isNotEmpty ? supplierName : supplierId}',
                  style: const TextStyle(color: AppColors.textLight),
                ),
                SizedBox(height: r.hp(0.6)),
                if (materialName.isNotEmpty) ...[
                  Text(
                    'Material : $materialName',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: r.sp(11),
                    ),
                  ),
                  SizedBox(height: r.hp(0.6)),
                ],
                if (unitName.isNotEmpty) ...[
                  Text(
                    'Unit : $unitName',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: r.sp(11),
                    ),
                  ),
                  SizedBox(height: r.hp(0.6)),
                ],
                Text(
                  'Total : $totalWeight ${unitName.isNotEmpty ? unitName : 'kg'}',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: r.sp(11),
                  ),
                ),
                SizedBox(height: r.hp(0.6)),
                Text(
                  'Boxes : $boxes',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: r.sp(11),
                  ),
                ),
                SizedBox(height: r.hp(0.6)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status : $status',
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (status != 'confirmed') ...[
                  SizedBox(height: r.hp(1.0)),
                  PrimaryButton(
                    label: 'Confirm',
                    onTap: () {
                      _handleConfirmStandaloneIntimation(itm);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows material requests where supplier has intimated or request is confirmed.
  /// Each tile opens SupplierIntimationScreen where company can see full
  /// dispatch details and confirm.
  Widget _dispatchIntimationsSection(Responsive r, CompanyProvider prov) {
    // Show all material requests so company can always see what has been
    // requested and whether dispatch intimation / confirmation is done.
    final intimated = prov.requests;

    if (prov.loadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (intimated.isEmpty) {
      return Text(
        'No dispatch intimations yet.',
        style: TextStyle(
          color: AppColors.textLight,
          fontSize: r.sp(11),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: intimated.length,
      itemBuilder: (context, index) {
        final req = intimated[index];
        final material = req['materialName']?.toString() ?? '-';
        final qty = req['quantity']?.toString() ?? '-';
        final weight = req['weight']?.toString() ?? '-';
        final status = req['status']?.toString() ?? '-';
        final supplierEmail = req['supplierEmail']?.toString() ?? '-';
        final id = req['id']?.toString() ?? '';

        return Card(
          color: AppColors.greyBackground,
          margin: EdgeInsets.only(bottom: r.hp(1.2)),
          child: ListTile(
            onTap: id.isEmpty
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SupplierIntimationScreen(
                          requestId: id,
                          materialName: material,
                        ),
                      ),
                    );
                  },
            title: Text(
              material,
              style: const TextStyle(color: AppColors.textLight),
            ),
            subtitle: Text(
              'Supplier: $supplierEmail\nQty: $qty | Weight: ${weight}kg\nStatus: $status',
              style: const TextStyle(color: AppColors.textLight),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.textLight,
            ),
          ),
        );
      },
    );
  }

  /// Dashboard screen widget
  Widget _dashboardScreen(Responsive r, User? user) {
    return SafeArea(
      child: Consumer<CompanyProvider>(
        builder: (context, prov, _) {
          if (prov.companyId.isEmpty) {
            return _companyDataNotAvailable(r);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await prov.loadDashboardSummary();
              await prov.loadMaterials();
              await prov.loadMaterialRequests();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(r.wp(4)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topGreetingRow(r, user),
                  SizedBox(height: r.hp(2)),
                  _summaryCards(r, prov),
                  SizedBox(height: r.hp(3)),
                  const Text(
                    'Quick Access',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: r.hp(1.5)),
                  _quickAccessTiles(r),
                  SizedBox(height: r.hp(3)),
                  const Text(
                    'Dispatch Intimations',
                    style: TextStyle(color:AppColors.textLight,fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: r.hp(1.5)),
                  _dispatchIntimationsSection(r, prov),
                  SizedBox(height: r.hp(3)),
                  const Text(
                    'Standalone Dispatch Intimations',
                    style: TextStyle(color:AppColors.textLight,fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: r.hp(1.5)),
                  _standaloneIntimationsSection(r, prov),
                  SizedBox(height: r.hp(10)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _companyDataNotAvailable(Responsive r) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: r.wp(6)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.orange,
            ),
            SizedBox(height: r.hp(2)),
            Text(
              'Company data not available yet.\nPlease login or ensure you are a company user.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: r.sp(12)),
            ),
            SizedBox(height: r.hp(2)),
            ElevatedButton(
              onPressed: () => Navigator.of(
                // navigatorKey.currentContext!,
                context,
              ).pushReplacementNamed('/roleRouter'),
              child: const Text('Go to Login / Role Router'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topGreetingRow(Responsive r, User? user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(r.wp(4)),
      decoration: BoxDecoration(
        color: AppColors.greyBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: r.wp(8),
            backgroundColor: AppColors.primaryGreen.withOpacity(0.15),
            child: Icon(
              Icons.business,
              size: r.sp(24),
              color: AppColors.primaryGreen,
            ),
          ),
          SizedBox(width: r.wp(4)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome${user?.displayName != null ? ', ${user!.displayName}' : ''}',
                  style: TextStyle(
                    fontSize: r.sp(14),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                SizedBox(height: r.hp(0.6)),
                Text(
                  'Manage materials, challans, bills and receipts from here.',
                  style: TextStyle(
                    fontSize: r.sp(11),
                    color: AppColors.textLight.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCards(Responsive r, CompanyProvider prov) {
    final crossAxis = r.isDesktop ? 3 : (r.isTablet ? 2 : 2);
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final cardWidth =
            (constraints.maxWidth - (crossAxis - 1) * r.wp(3)) / crossAxis;
        return Wrap(
          spacing: r.wp(3),
          runSpacing: r.hp(2),
          children: [
            _dashboardCard(
              r,
              prov.pendingInward,
              'Pending Inward',
              Icons.inventory_2_outlined,
              AppColors.primaryGreen,
              PendingInwardScreen(),
            ),
            _dashboardCard(
              r,
              prov.supplierRequests,
              'Supplier Requests',
              Icons.people_outline,
              Colors.purpleAccent,
              SupplierRequestScreen(),
            ),
            _dashboardCard(
              r,
              prov.openChallans,
              'Open Challans',
              Icons.list_alt_outlined,
              Colors.orangeAccent,
              OpenChallanscreen(),
            ),
            _dashboardCard(
              r,
              prov.pendingBills,
              'Pending Bills',
              Icons.receipt_long_outlined,
              Colors.redAccent,
              PendingBillsscreen(),
            ),
            _dashboardCard(
              r,
              '₹${prov.advanceReceiptsTotal.toStringAsFixed(0)}',
              'Advance Receipts',
              Icons.account_balance_wallet_outlined,
              Colors.amberAccent,
              AdvancedRecieptscreen(),
            ),
          ].map((e) => SizedBox(width: cardWidth, child: e)).toList(),
        );
      },
    );
  }

  Widget _dashboardCard(
    Responsive r,
    dynamic count,
    String label,
    IconData icon,
    Color color,
    Widget screen,
  ) {
    return DashboardCard(
      icon: icon,
      color: color,
      count: '$count',
      label: label,
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
    );
  }

  Widget _quickAccessTiles(Responsive r) {
    return Column(
      children: [
        _quickActionTile(
          context,
          icon: Icons.storage_outlined,
          label: 'Master Data',
          onTap: () => Navigator.of(context).pushNamed('/materials'),
        ),
        _quickActionTile(
          context,
          icon: Icons.receipt_long_outlined,
          label: 'Create Bill',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MaterialBillingScreen()),
            );
          },
        ),
        _quickActionTile(
          context,
          icon: Icons.inventory_2_outlined,
          label: 'Inventory',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InventoryScreen()),
            );
          },
        ),
        _quickActionTile(
          context,
          icon: Icons.view_week_outlined,
          label: 'Lot Master',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider(
                  create: (ctx) {
                    final companyProv = Provider.of<CompanyProvider>(
                      ctx,
                      listen: false,
                    );
                    final lotProv = LotProvider(LotRepository());
                    lotProv.companyId = companyProv.companyId;
                    return lotProv;
                  },
                  child: const LotListScreen(),
                ),
              ),
            );
          },
        ),
        _quickActionTile(
          context,
          icon: Icons.history_toggle_off_outlined,
          label: 'Inward History',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InwardHistoryScreen()),
            );
          },
        ),
        _quickActionTile(
          context,
          icon: Icons.all_inbox_outlined,
          label: 'Box Master',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider(
                  create: (ctx) {
                    final companyProv = Provider.of<CompanyProvider>(
                      ctx,
                      listen: false,
                    );
                    final boxProv = BoxProvider(BoxRepository());
                    boxProv.companyId = companyProv.companyId;
                    return boxProv;
                  },
                  child: const BoxListScreen(),
                ),
              ),
            );
          },
        ),
        _quickActionTile(
          context,
          icon: Icons.request_page_outlined,
          label: 'Material Requests',
          onTap: () => Navigator.of(context).pushNamed('/materialRequests'),
        ),
        _quickActionTile(
          context,
          icon: Icons.person_add_alt_1_outlined,
          label: 'Create Supplier/Customer User',
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CreateUserScreen()));
          },
        ),
      ],
    );
  }

  Widget _quickActionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final r = Responsive(context);
    return Container(
      margin: EdgeInsets.only(bottom: r.hp(1.4)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.greyBackground,
          child: Icon(icon, color: AppColors.primaryGreen),
        ),
        title: Text(
          label,
          style: TextStyle(color: AppColors.textLight, fontSize: r.sp(12)),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
        tileColor: AppColors.greyBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(
          vertical: r.hp(1.2),
          horizontal: r.wp(3),
        ),
      ),
    );
  }
}
