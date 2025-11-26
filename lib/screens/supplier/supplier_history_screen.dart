import 'package:flutter/material.dart';
import 'package:inward_outward_management/utils/app_colors.dart';

class SupplierHistoryScreen extends StatelessWidget {
  const SupplierHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Supplier History',
        style: TextStyle(color: AppColors.textLight),
      ),
    );
  }
}
