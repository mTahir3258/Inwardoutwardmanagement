import 'package:flutter/material.dart';
import 'package:inward_outward_management/providers/lot_provider.dart';
import 'package:provider/provider.dart';
import '../../../../utils/responsive.dart';
import 'package:uuid/uuid.dart';

class AddEditLotScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const AddEditLotScreen({super.key, this.existing});

  @override
  State<AddEditLotScreen> createState() => _AddEditLotScreenState();
}

class _AddEditLotScreenState extends State<AddEditLotScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController lotName = TextEditingController();
  final TextEditingController materialName = TextEditingController();
  final TextEditingController boxCount = TextEditingController();
  final TextEditingController weight = TextEditingController();
  final TextEditingController rate = TextEditingController();

  double totalValue = 0.0;

  @override
  void initState() {
    super.initState();

    if (widget.existing != null) {
      final e = widget.existing!;

      lotName.text = e['lotName'];
      materialName.text = e['materialName'];
      boxCount.text = e['boxCount'].toString();
      weight.text = e['weight'].toString();
      rate.text = e['rate'].toString();
      totalValue = e['totalValue'];
    }

    weight.addListener(_calculate);
    rate.addListener(_calculate);
  }

  void _calculate() {
    final w = double.tryParse(weight.text) ?? 0;
    final r = double.tryParse(rate.text) ?? 0;

    setState(() => totalValue = w * r);
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<LotProvider>(context, listen: false);
    final r = Responsive(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? "Add Lot" : "Edit Lot"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Padding(
        padding: EdgeInsets.all(r.wp(5)),
        child: Form(
          key: _formKey,

          child: Column(
            children: [
              TextFormField(
                controller: lotName,
                decoration: const InputDecoration(labelText: "Lot Name"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: materialName,
                decoration: const InputDecoration(labelText: "Material"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: boxCount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Box Count"),
              ),
              TextFormField(
                controller: weight,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Weight (kg)"),
              ),
              TextFormField(
                controller: rate,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Rate (₹ per kg)"),
              ),

              SizedBox(height: r.hp(2)),
              Text(
                "Total Value: ₹$totalValue",
                style: TextStyle(
                  fontSize: r.sp(12),
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Spacer(),

              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text(widget.existing == null ? "Save" : "Update"),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  final lot = {
                    "lotId": widget.existing?['lotId'] ?? const Uuid().v4(),
                    "lotName": lotName.text.trim(),
                    "materialName": materialName.text.trim(),
                    "boxCount": int.tryParse(boxCount.text) ?? 0,
                    "weight": double.tryParse(weight.text) ?? 0,
                    "rate": double.tryParse(rate.text) ?? 0,
                    "totalValue": totalValue,
                    "createdAt": DateTime.now().millisecondsSinceEpoch,
                  };

                  await prov.saveLot(lot);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
