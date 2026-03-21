import 'package:flutter/material.dart';

class PurchaseTableScreen extends StatelessWidget {
  const PurchaseTableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Purchases"),
        backgroundColor: const Color.fromARGB(255, 53, 235, 37),
      ),
      body: const Center(child: Text("Purchase Table Here")),
    );
  }
}
