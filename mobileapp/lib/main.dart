import 'package:flutter/material.dart';
import 'screens/dashboard/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Store App',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 37, 235, 63),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        fontFamily: 'Poppins',
      ),
      home: const DashboardScreen(),
    );
  }
}
