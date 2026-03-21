import 'package:flutter/material.dart';
import '../../models/supplier.dart';
import 'add_supplier_screen.dart';
import 'supplier_details_screen.dart';

class SupplierManagementScreen extends StatefulWidget {
  const SupplierManagementScreen({super.key});

  @override
  State<SupplierManagementScreen> createState() =>
      _SupplierManagementScreenState();
}

class _SupplierManagementScreenState extends State<SupplierManagementScreen> {
  List<Supplier> suppliers = [];

  void addSupplier(Supplier supplier) {
    setState(() {
      suppliers.add(supplier);
    });
  }

  void updateSupplier(int index, Supplier updated) {
    setState(() {
      suppliers[index] = updated;
    });
  }

  void deleteSupplier(int index) {
    setState(() {
      suppliers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Suppliers"),
        backgroundColor: const Color.fromARGB(255, 37, 235, 47),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddSupplierScreen(onAdd: addSupplier),
                  ),
                );
              },
              child: const Text("Add Supplier"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SupplierDetailsScreen(
                      suppliers: suppliers,
                      onDelete: deleteSupplier,
                      onUpdate: updateSupplier,
                    ),
                  ),
                );
              },
              child: const Text("View Suppliers"),
            ),
          ],
        ),
      ),
    );
  }
}
