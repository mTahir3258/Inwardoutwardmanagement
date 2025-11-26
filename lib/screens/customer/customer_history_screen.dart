import 'package:flutter/material.dart';
import 'package:inward_outward_management/utils/app_colors.dart';

class CustomerHistoryScreen extends StatelessWidget {
  const CustomerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text(
          'Customer Billing History',
          style: TextStyle(color: AppColors.textLight),
        ),
      ),
    );
  }
}
