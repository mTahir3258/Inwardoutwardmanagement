// lib/screens/role_router.dart
import 'package:flutter/material.dart';
import 'package:inward_outward_management/screens/company/dashboard/company_dashboard.dart';
import 'package:inward_outward_management/screens/company/mainwrapper/company_main_screen.dart';
import 'package:inward_outward_management/screens/customer/customer_dashboard.dart';
import 'package:inward_outward_management/screens/supplier/supplier_dashboard.dart';
import 'package:provider/provider.dart';
import 'package:inward_outward_management/providers/auth_provider.dart';
import 'package:inward_outward_management/screens/auth/login_screen.dart';

class RoleRouterScreen extends StatelessWidget {
  const RoleRouterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return FutureBuilder<String?>(
      future: auth.fetchUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data;
        print("Fetched user role: $role");

        if (role == null) {
          // If no role found, go to login
          return const LoginScreen();
        }

        switch (role.toLowerCase()) {
          case 'company':
            return CompanyMainScreen();
          case 'supplier':
            return const SupplierDashboardScreen();
          case 'customer':
            return const CustomerDashboardScreen();
          default:
            return const LoginScreen();
        }
      },
    );
  }
}
