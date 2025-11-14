// CompanyMainScreen: holds bottom navigation and the company tabs.
// Uses NavProvider to change tabs while preserving state via IndexedStack.

import 'package:flutter/material.dart';
import 'package:inward_outward_management/screens/company/dashboard/company_dashboard.dart';
import 'package:provider/provider.dart';
import 'package:inward_outward_management/providers/nav_provider.dart';
import 'package:inward_outward_management/screens/company/supplier_request_screen.dart';
import 'package:inward_outward_management/screens/company/pending_billsscreen.dart';
import 'package:inward_outward_management/screens/company/open_challanScreen.dart';

class CompanyMainScreen extends StatefulWidget {
  CompanyMainScreen({Key? key}) : super(key: key);

  @override
  State<CompanyMainScreen> createState() => _CompanyMainScreenState();
}

class _CompanyMainScreenState extends State<CompanyMainScreen> {
  final List<Widget> _tabs = const [
    CompanyDashboardScreen(),
    SupplierRequestScreen(),
    PendingBillsscreen(),
    OpenChallanscreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<NavProvider>(
      builder: (context, nav, _) {
        return Scaffold(
          body: IndexedStack(index: nav.index, children: _tabs),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: nav.index,
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            onTap: (v) => nav.changeIndex(v),
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                label: "Dashboard",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_shipping_outlined),
                label: "Suppliers",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                label: "Bills",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_outlined),
                label: "Challans",
              ),
            ],
          ),
        );
      },
    );
  }
}
