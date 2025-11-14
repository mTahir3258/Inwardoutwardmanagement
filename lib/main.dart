// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:inward_outward_management/providers/company_provider.dart';
import 'package:inward_outward_management/providers/customer_provider.dart';
import 'package:inward_outward_management/providers/material_request_provider.dart';
import 'package:inward_outward_management/providers/nav_provider.dart';
import 'package:inward_outward_management/screens/auth/splash_screen.dart';
import 'package:inward_outward_management/screens/company/dashboard/material_master_screen.dart';
import 'package:inward_outward_management/screens/company/mainwrapper/company_main_screen.dart';
import 'package:inward_outward_management/screens/company/material/material_request_screen.dart';
import 'package:inward_outward_management/screens/customer/customer_dashboard.dart';
import 'package:inward_outward_management/screens/home/role_router_screen.dart';
import 'package:inward_outward_management/screens/supplier/supplier_dashboard.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart'; // if you use flutterfire configure
import 'providers/splash_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SplashProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => NavProvider()),
        ChangeNotifierProvider(create: (_) => MaterialRequestProvider()),

        ChangeNotifierProxyProvider<AuthProvider, CompanyProvider>(
          create: (_) => CompanyProvider(companyId: ''),
          update: (_, auth, companyProv) {
            final cid = auth.currentCompanyId ?? '';
            companyProv ??= CompanyProvider(companyId: cid);
            if (cid.isNotEmpty) {
              companyProv.updateCompanyId(cid);
            }
            return companyProv;
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Inward-Outward Management',
            theme: ThemeData(primarySwatch: Colors.green),
            initialRoute: '/',
            routes: {
              '/': (_) => const SplashScreen(),
              '/login': (_) => const LoginScreen(),
              '/register': (_) => const RegisterScreen(),
              '/roleRouter': (_) => const RoleRouterScreen(),
              '/companyDashboard': (_) => CompanyMainScreen(),
              '/supplierDashboard': (_) => const SupplierDashboardScreen(),
              '/customerDashboard': (_) => const CustomerDashboardScreen(),
              '/materialRequest': (_) => const MaterialRequestScreen(),
              // ⚠️ Add these missing routes:
              '/materials': (_) =>
                  const MaterialMasterScreen(), // your material master screen
              '/materialRequests': (_) => const MaterialRequestScreen(), // mate
            },
          );
        },
      ),
    );
  }
}
