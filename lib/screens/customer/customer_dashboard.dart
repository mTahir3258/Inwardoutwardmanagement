import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:inward_outward_management/providers/auth_provider.dart';
import 'package:inward_outward_management/providers/customer_provider.dart';
import 'package:inward_outward_management/utils/app_colors.dart';
import 'package:inward_outward_management/utils/responsive.dart';
import 'package:inward_outward_management/widgets/app_scaffold.dart';
import 'package:inward_outward_management/screens/customer/customer_invoices_screen.dart';
import 'package:inward_outward_management/screens/customer/customer_new_invoice_screen.dart';
import 'package:inward_outward_management/screens/customer/customer_products_screen.dart';
import 'package:inward_outward_management/screens/customer/customer_history_screen.dart';
import 'package:inward_outward_management/screens/customer/customer_settings_screen.dart';
import 'package:provider/provider.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomerProvider>(
        context,
        listen: false,
      ).fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final r = Responsive(context);

    // Use a property that exists on the User type (e.g. displayName or email).
    final userName =
        authProvider.currentUser?.displayName ??
        authProvider.currentUser?.email ??
        'Customer';

    // Tabs for bottom navigation
    final List<Widget> tabs = [
      // Dashboard tab (existing content)
      SafeArea(
        child: Consumer<CustomerProvider>(
          builder: (context, cp, _) {
            return RefreshIndicator(
              onRefresh: () => cp.fetchDashboardStats(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: r.wp(4),
                  vertical: r.hp(1),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    final cardWidth =
                        isNarrow ? double.infinity : (constraints.maxWidth - 48) / 2;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                    radius: 22,
                                    backgroundColor:
                                        AppColors.primaryGreen.withOpacity(0.15),
                                    child: const Icon(
                                      Icons.person_outline,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                  SizedBox(width: r.wp(2.5)),
                                  Text(
                                    'Hello, $userName',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: r.sp(16),
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
                              SizedBox(height: r.hp(1.5)),
                              Wrap(
                                spacing: r.wp(2.5),
                                runSpacing: r.hp(1.5),
                                children: [
                                  SizedBox(
                                    width: cardWidth,
                                    child: _metricCard(
                                      titleTop: '${cp.invoicesDue}',
                                      subtitle: 'Invoices Due',
                                      icon: Icons.receipt_long_outlined,
                                      iconBg: Colors.blue.shade100,
                                      isLoading: cp.loading,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const CustomerInvoicesScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: _metricCard(
                                      titleTop:
                                          '₹${_formatAmount(cp.pendingPayments)}',
                                      subtitle: 'Pending Payments',
                                      icon: Icons.account_balance_wallet_outlined,
                                      iconBg: Colors.amber.shade100,
                                      isLoading: cp.loading,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const CustomerInvoicesScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: _metricCard(
                                      titleTop:
                                          '${cp.billingHistoryCount > 0 ? "View" : 0}',
                                      subtitle: 'Billing History',
                                      icon: Icons.history_rounded,
                                      iconBg: Colors.pink.shade100,
                                      isLoading: cp.loading,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const CustomerInvoicesScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: r.hp(2)),
                        Text(
                          'Quick Access',
                          style: TextStyle(
                            fontSize: r.sp(14),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textLight,
                          ),
                        ),
                        SizedBox(height: r.hp(1.2)),
                        _quickAccessItem(
                          context,
                          icon: Icons.add_circle_outline,
                          title: 'Generate New Invoice',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CustomerNewInvoiceScreen(),
                              ),
                            );
                          },
                        ),
                        _quickAccessItem(
                          context,
                          icon: Icons.history_toggle_off,
                          title: 'View Billing History',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CustomerHistoryScreen(),
                              ),
                            );
                          },
                        ),
                        _quickAccessItem(
                          context,
                          icon: Icons.receipt_long_outlined,
                          title: 'View Invoices',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CustomerInvoicesScreen(),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: r.hp(4)),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
      const CustomerProductsScreen(),
      const CustomerHistoryScreen(),
      const CustomerSettingsScreen(),
    ];

    return AppScaffold(
      title: 'Customer Dashboard',
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
          Expanded(child: tabs[_currentIndex]),
          Container(
            color: AppColors.greyBackground,
            child: BottomNavigationBar(
              backgroundColor: AppColors.greyBackground,
              currentIndex: _currentIndex,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primaryGreen,
              unselectedItemColor: Colors.grey,
              onTap: (index) {
                setState(() => _currentIndex = index);
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_rounded),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2_outlined),
                  label: 'Products',
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

  Widget _metricCard({
    required String titleTop,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required bool isLoading,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyBackground),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: iconBg,
              radius: 20,
              child:  Icon(icon, color: AppColors.textDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isLoading
                  ? const SizedBox(
                      height: 40,
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleTop,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAccessItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final r = Responsive(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.greyBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyBackground),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: r.sp(13),
                  fontWeight: FontWeight.w500,
                  color: AppColors.textLight,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double value) {
    // simple formatting; adapt to locale/intl if needed
    if (value == 0) return '0';
    // show with comma separators and two decimals
    return value
        .toStringAsFixed(2)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }
}
