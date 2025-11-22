import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:inward_outward_management/providers/customer_provider.dart';
import 'package:inward_outward_management/utils/app_colors.dart';
import 'package:inward_outward_management/utils/responsive.dart';
import 'package:inward_outward_management/widgets/app_scaffold.dart';
import 'package:inward_outward_management/widgets/primary_button.dart';
import 'package:inward_outward_management/screens/customer/customer_payment_screen.dart';
import 'package:provider/provider.dart';

class CustomerInvoicesScreen extends StatelessWidget {
  const CustomerInvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = Provider.of<CustomerProvider>(context);
    final r = Responsive(context);
    final mobile = cp.currentCustomerMobile;

    return AppScaffold(
      title: 'Invoices',
      body: SafeArea(
        child: mobile == null || mobile.isEmpty
            ? Center(
                child: Text(
                  'Customer not set.',
                  style: TextStyle(color: AppColors.textLight, fontSize: r.sp(12)),
                ),
              )
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('customers')
                    .doc(mobile)
                    .collection('invoices')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load invoices',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: r.sp(12),
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No invoices found.',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: r.sp(12),
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(r.wp(4)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invoices & Billing',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: r.sp(14),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: r.hp(1.5)),
                        ...docs.map((d) {
                          final data = d.data();
                          final id = d.id;
                          final invoiceNumber =
                              data['invoiceNumber']?.toString() ?? id;
                          final materialName =
                              data['materialName']?.toString() ?? 'Material';
                          final amountRaw = data['amount'];
                          final amount = (amountRaw is num)
                              ? amountRaw.toDouble()
                              : double.tryParse('$amountRaw') ?? 0.0;
                          final qtyRaw = data['quantity'];
                          final qty = (qtyRaw is num)
                              ? qtyRaw.toDouble()
                              : double.tryParse('$qtyRaw') ?? 0.0;
                          final availRaw = data['availableQuantity'];
                          final availableQty = (availRaw is num)
                              ? availRaw.toDouble()
                              : double.tryParse('$availRaw') ?? 0.0;
                          final remRaw = data['remainingQuantity'];
                          final remainingQty = (remRaw is num)
                              ? remRaw.toDouble()
                              : double.tryParse('$remRaw') ?? 0.0;
                          final unitName = data['unitName']?.toString() ?? '';
                          final rateRaw = data['ratePerUnit'];
                          final rate = (rateRaw is num)
                              ? rateRaw.toDouble()
                              : double.tryParse('$rateRaw') ?? 0.0;
                          final status =
                              data['status']?.toString().toLowerCase() ?? 'pending';

                          final isPaid = status == 'paid' || status == 'settled';

                          return Container(
                            margin: EdgeInsets.only(bottom: r.hp(1.2)),
                            padding: EdgeInsets.all(r.wp(3)),
                            decoration: BoxDecoration(
                              color: AppColors.greyBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        materialName,
                                        style: TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: r.sp(13),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '₹ ${amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: r.sp(12),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: r.hp(0.5)),
                                Text(
                                  '${qty.toStringAsFixed(2)} $unitName @ ₹ ${rate.toStringAsFixed(2)}/$unitName',
                                  style: TextStyle(
                                    color:
                                        AppColors.textLight.withOpacity(0.8),
                                    fontSize: r.sp(10),
                                  ),
                                ),
                                SizedBox(height: r.hp(0.3)),
                                if (availableQty > 0)
                                  Text(
                                    'Available: ${availableQty.toStringAsFixed(2)} $unitName',
                                    style: TextStyle(
                                      color:
                                          AppColors.textLight.withOpacity(0.7),
                                      fontSize: r.sp(9),
                                    ),
                                  ),
                                if (remainingQty > 0)
                                  Text(
                                    'Remaining: ${remainingQty.toStringAsFixed(2)} $unitName',
                                    style: TextStyle(
                                      color:
                                          AppColors.textLight.withOpacity(0.7),
                                      fontSize: r.sp(9),
                                    ),
                                  ),
                                SizedBox(height: r.hp(0.6)),
                                Text(
                                  'Status: ${status.toUpperCase()}',
                                  style: TextStyle(
                                    color: isPaid
                                        ? Colors.greenAccent
                                        : AppColors.errorRed,
                                    fontSize: r.sp(10),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: r.hp(1)),
                                if (!isPaid)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: PrimaryButton(
                                          label: 'Due Now',
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => CustomerPaymentScreen(
                                                  customerName:
                                                      data['customerName']
                                                              ?.toString() ??
                                                          '',
                                                  invoiceId: id,
                                                  invoiceNumber: invoiceNumber,
                                                  amount: amount,
                                                  materialName: materialName,
                                                  quantity: qty,
                                                  unitName: unitName,
                                                  ratePerUnit: rate,
                                                  lines: (data['lines'] is List)
                                                      ? List<dynamic>.from(
                                                          data['lines'] as List,
                                                        )
                                                      : null,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
