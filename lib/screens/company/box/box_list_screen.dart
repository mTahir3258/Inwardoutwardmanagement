import 'package:flutter/material.dart';
import 'package:inward_outward_management/providers/box_provider.dart';
import 'package:inward_outward_management/screens/company/box/add_edit_boxscreen.dart';
import 'package:provider/provider.dart';
import '../../../../utils/responsive.dart';

class BoxListScreen extends StatefulWidget {
  const BoxListScreen({super.key});

  @override
  State<BoxListScreen> createState() => _BoxListScreenState();
}

class _BoxListScreenState extends State<BoxListScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BoxProvider>(context, listen: false).loadBoxes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<BoxProvider>(context);
    final r = Responsive(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Box Master"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditBoxScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(r.wp(4)),
              itemCount: prov.boxes.length,
              itemBuilder: (_, i) {
                final box = prov.boxes[i];

                return Container(
                  padding: EdgeInsets.all(r.wp(3)),
                  margin: EdgeInsets.only(bottom: r.hp(1.5)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: ListTile(
                    title: Text(
                      "${box['boxType']} Box",
                      style: TextStyle(
                        fontSize: r.sp(13),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Material: ${box['materialName']}\n"
                      "Weight: ${box['boxWeight']} kg + Plastic: ${box['plasticWeight']} kg\n"
                      "Total Weight: ${box['totalWeight']} kg",
                    ),

                    trailing: PopupMenuButton(
                      onSelected: (value) {
                        if (value == "edit") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditBoxScreen(existing: box),
                            ),
                          );
                        } else {
                          prov.deleteBox(box["boxId"]);
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
