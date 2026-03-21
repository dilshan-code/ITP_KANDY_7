import 'package:flutter/material.dart';
import '../../models/supplier.dart';

class SupplierDetailsScreen extends StatefulWidget {
  final List<Supplier> suppliers;
  final Function(int) onDelete;
  final Function(int, Supplier) onUpdate;

  const SupplierDetailsScreen({
    super.key,
    required this.suppliers,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<SupplierDetailsScreen> createState() => _SupplierDetailsScreenState();
}

class _SupplierDetailsScreenState extends State<SupplierDetailsScreen> {
  void showEditDialog(int index) {
    final supplier = widget.suppliers[index];

    final nameController = TextEditingController(text: supplier.name);
    final phoneController = TextEditingController(text: supplier.phone);
    final emailController = TextEditingController(text: supplier.email);
    final addressController = TextEditingController(text: supplier.address);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Update Supplier"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController),
              TextField(controller: phoneController),
              TextField(controller: emailController),
              TextField(controller: addressController),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final updated = Supplier(
                id: supplier.id,
                name: nameController.text,
                phone: phoneController.text,
                email: emailController.text,
                address: addressController.text,
              );

              widget.onUpdate(index, updated);

              setState(() {}); // 🔥 FORCE REFRESH

              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Supplier Table"),
        backgroundColor: const Color.fromARGB(255, 64, 239, 34),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text("ID")),
            DataColumn(label: Text("Name")),
            DataColumn(label: Text("Phone")),
            DataColumn(label: Text("Email")),
            DataColumn(label: Text("Address")),
            DataColumn(label: Text("Actions")),
          ],
          rows: widget.suppliers.asMap().entries.map((entry) {
            int index = entry.key;
            Supplier supplier = entry.value;

            return DataRow(
              cells: [
                DataCell(Text(supplier.id)),
                DataCell(Text(supplier.name)),
                DataCell(Text(supplier.phone)),
                DataCell(Text(supplier.email)),
                DataCell(Text(supplier.address)),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Color.fromARGB(255, 102, 255, 0),
                        ),
                        onPressed: () => showEditDialog(index),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Color.fromARGB(255, 82, 244, 54),
                        ),
                        onPressed: () {
                          widget.onDelete(index);
                          setState(() {}); // 🔥 REFRESH AFTER DELETE
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
