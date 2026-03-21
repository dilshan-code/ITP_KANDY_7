import 'package:flutter/material.dart';
import '../../models/purchase.dart';

class NewPurchaseScreen extends StatefulWidget {
  final Function(Purchase) onSave;

  const NewPurchaseScreen({super.key, required this.onSave});

  @override
  State<NewPurchaseScreen> createState() => _NewPurchaseScreenState();
}

class _NewPurchaseScreenState extends State<NewPurchaseScreen> {
  final supplierIdController = TextEditingController();
  final supplierNameController = TextEditingController();
  final phoneController = TextEditingController();
  final quantityController = TextEditingController();
  final priceController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  double total = 0;

  void calculateTotal() {
    final qty = int.tryParse(quantityController.text) ?? 0;
    final price = double.tryParse(priceController.text) ?? 0;

    setState(() {
      total = qty * price;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Purchase"),
        backgroundColor: const Color.fromARGB(255, 70, 235, 37),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: supplierIdController,
              decoration: const InputDecoration(labelText: "Supplier ID"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: supplierNameController,
              decoration: const InputDecoration(labelText: "Supplier Name"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: "Quantity"),
              onChanged: (_) => calculateTotal(),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: "Unit Price"),
              onChanged: (_) => calculateTotal(),
            ),
            const SizedBox(height: 20),
            Text(
              "Total: $total",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 37, 235, 67),
                    ),
                    onPressed: () {
                      final purchase = Purchase(
                        supplierId: supplierIdController.text,
                        supplierName: supplierNameController.text,
                        phone: phoneController.text,
                        date: selectedDate.toString(),
                        quantity: int.parse(quantityController.text),
                        unitPrice: double.parse(priceController.text),
                        total: total,
                      );

                      widget.onSave(purchase);
                      Navigator.pop(context);
                    },
                    child: const Text("Save"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
