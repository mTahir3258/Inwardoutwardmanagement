import 'package:flutter/material.dart';
import 'package:inward_outward_management/utils/app_colors.dart';

class CustomerProductsScreen extends StatelessWidget {
  const CustomerProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Customer Products',
        style: TextStyle(color: AppColors.textLight),
      ),
    );
  }
}
