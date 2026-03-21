import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/api_service.dart';
import 'invoice_preview_screen.dart';

class CreateSaleScreen extends StatefulWidget {
  const CreateSaleScreen({super.key});

  @override
  State<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends State<CreateSaleScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();

  bool _isCreditSale = false;
  bool _isSaving = false;
  bool _isLoadingProducts = true;
  String? _loadError;

  // Products list — Firebase ගෙන් dynamically load කරනවා (hardcode නෑ)
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  // Backend API ගෙන් products load කරනවා
  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _loadError = null;
    });
    try {
      final products = await ApiService.getProducts();
      // qty field add කරනවා UI tracking සඳහා
      final withQty = products.map((p) => {...p, 'qty': 0}).toList();
      setState(() {
        _products = withQty;
        _filteredProducts = withQty;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString();
        _isLoadingProducts = false;
      });
    }
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products
          .where(
            (p) =>
                (p['name'] as String).toLowerCase().contains(query) ||
                (p['category'] as String? ?? '').toLowerCase().contains(query),
          )
          .toList();
    });
  }

  // Selected products (qty > 0)
  List<Map<String, dynamic>> get selectedProducts =>
      _products.where((p) => p['qty'] > 0).toList();

  // Products not yet added (qty == 0), filtered
  List<Map<String, dynamic>> get availableProducts =>
      _filteredProducts.where((p) => p['qty'] == 0).toList();

  double get subtotal => selectedProducts.fold(
    0,
    (sum, p) => sum + (p['sellingPrice'] * p['qty']),
  );
  double get tax => subtotal * 0.08;
  double get total => subtotal + tax;

  // Backend API හරහා sale save කරනවා
  Future<void> _saveSale(String status) async {
    if (selectedProducts.isEmpty) {
      _showSnack('⚠️ Please add at least one product!', Colors.orange);
      return;
    }
    if (status == 'Credit' && _customerController.text.trim().isEmpty) {
      _showSnack(
        '⚠️ Please enter customer name for credit sale!',
        Colors.orange,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final customerName = _customerController.text.trim().isEmpty
          ? 'Walk-in Customer'
          : _customerController.text.trim();

      // Build items list with productId for stock deduction in backend
      final items = selectedProducts
          .map(
            (p) => {
              'productId': p['id'] ?? '',
              'productName': p['name'],
              'quantity': p['qty'],
              'unitPrice': p['sellingPrice'],
              'subTotal': p['sellingPrice'] * p['qty'],
            },
          )
          .toList();

      // Backend API call — handles stock deduction + credit customer update
      await ApiService.createSale(
        customerName: customerName,
        isCredit: status == 'Credit',
        status: status,
        subtotal: subtotal,
        tax: tax,
        totalAmount: total,
        items: items,
      );

      _showSnack(
        status == 'Completed'
            ? '✅ Sale saved successfully!'
            : '📋 Added to credit! Customer record updated.',
        status == 'Completed'
            ? const Color(0xFF2ECC71)
            : const Color(0xFFF39C12),
      );

      _resetSale();
    } catch (e) {
      _showSnack('❌ Error: $e', Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _resetSale() {
    setState(() {
      for (var p in _products) p['qty'] = 0;
      _customerController.clear();
      _isCreditSale = false;
    });
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'New Sale',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
            fontSize: 18,
          ),
        ),
        actions: [
          if (selectedProducts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _resetSale,
              tooltip: 'Clear Sale',
            ),
        ],
      ),
      body: _isLoadingProducts
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF029934)),
            )
          : _loadError != null
          ? _buildErrorState()
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      if (selectedProducts.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Current Sale',
                          '${selectedProducts.length} Items',
                        ),
                        const SizedBox(height: 10),
                        ...selectedProducts.map(_buildSelectedCard),
                        const SizedBox(height: 16),
                      ],
                      _buildSectionLabel('All Products'),
                      const SizedBox(height: 10),
                      if (availableProducts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No products found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...availableProducts.map(_buildProductRow),
                      const SizedBox(height: 16),
                      if (selectedProducts.isNotEmpty) _buildOrderSummary(),
                    ],
                  ),
                ),
                if (selectedProducts.isNotEmpty) _buildBottomButtons(),
              ],
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(
            'Failed to load products.\nMake sure the backend server is running.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadProducts,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF029934),
            ),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search products or category...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                _onSearch();
              },
              child: const Icon(Icons.close, color: Colors.grey, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String badge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEEEB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              color: Color(0xFF029934),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 13,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSelectedCard(Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFF029934),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'LKR ${(product['sellingPrice'] as num).toStringAsFixed(2)} · Stock: ${product['stockQuantity']}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  product['qty'] = product['qty'] > 1 ? product['qty'] - 1 : 0;
                }),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.remove, size: 16, color: Colors.grey),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '${product['qty']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  final stock = product['stockQuantity'] as int? ?? 0;
                  if (product['qty'] >= stock) {
                    _showSnack(
                      '⚠️ Not enough stock! (${stock} available)',
                      Colors.orange,
                    );
                    return;
                  }
                  setState(() => product['qty']++);
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF029934),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> product) {
    final stock = product['stockQuantity'] as int? ?? 0;
    final isOutOfStock = stock == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Stock: $stock ${product['unit'] ?? ''}',
                  style: TextStyle(
                    color: stock <= (product['minimumStockLevel'] ?? 5)
                        ? Colors.red
                        : Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'LKR ${(product['sellingPrice'] as num).toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF029934),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isOutOfStock
                ? () => _showSnack('⚠️ Out of stock!', Colors.red)
                : () => setState(() => product['qty'] = 1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isOutOfStock
                    ? Colors.grey.shade200
                    : const Color(0xFFFFEEEB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isOutOfStock ? 'Out' : '+ Add',
                style: TextStyle(
                  color: isOutOfStock ? Colors.grey : const Color(0xFF029934),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', subtotal),
          const SizedBox(height: 6),
          _summaryRow('Tax (8%)', tax),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              Text(
                'LKR ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xFF029934),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              const Icon(Icons.person_outline, color: Colors.grey, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _customerController,
                  decoration: const InputDecoration(
                    hintText: 'Customer Name (Optional)',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              const Text(
                'Credit',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 6),
              Switch(
                value: _isCreditSale,
                onChanged: (val) => setState(() => _isCreditSale = val),
                activeColor: const Color(0xFF029934),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(
          'LKR ${amount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          if (_isCreditSale)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF39C12)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFF39C12), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '📋 Credit data will be saved to Customer Credit Management module',
                      style: TextStyle(color: Color(0xFFF39C12), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : () => _saveSale('Completed'),
                  icon: const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Color(0xFF029934),
                  ),
                  label: const Text(
                    'Mark Paid',
                    style: TextStyle(
                      color: Color(0xFF029934),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF029934)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : () => _saveSale('Credit'),
                  icon: const Icon(
                    Icons.person_add,
                    size: 16,
                    color: Color(0xFF029934),
                  ),
                  label: const Text(
                    'Add to Credit',
                    style: TextStyle(
                      color: Color(0xFF029934),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF029934)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InvoicePreviewScreen(
                            selectedProducts: selectedProducts,
                            total: total,
                            subtotal: subtotal,
                            tax: tax,
                            customerName: _customerController.text.trim(),
                            isCredit: _isCreditSale,
                          ),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF029934),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Complete Checkout',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
