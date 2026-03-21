import 'package:flutter/material.dart';

import '../../models/purchase.dart';

class PaymentsTableScreen extends StatefulWidget {
  final List<Purchase> purchases;
  final Function(int) onStatusChange;
  final Function(int, String) onBillUpload;

  const PaymentsTableScreen({
    super.key,
    required this.purchases,
    required this.onStatusChange,
    required this.onBillUpload,
  });

  @override
  State<PaymentsTableScreen> createState() => _PaymentsTableScreenState();
}

class _PaymentsTableScreenState extends State<PaymentsTableScreen> {
  Future<void> pickFile(int index) async {
    String? fileName = await showDialog<String>(
      context: context,
      builder: (context) {
        TextEditingController controller = TextEditingController();

        return AlertDialog(
          title: const Text("Upload Bill"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Enter bill file name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
              child: const Text("Upload"),
            ),
          ],
        );
      },
    );

    if (fileName != null && fileName.isNotEmpty) {
      widget.onBillUpload(index, fileName);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payments"),
        backgroundColor: const Color.fromARGB(255, 75, 215, 29),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text("ID")),
            DataColumn(label: Text("Name")),
            DataColumn(label: Text("Date")),
            DataColumn(label: Text("Qty")),
            DataColumn(label: Text("Amount")),
            DataColumn(label: Text("Status")),
            DataColumn(label: Text("Bill")),
          ],
          rows: widget.purchases.asMap().entries.map((entry) {
            int index = entry.key;
            Purchase p = entry.value;

            return DataRow(
              cells: [
                DataCell(Text(p.supplierId)),
                DataCell(Text(p.supplierName)),
                DataCell(Text(p.date.split(" ")[0])),
                DataCell(Text(p.quantity.toString())),
                DataCell(Text(p.total.toString())),
                DataCell(
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.status == "Paid"
                          ? Colors.green
                          : const Color.fromARGB(255, 77, 255, 0),
                    ),
                    onPressed: () {
                      widget.onStatusChange(index);
                      setState(() {});
                    },
                    child: Text(p.status),
                  ),
                ),
                DataCell(
                  ElevatedButton(
                    onPressed: () => pickFile(index),
                    child: Text(p.billPath ?? "Upload"),
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
