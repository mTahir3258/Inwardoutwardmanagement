import 'package:flutter/material.dart';
import 'package:inward_outward_management/providers/box_provider.dart';
import 'package:provider/provider.dart';
import '../../../../utils/responsive.dart';
import 'package:uuid/uuid.dart';

class AddEditBoxScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const AddEditBoxScreen({super.key, this.existing});

  @override
  State<AddEditBoxScreen> createState() => _AddEditBoxScreenState();
}

class _AddEditBoxScreenState extends State<AddEditBoxScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController materialName = TextEditingController();
  final TextEditingController boxType = TextEditingController();
  final TextEditingController boxWeight = TextEditingController();
  final TextEditingController plasticWeight = TextEditingController();
  final TextEditingController rate = TextEditingController();

  double totalWeight = 0;
  double amount = 0;

  @override
  void initState() {
    super.initState();

    if (widget.existing != null) {
      final e = widget.existing!;
      materialName.text = e["materialName"];
      boxType.text = e["boxType"];
      boxWeight.text = e["boxWeight"].toString();
      plasticWeight.text = e["plasticWeight"].toString();
      rate.text = e["rate"].toString();
      totalWeight = e["totalWeight"];
      amount = e["amount"];
    }

    boxWeight.addListener(_calculate);
    plasticWeight.addListener(_calculate);
    rate.addListener(_calculate);
  }

  void _calculate() {
    final w = double.tryParse(boxWeight.text) ?? 0;
    final p = double.tryParse(plasticWeight.text) ?? 0;
    final r = double.tryParse(rate.text) ?? 0;

    setState(() {
      totalWeight = w + p;
      amount = totalWeight * r;
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<BoxProvider>(context, listen: false);
    final r = Responsive(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? "Add Box" : "Edit Box"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      body: Padding(
        padding: EdgeInsets.all(r.wp(5)),
        child: Form(
          key: _formKey,

          child: Column(
            children: [
              TextFormField(
                controller: materialName,
                decoration: const InputDecoration(labelText: "Material Name"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              TextFormField(
                controller: boxType,
                decoration: const InputDecoration(labelText: "Box Type"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              TextFormField(
                controller: boxWeight,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Box Weight (kg)"),
              ),

              TextFormField(
                controller: plasticWeight,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Plastic Weight (kg)",
                ),
              ),

              TextFormField(
                controller: rate,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Rate (₹ per kg)"),
              ),

              SizedBox(height: r.hp(2)),
              Text(
                "Total Weight: ${totalWeight.toStringAsFixed(2)} kg",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: r.sp(12),
                ),
              ),
              Text(
                "Total Amount: ₹${amount.toStringAsFixed(2)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: r.sp(12),
                ),
              ),

              const Spacer(),

              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  final box = {
                    "boxId": widget.existing?["boxId"] ?? const Uuid().v4(),
                    "materialName": materialName.text,
                    "boxType": boxType.text,
                    "boxWeight": double.tryParse(boxWeight.text) ?? 0,
                    "plasticWeight": double.tryParse(plasticWeight.text) ?? 0,
                    "rate": double.tryParse(rate.text) ?? 0,
                    "totalWeight": totalWeight,
                    "amount": amount,
                    "createdAt": DateTime.now().millisecondsSinceEpoch,
                  };

                  await prov.saveBox(box);
                  Navigator.pop(context);
                },
                child: Text(widget.existing == null ? "Save" : "Update"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
