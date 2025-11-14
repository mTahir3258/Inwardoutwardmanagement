// lib/screens/company/company_dashboard.dart

import 'package:flutter/material.dart';
import 'package:inward_outward_management/screens/company/open_challanScreen.dart';
import 'package:inward_outward_management/screens/company/pending_billsscreen.dart';
import 'package:inward_outward_management/screens/company/pending_inward_screen.dart';
import 'package:inward_outward_management/screens/company/pending_outward_screen.dart';
import 'package:inward_outward_management/screens/company/supplier_request_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inward_outward_management/providers/company_provider.dart';
import 'package:inward_outward_management/providers/nav_provider.dart';
import 'package:inward_outward_management/utils/responsive.dart';
import 'package:inward_outward_management/widgets/dashboard_card.dart';

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
      }
    });
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

        return Scaffold(
          backgroundColor: const Color(0xFFF2F2F2),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Company Dashboard',
              style: TextStyle(color: Colors.black),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.black),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted)
                    Navigator.of(context).pushReplacementNamed('/login');
                },
              ),
            ],
          ),
          body: screens[nav.index],
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.green,
            onPressed: () {
              Navigator.of(context).pushNamed('/materials');
            },
            child: const Icon(Icons.add),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: r.wp(8),
            backgroundColor: Colors.green.shade50,
            child: Icon(Icons.business, size: r.sp(24), color: Colors.green),
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
                  ),
                ),
                SizedBox(height: r.hp(0.6)),
                Text(
                  'Manage materials, challans, bills and receipts from here.',
                  style: TextStyle(fontSize: r.sp(11), color: Colors.black54),
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
              Colors.green,
              PendingInwardScreen(),
            ),
            _dashboardCard(
              r,
              prov.pendingOutward,
              'Pending Outward',
              Icons.outbox_outlined,
              Colors.blue,
              PendingOutwardScreen(),
            ),
            _dashboardCard(
              r,
              prov.supplierRequests,
              'Supplier Requests',
              Icons.people_outline,
              Colors.purple,
              SupplierRequestScreen(),
            ),
            _dashboardCard(
              r,
              prov.openChallans,
              'Open Challans',
              Icons.list_alt_outlined,
              Colors.orange,
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
              Colors.amber,
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
          icon: Icons.request_page_outlined,
          label: 'Material Requests',
          onTap: () => Navigator.of(context).pushNamed('/materialRequests'),
        ),
        _quickActionTile(
          context,
          icon: Icons.insert_chart_outlined,
          label: 'Reports',
          onTap: () {},
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
          backgroundColor: Colors.grey.shade100,
          child: Icon(icon, color: Colors.black54),
        ),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        tileColor: Colors.white,
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

class AdvancedRecieptscreen extends StatelessWidget {
  const AdvancedRecieptscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Advanced Reciept Screen',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
