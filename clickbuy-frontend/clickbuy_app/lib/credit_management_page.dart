import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CreditManagementPage extends StatefulWidget {
  const CreditManagementPage({super.key});
  @override
  _CreditManagementPageState createState() => _CreditManagementPageState();
}

class _CreditManagementPageState extends State<CreditManagementPage> {
  final _auth = FirebaseAuth.instance;
  Map<String, dynamic> _creditData = {};
  final String _backendUrl = 'http://172.19.83.83:3000';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCredit();
  }

  Future<String?> _getToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated. Please login again.')),
        );
      }
      return null;
    }
    return await user.getIdToken();
  }

  Future<void> _fetchCredit() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$_backendUrl/credit'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        setState(() => _creditData = jsonDecode(response.body));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCredit,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Credit Summary',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 24),
                          _buildSummaryRow(
                            'Credit Limit:',
                            'LKR ${_creditData['creditLimit']?.toStringAsFixed(2) ?? '0.00'}',
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow(
                            'Available Balance:',
                            'LKR ${_creditData['currentBalance']?.toStringAsFixed(2) ?? '0.00'}',
                            color: Colors.green,
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow(
                            'Unpaid Balance:',
                            'LKR ${_creditData['unpaidBalance']?.toStringAsFixed(2) ?? '0.00'}',
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}