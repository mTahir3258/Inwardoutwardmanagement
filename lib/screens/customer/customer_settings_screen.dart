import 'package:flutter/material.dart';
import 'package:inward_outward_management/utils/app_colors.dart';

class CustomerSettingsScreen extends StatelessWidget {
  const CustomerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Customer Settings',
        style: TextStyle(color: AppColors.textLight),
      ),
    );
  }
}
