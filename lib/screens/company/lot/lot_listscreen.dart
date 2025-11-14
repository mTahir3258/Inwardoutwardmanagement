import 'package:flutter/material.dart';
import 'package:inward_outward_management/providers/lot_provider.dart';
import 'package:inward_outward_management/screens/company/lot/add_edit_lotscreen.dart';
import 'package:provider/provider.dart';
import '../../../../../utils/responsive.dart';

class LotListScreen extends StatefulWidget {
  const LotListScreen({super.key});

  @override
  State<LotListScreen> createState() => _LotListScreenState();
}

class _LotListScreenState extends State<LotListScreen> {
  @override
  void initState() {
    super.initState();

    // Load lots
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LotProvider>(context, listen: false).loadLots();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<LotProvider>(context);
    final r = Responsive(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lot Master"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddEditLotScreen()),
          );
        },
      ),

      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(r.wp(4)),
              itemCount: prov.lots.length,
              itemBuilder: (context, i) {
                final lot = prov.lots[i];

                return Container(
                  margin: EdgeInsets.only(bottom: r.hp(1.5)),
                  padding: EdgeInsets.all(r.wp(3)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: ListTile(
                    title: Text(
                      "Lot: ${lot['lotName']}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: r.sp(12),
                      ),
                    ),
                    subtitle: Text(
                      "Material: ${lot['materialName']}\n"
                      "Boxes: ${lot['boxCount']}  |  Weight: ${lot['weight']} kg",
                    ),

                    trailing: PopupMenuButton(
                      onSelected: (value) {
                        if (value == "edit") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditLotScreen(existing: lot),
                            ),
                          );
                        } else {
                          prov.deleteLot(lot['lotId']);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: "edit", child: Text("Edit")),
                        const PopupMenuItem(
                          value: "delete",
                          child: Text("Delete"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
