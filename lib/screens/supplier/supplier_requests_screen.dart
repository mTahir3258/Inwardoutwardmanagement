import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inward_outward_management/utils/app_colors.dart';
import 'package:inward_outward_management/utils/responsive.dart';
import 'package:inward_outward_management/widgets/app_scaffold.dart';
import 'package:inward_outward_management/screens/supplier/supplier_intimation_form_screen.dart';

class SupplierRequestsScreen extends StatefulWidget {
  const SupplierRequestsScreen({super.key});

  @override
  State<SupplierRequestsScreen> createState() => _SupplierRequestsScreenState();
}

class _SupplierRequestsScreenState extends State<SupplierRequestsScreen> {
  bool _loading = false;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _requests = [];
          _loading = false;
        });
        return;
      }

      final supplierEmail = user.email ?? '';

      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
        'supplier_requests',
      );

      // Link requests to supplier by login email (synthetic mobile-based email)
      if (supplierEmail.isNotEmpty) {
        query = query.where('supplierId', isEqualTo: supplierEmail);
      }

      // Keep query simple to avoid composite index requirements
      final snap = await query.get();
      _requests = snap.docs.map((d) {
        final m = Map<String, dynamic>.from(d.data());
        m['id'] = d.id;
        return m;
      }).toList();
    } catch (e) {
      // Log for debugging; UI will show "no requests" if this fails
      debugPrint('Error loading supplier requests: $e');
      _requests = [];
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return AppScaffold(
      title: 'Material Requests',
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _requests.isEmpty
            ? Center(
                child: Text(
                  'No material requests for you yet.',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: r.sp(12),
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadRequests,
                child: ListView.builder(
                  padding: EdgeInsets.all(r.wp(4)),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    return _buildRequestTile(r, req);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildRequestTile(Responsive r, Map<String, dynamic> req) {
    final id = req['id']?.toString() ?? '';
    final material = req['materialName']?.toString() ?? '-';
    final qty = req['quantity']?.toString() ?? '-';
    final unit = req['unit']?.toString() ?? '';
    final boxes = (req['boxes'] ?? req['weight'])?.toString() ?? '-';
    final weight = req['weight']?.toString() ?? '-';
    final companyId = req['companyId']?.toString() ?? '-';
    final companyName = req['companyName']?.toString() ?? '';
    final status = req['status']?.toString() ?? 'requested';

    return Card(
      color: AppColors.greyBackground,
      margin: EdgeInsets.only(bottom: r.hp(1.2)),
      child: ListTile(
        onTap: id.isEmpty
            ? null
            : () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SupplierIntimationFormScreen(
                      requestId: id,
                      materialName: material,
                      companyId: companyId,
                      baseQuantity: qty,
                      baseWeight: boxes,
                    ),
                  ),
                );
              },
        title: Text(
          material,
          style: const TextStyle(color: AppColors.textLight),
        ),
        subtitle: Text(
          unit.isNotEmpty
              ? 'Company: ${companyName.isNotEmpty ? companyName : companyId}\nQty: $qty $unit  |  Boxes: $boxes'
              : 'Company: ${companyName.isNotEmpty ? companyName : companyId}\nQty: $qty  |  Boxes: $boxes',
          style: const TextStyle(color: AppColors.textLight),
        ),
        trailing: Text(
          status,
          style: const TextStyle(
            color: AppColors.primaryGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
