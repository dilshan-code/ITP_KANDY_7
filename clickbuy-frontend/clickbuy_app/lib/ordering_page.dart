import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OrderingPage extends StatefulWidget {
  const OrderingPage({super.key});
  @override
  _OrderingPageState createState() => _OrderingPageState();
}

class _OrderingPageState extends State<OrderingPage> {
  final _auth = FirebaseAuth.instance;
  final List<Map<String, dynamic>> dummyItems = [
    {'name': 'Item 1', 'price': 1000.0},
    {'name': 'Item 2', 'price': 1500.0},
    {'name': 'Item 3', 'price': 500.0},
    {'name': 'Item 4', 'price': 2000.0},
    {'name': 'Item 5', 'price': 750.0},
  ];
  final List<Map<String, dynamic>> cart = [];
  double total = 0.0;
  String paymentMethod = 'card';
  double cashPaid = 0.0;
  double creditsUsed = 0.0;
  double currentBalance = 0.0;
  final String _backendUrl = 'http://172.19.83.83:3000';
  bool _isLoading = false;
  final TextEditingController _cashController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  Future<void> _fetchBalance() async {
    try {
      final token = await _auth.currentUser?.getIdToken();
      if (token == null) {
        print('No token available');
        return;
      }
      
      print('Fetching credit balance...');
      final response = await http.get(
        Uri.parse('$_backendUrl/credit'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Credit data: $data');
        setState(() {
          currentBalance = (data['currentBalance'] ?? 0).toDouble();
          print('Current balance set to: $currentBalance');
        });
      } else {
        print('Failed to fetch balance: ${response.body}');
      }
    } catch (e) {
      print('Error fetching balance: $e');
    }
  }

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      // Check if item already exists in cart
      final existingItemIndex = cart.indexWhere((cartItem) => cartItem['name'] == item['name']);
      
      if (existingItemIndex >= 0) {
        // Increment quantity if item exists
        cart[existingItemIndex]['quantity'] = (cart[existingItemIndex]['quantity'] ?? 1) + 1;
      } else {
        // Add new item with quantity 1
        cart.add({...item, 'quantity': 1});
      }
      
      total += item['price'];
      print('Cart updated: $cart, Total: $total');
    });
  }

  void _removeFromCart(Map<String, dynamic> item) {
    setState(() {
      if (item['quantity'] > 1) {
        item['quantity'] = item['quantity'] - 1;
      } else {
        cart.remove(item);
      }
      total -= item['price'];
    });
  }

  void _clearCart() {
    setState(() {
      cart.clear();
      total = 0.0;
      cashPaid = 0.0;
      creditsUsed = 0.0;
      _cashController.clear();
    });
  }

  Future<void> _placeOrder() async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    // Calculate required credits for cash payment
    if (paymentMethod == 'cash') {
      if (cashPaid <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter cash paid amount')),
        );
        return;
      }
      
      final needed = total - cashPaid;
      print('Total: $total, Cash paid: $cashPaid, Needed: $needed, Current balance: $currentBalance');
      
      if (needed > 0) {
        if (needed > currentBalance) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Insufficient credits. Need LKR ${needed.toStringAsFixed(2)} more'),
            ),
          );
          return;
        }
        creditsUsed = needed;
        print('Will use $creditsUsed credits');
      } else {
        creditsUsed = 0;
      }
    } else {
      // Card payment - use full amount from credits
      if (total > currentBalance) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Insufficient credits. Available: LKR ${currentBalance.toStringAsFixed(2)}'),
          ),
        );
        return;
      }
      creditsUsed = total;
      cashPaid = 0;
    }

    setState(() => _isLoading = true);
    
    try {
      final token = await _auth.currentUser?.getIdToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      print('Placing order with:');
      print('Items: $cart');
      print('Total: $total');
      print('Payment method: $paymentMethod');
      print('Cash paid: $cashPaid');
      print('Credits used: $creditsUsed');

      final response = await http.post(
        Uri.parse('$_backendUrl/order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'items': cart,
          'total': total,
          'paymentMethod': paymentMethod,
          'cashPaid': cashPaid,
          'creditsUsed': creditsUsed,
        }),
      );

      print('Order response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        _clearCart();
        await _fetchBalance(); // Refresh balance after order
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order placed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      print('Error placing order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building OrderingPage - Current balance: $currentBalance');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Now'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBalance,
            tooltip: 'Refresh balance',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Available Items Section
            const Text(
              'Available Items',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: dummyItems.length,
              itemBuilder: (context, index) {
                final item = dummyItems[index];
                return Card(
                  elevation: 3,
                  child: InkWell(
                    onTap: _isLoading ? null : () => _addToCart(item),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'LKR ${item['price'].toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'ADD',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Cart Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Cart',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (cart.isNotEmpty)
                          TextButton(
                            onPressed: _isLoading ? null : _clearCart,
                            child: const Text('Clear All'),
                          ),
                      ],
                    ),
                    const Divider(),
                    
                    if (cart.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text('Cart is empty'),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cart.length,
                        itemBuilder: (context, index) {
                          final item = cart[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                '${item['quantity']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(item['name']),
                            subtitle: Text('LKR ${item['price'].toStringAsFixed(2)} each'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  onPressed: _isLoading ? null : () => _removeFromCart(item),
                                  iconSize: 20,
                                ),
                                Text(
                                  'LKR ${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    
                    const Divider(),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'LKR ${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Payment Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    
                    // Available Credits Display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Available Credits:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'LKR ${currentBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: currentBalance > 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    const Text(
                      'Select Payment Method:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    
                    RadioListTile<String>(
                      title: const Text('Card (Use Credits)'),
                      value: 'card',
                      groupValue: paymentMethod,
                      onChanged: _isLoading ? null : (val) {
                        setState(() {
                          paymentMethod = val!;
                          cashPaid = 0;
                          _cashController.clear();
                        });
                      },
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.credit_card, size: 20),
                      ),
                    ),
                    
                    RadioListTile<String>(
                      title: const Text('Cash + Credits (if needed)'),
                      value: 'cash',
                      groupValue: paymentMethod,
                      onChanged: _isLoading ? null : (val) {
                        setState(() => paymentMethod = val!);
                      },
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.money, size: 20),
                      ),
                    ),
                    
                    if (paymentMethod == 'cash') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _cashController,
                        decoration: InputDecoration(
                          labelText: 'Cash Paid (LKR)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.attach_money),
                          helperText: 'Enter cash amount paid',
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !_isLoading,
                        onChanged: (val) {
                          setState(() {
                            cashPaid = double.tryParse(val) ?? 0.0;
                          });
                        },
                      ),
                      
                      if (cashPaid > 0 && total > cashPaid)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Credits to be used: LKR ${(total - cashPaid).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _placeOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Place Order',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
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
}