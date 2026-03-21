import 'package:flutter/material.dart';
import '../../models/purchase.dart';
import '../purchase/new_purchase_screen.dart';
import '../payments/payments_table_screen.dart';
import '../supplier/supplier_management_screen.dart';
import '../../widgets/dashboard/dashboard_tile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Purchase> purchases = [];

  void addPurchase(Purchase purchase) {
    setState(() {
      purchases.add(purchase);
    });
  }

  void updateStatus(int index) {
    setState(() {
      purchases[index].status = purchases[index].status == "Pending"
          ? "Paid"
          : "Pending";
    });
  }

  void updateBill(int index, String path) {
    setState(() {
      purchases[index].billPath = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Supplier Dashboard"),
        backgroundColor: const Color.fromARGB(255, 6, 197, 64),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            DashboardTile(
              title: "Suppliers",
              icon: Icons.people,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SupplierManagementScreen(),
                  ),
                );
              },
            ),
            DashboardTile(
              title: "New Purchase",
              icon: Icons.shopping_cart,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewPurchaseScreen(onSave: addPurchase),
                  ),
                );
              },
            ),
            DashboardTile(
              title: "Payments",
              icon: Icons.payment,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentsTableScreen(
                      purchases: purchases,
                      onStatusChange: updateStatus,
                      onBillUpload: updateBill,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
