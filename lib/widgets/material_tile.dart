// import 'package:flutter/material.dart';
// import 'package:inward_outward_management/core/models/material_model.dart';

// class MaterialTile extends StatelessWidget {
//   final MaterialModel material;
//   final VoidCallback? onEdit;
//   final VoidCallback? onDelete;

//   const MaterialTile({
//     required this.material,
//     this.onEdit,
//     this.onDelete,
//     Key? key,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       title: Text(material.name),
//       subtitle: Text(
//         'Unit: ${material.unit} • Plastic: ${material.plasticQty}',
//       ),
//       trailing: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           IconButton(icon: Icon(Icons.edit), onPressed: onEdit),
//           IconButton(icon: Icon(Icons.delete), onPressed: onDelete),
//         ],
//       ),
//     );
//   }
// }
