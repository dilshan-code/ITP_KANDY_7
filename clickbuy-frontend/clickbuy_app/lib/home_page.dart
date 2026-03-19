import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'credit_management_page.dart';
import 'ordering_page.dart';
import 'order_history_page.dart';
import 'admin_dashboard_page.dart';
import 'login_page.dart';
import 'dart:ui';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = FirebaseAuth.instance;
  final String _backendUrl = 'http://172.19.83.83:3000';
  String _role = 'customer';
  int _selectedIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    setState(() => _isLoading = true);
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final token = await user.getIdToken();
        final response = await http.get(
          Uri.parse('$_backendUrl/user/role'),
          headers: {'Authorization': 'Bearer $token'},
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() => _role = data['role'] ?? 'customer');
        }
      } catch (e) {
        print('Error checking role: $e');
        // Fallback to email-based role detection
        if (user.email == 'admin@example.com') {
          setState(() => _role = 'admin');
        }
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => const LoginPage())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_role == 'admin') {
      return const AdminDashboardPage();
    }

    final pages = [
      const OrderingPage(),
      const OrderHistoryPage(),
      const CreditManagementPage(),
    ];

    return Scaffold(
  extendBody: true, // Allows body to flow behind the navbar
  appBar: AppBar(
    title: const Text('ClickBuy', style: TextStyle(fontWeight: FontWeight.bold)),
    actions: [
      IconButton(
        onPressed: _signOut,
        icon: const Icon(Icons.logout_rounded),
      ),
    ],
  ),
  body: Stack(
    children: [
      pages[_selectedIndex],
      
      // Floating Glassy Nav Bar
      Positioned(
        left: 20,
        right: 20,
        bottom: 30,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  indicatorColor: const Color(0xFF2E7D32).withOpacity(0.2),
                  labelTextStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)
                  ),
                ),
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.shopping_cart_outlined),
                      selectedIcon: Icon(Icons.shopping_cart, color: Color(0xFF2E7D32)),
                      label: 'Order',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.history_outlined),
                      selectedIcon: Icon(Icons.history, color: Color(0xFF2E7D32)),
                      label: 'History',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.credit_card_outlined),
                      selectedIcon: Icon(Icons.credit_card, color: Color(0xFF2E7D32)),
                      label: 'Credits',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  ),
);
  }
}