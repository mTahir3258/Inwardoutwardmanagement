import 'package:flutter/material.dart';
import 'package:inward_outward_management/utils/app_colors.dart';

class SupplierSettingsScreen extends StatelessWidget {
  const SupplierSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Supplier Settings',
        style: TextStyle(color: AppColors.textLight),
      ),
    );
  }
}
