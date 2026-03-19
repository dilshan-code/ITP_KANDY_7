import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});
  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final _auth = FirebaseAuth.instance;
  Map<String, dynamic> orders = {};
  final String _backendUrl = 'http://172.19.83.83:3000';
  bool _isLoading = true;
  String? _downloadingOrderId;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final token = await _auth.currentUser?.getIdToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$_backendUrl/orders'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        setState(() => orders = jsonDecode(response.body));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading orders: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadPDF(String orderId) async {
    setState(() => _downloadingOrderId = orderId);
    
    try {
      final token = await _auth.currentUser?.getIdToken();
      if (token == null) throw Exception('Not authenticated');

      // Request PDF from server
      final response = await http.get(
        Uri.parse('$_backendUrl/order/$orderId/pdf'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        // Get temporary directory
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/order_$orderId.pdf');
        
        // Write PDF to file
        await file.writeAsBytes(response.bodyBytes);
        
        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Order Receipt',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF generated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to generate PDF: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading PDF: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _downloadingOrderId = null);
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy hh:mm a').format(date.toLocal());
    } catch (e) {
      return dateString;
    }
  }

  String _getPaymentStatus(Map<String, dynamic> order) {
    if (order['paymentMethod'] == 'cash') {
      if (order['cashPaid'] >= order['total']) {
        return 'Paid in Full';
      } else if (order['creditsUsed'] > 0) {
        return 'Partial Credits';
      }
    } else if (order['paymentMethod'] == 'card') {
      return 'Paid by Card';
    }
    return 'Unknown';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Paid in Full':
        return Colors.green;
      case 'Paid by Card':
        return Colors.blue;
      case 'Partial Credits':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOrders,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No orders yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your orders will appear here',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final entry = orders.entries.elementAt(index);
                    final orderId = entry.key;
                    final order = entry.value;
                    final status = _getPaymentStatus(order);
                    final statusColor = _getStatusColor(status);
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      elevation: 3,
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor,
                          child: Text(
                            (index + 1).toString(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Order #${order['orderNumber'] ?? orderId.substring(0, 8).toUpperCase()}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_formatDate(order['date'] ?? '')),
                            const SizedBox(height: 4),
                            Text(
                              'Total: LKR ${order['total']?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Order Details
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildDetailRow('Order Number:', '#${order['orderNumber'] ?? orderId.substring(0, 8).toUpperCase()}'),
                                      _buildDetailRow('Date:', _formatDate(order['date'] ?? '')),
                                      _buildDetailRow('Payment Method:', (order['paymentMethod'] ?? 'N/A').toUpperCase()),
                                      if (order['cashPaid'] > 0)
                                        _buildDetailRow('Cash Paid:', 'LKR ${order['cashPaid']?.toStringAsFixed(2) ?? '0.00'}'),
                                      if (order['creditsUsed'] > 0)
                                        _buildDetailRow('Credits Used:', 'LKR ${order['creditsUsed']?.toStringAsFixed(2) ?? '0.00'}'),
                                      const Divider(),
                                      _buildDetailRow('Total Amount:', 'LKR ${order['total']?.toStringAsFixed(2) ?? '0.00'}', isBold: true),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Items List
                                const Text(
                                  'Items:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                ...(order['items'] as List? ?? []).map((item) => Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item['name']} x${item['quantity'] ?? 1}',
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Text(
                                        'LKR ${(item['price'] * (item['quantity'] ?? 1)).toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                )),
                                
                                const SizedBox(height: 16),
                                
                                // Download PDF Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _downloadingOrderId == orderId 
                                        ? null 
                                        : () => _downloadPDF(orderId),
                                    icon: _downloadingOrderId == orderId
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.picture_as_pdf),
                                    label: Text(
                                      _downloadingOrderId == orderId
                                          ? 'Generating PDF...'
                                          : 'Download Receipt PDF'
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 16 : 14,
              color: isBold ? Colors.blue.shade700 : null,
            ),
          ),
        ],
      ),
    );
  }
}