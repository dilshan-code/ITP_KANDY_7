import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _auth = FirebaseAuth.instance;
  Map<String, dynamic> allUsers = {};
  final String _backendUrl = 'http://172.19.83.83:3000';
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAllUsers();
  }

  Future<void> _fetchAllUsers() async {
    setState(() => _isLoading = true);
    try {
      final token = await _auth.currentUser?.getIdToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$_backendUrl/admin/users'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        setState(() => allUsers = jsonDecode(response.body));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> get _filteredUsers {
    if (_searchQuery.isEmpty) return allUsers;
    return Map.fromEntries(
      allUsers.entries.where(
        (entry) => entry.key.toLowerCase().contains(_searchQuery.toLowerCase()),
      ),
    );
  }

  int get _totalUsers => allUsers.length;
  int get _totalAdmins {
    return allUsers.values.where((user) => user['role'] == 'admin').length;
  }
  double get _totalCreditBalance {
    double total = 0;
    allUsers.forEach((key, value) {
      final credit = value['creditDetails'];
      if (credit != null) {
        total += (credit['currentBalance'] ?? 0).toDouble();
      }
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAllUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats Cards
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Users',
                          _totalUsers.toString(),
                          Colors.blue,
                          Icons.people,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Admins',
                          _totalAdmins.toString(),
                          Colors.orange,
                          Icons.admin_panel_settings,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Credit Balance',
                          'LKR ${_totalCreditBalance.toStringAsFixed(2)}',
                          Colors.green,
                          Icons.credit_card,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by User ID...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Users List
                Expanded(
                  child: _filteredUsers.isEmpty
                      ? const Center(
                          child: Text('No users found'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final entry = _filteredUsers.entries.elementAt(index);
                            final uid = entry.key;
                            final user = entry.value;
                            final credit = user['creditDetails'] ?? {};
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: user['role'] == 'admin' 
                                      ? Colors.orange 
                                      : Colors.blue,
                                  child: Text(
                                    (index + 1).toString(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  'User: ${uid.substring(0, 8)}...',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('Role: ${user['role'] ?? 'customer'}'),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        _buildDetailRow('Credit Limit:', 
                                            'LKR ${(credit['creditLimit'] ?? 0).toStringAsFixed(2)}'),
                                        _buildDetailRow('Current Balance:', 
                                            'LKR ${(credit['currentBalance'] ?? 0).toStringAsFixed(2)}'),
                                        _buildDetailRow('Unpaid Balance:', 
                                            'LKR ${(credit['unpaidBalance'] ?? 0).toStringAsFixed(2)}'),
                                        
                                        if (credit['paymentHistory'] != null &&
                                            (credit['paymentHistory'] as List).isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Recent Payments:',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          ...(credit['paymentHistory'] as List).take(3).map((payment) =>
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                                              child: Text(
                                                '${payment['date']?.substring(0, 10)}: LKR ${payment['amount']}',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            )
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}