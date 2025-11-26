import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:inward_outward_management/providers/auth_provider.dart';
import 'package:inward_outward_management/utils/app_colors.dart';
import 'package:inward_outward_management/utils/responsive.dart';
import 'package:inward_outward_management/widgets/app_scaffold.dart';
import 'package:inward_outward_management/screens/supplier/supplier_requests_screen.dart';
import 'package:inward_outward_management/screens/supplier/supplier_challan_status_screen.dart';
import 'package:inward_outward_management/screens/supplier/submit_without_request_screen.dart';
import 'package:inward_outward_management/screens/supplier/supplier_history_screen.dart';
import 'package:inward_outward_management/screens/supplier/supplier_settings_screen.dart';
import 'package:provider/provider.dart';

class SupplierDashboardScreen extends StatefulWidget {
  const SupplierDashboardScreen({super.key});

  @override
  State<SupplierDashboardScreen> createState() =>
      _SupplierDashboardScreenState();
}

class _SupplierDashboardScreenState extends State<SupplierDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final r = Responsive(context);

    // Tabs for bottom navigation
    final List<Widget> tabs = [
      _buildDashboardContent(
        context,
        r,
        user?.email ?? 'Supplier',
      ),
      const SupplierChallanStatusScreen(),
      const SupplierHistoryScreen(),
      const SupplierSettingsScreen(),
    ];

    return AppScaffold(
      title: 'Supplier Dashboard',
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: AppColors.textLight, size: 18),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          },
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: tabs[_currentIndex],
          ),
          Container(
            color: AppColors.greyBackground,
            child: BottomNavigationBar(
              backgroundColor: AppColors.greyBackground,
              currentIndex: _currentIndex,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primaryGreen,
              unselectedItemColor: Colors.grey,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_rounded),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.local_shipping_outlined),
                  label: 'Challans',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_rounded),
                  label: 'History',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    Responsive r,
    String name,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: r.wp(4), vertical: r.hp(1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dashboard Card Container
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(r.wp(4)),
            decoration: BoxDecoration(
              color: AppColors.greyBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryGreen.withOpacity(0.15),
                      radius: 22,
                      child: const Icon(
                        Icons.person_outline,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    SizedBox(width: r.wp(2.5)),
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: r.sp(16),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textLight,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Metrics Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        icon: Icons.inventory_2_outlined,
                        color: Colors.blue.shade100,
                        value: "0",
                        label: "Outstanding Material\nRequests",
                      ),
                    ),
                    Expanded(
                      child: _buildMetricCard(
                        icon: Icons.local_shipping_outlined,
                        color: Colors.amber.shade100,
                        value: "0",
                        label: "Pending Dispatch\nIntimations",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        icon: Icons.receipt_long_outlined,
                        color: Colors.red.shade100,
                        value: "0",
                        label: "Unpaid Challans",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Access Section
          SizedBox(height: r.hp(2)),
          Text(
            'Quick Access',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: r.sp(14),
              color: AppColors.textLight,
            ),
          ),
          SizedBox(height: r.hp(1.2)),

          _buildQuickAccessCard(
            icon: Icons.description_outlined,
            title: "View Material Requests",
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SupplierRequestsScreen(),
                ),
              );
            },
          ),
          _buildQuickAccessCard(
            icon: Icons.play_circle_outline_rounded,
            title: "Submit Dispatch",
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SupplierRequestsScreen(),
                ),
              );
            },
          ),
          _buildQuickAccessCard(
            icon: Icons.receipt_outlined,
            title: "View Challan Details",
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SupplierChallanStatusScreen(),
                ),
              );
            },
          ),
          _buildQuickAccessCard(
            icon: Icons.send_outlined,
            title: "Send Material",
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SubmitWithoutRequestScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return GestureDetector(
      onTap: () {
        // Simple routing based on label text
        if (label.startsWith('Outstanding')) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SupplierRequestsScreen(),
            ),
          );
        } else if (label.startsWith('Pending Dispatch')) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SupplierRequestsScreen(),
            ),
          );
        } else if (label.startsWith('Unpaid Challans')) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SupplierChallanStatusScreen(),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyBackground),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color,
              radius: 18,
              child: Icon(icon, color: AppColors.textDark, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.greyBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyBackground),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryGreen),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
