import 'package:flutter/material.dart';
import 'package:inward_outward_management/utils/app_colors.dart';
import 'package:inward_outward_management/widgets/app_scaffold.dart';

class CustomerNewInvoiceScreen extends StatelessWidget {
  const CustomerNewInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'New Invoice',
      body: Center(
        child: Text(
          'Create New Invoice',
          style: TextStyle(color: AppColors.textLight),
        ),
      ),
    );
  }
}
