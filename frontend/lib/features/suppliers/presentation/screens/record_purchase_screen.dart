import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/utils/snackbar_utils.dart';
import 'package:frontend/features/suppliers/presentation/providers/purchase_provider.dart';
import 'package:frontend/features/suppliers/presentation/providers/supplier_provider.dart';
import 'package:frontend/features/products/presentation/providers/product_provider.dart';
import 'package:frontend/features/products/domain/entities/product.dart';
import 'package:frontend/shared/main_shell.dart';

class RecordPurchaseScreen extends StatefulWidget {
  const RecordPurchaseScreen({super.key});

  @override
  State<RecordPurchaseScreen> createState() => _RecordPurchaseScreenState();
}

class _RecordPurchaseScreenState extends State<RecordPurchaseScreen> {
  final _invoiceController = TextEditingController();
  final _subtotalController = TextEditingController();
  final _taxController = TextEditingController();
  final _amountPaidController = TextEditingController();
  String? _selectedSupplierId;
  String _selectedSupplierName = '';
  final List<Map<String, dynamic>> _purchasedItems = [];
  bool _isSubmitting = false;
  bool _showSupplierError = false;
  bool _showProductError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SupplierProvider>().fetchSuppliers();
        context.read<ProductProvider>().fetchProducts();
      }
    });
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _subtotalController.dispose();
    _taxController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return _purchasedItems.fold(0.0, (sum, item) {
      final price = item['costPrice'] ?? 0.0;
      final qty = item['quantity'] ?? 0;
      return sum + (price * qty);
    });
  }

  double get _tax => double.tryParse(_taxController.text) ?? 0;
  double get _totalAmount => _subtotal + _tax;
  double get _amountPaid => double.tryParse(_amountPaidController.text) ?? 0;
  double get _remaining => _totalAmount - _amountPaid;

  void _addItem(Product product) {
    setState(() {
      _purchasedItems.add({
        'productId': product.id,
        'name': product.name,
        'quantity': 1,
        'unit': product.unit,
        'costPrice': product.sellingPrice, // Default to product's selling price if cost not known
      });
      _showProductError = false;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _purchasedItems.removeAt(index);
    });
  }

  void _updateItem(int index, {int? quantity, double? costPrice}) {
    setState(() {
      if (quantity != null) _purchasedItems[index]['quantity'] = quantity;
      if (costPrice != null) _purchasedItems[index]['costPrice'] = costPrice;
    });
  }

  void _submit() async {
    setState(() {
      _showSupplierError = _selectedSupplierId == null;
      _showProductError = _purchasedItems.isEmpty;
    });

    if (_showSupplierError) {
      SnackBarUtils.showSnackBar(
        context,
        'Please select a supplier',
        isError: true,
      );
      return;
    }
    if (_showProductError) {
      SnackBarUtils.showSnackBar(
        context,
        'Please add at least one product',
        isError: true,
      );
      return;
    }
    setState(() => _isSubmitting = true);
    final provider = Provider.of<PurchaseProvider>(context, listen: false);
    final success = await provider.addPurchase({
      'supplierId': _selectedSupplierId,
      'supplierName': _selectedSupplierName,
      'invoiceNumber': _invoiceController.text.trim(),
      'items': _purchasedItems,
      'subtotal': _subtotal,
      'tax': _tax,
      'totalAmount': _totalAmount,
      'amountPaid': _amountPaid,
    });
    if (success && mounted) {
      final productProvider = context.read<ProductProvider>();
      
      // Reset state BEFORE fetching new data to avoid dropdown assertion errors
      setState(() {
        _isSubmitting = false;
        _selectedSupplierId = null;
        _purchasedItems.clear();
        _invoiceController.clear();
        _taxController.clear();
        _amountPaidController.clear();
      });

      // Refresh products to show updated stock
      await productProvider.fetchProducts();

      // Refresh dashboard statistics on Home Screen
      MainShell.homeKey.currentState?.refresh();
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Purchase')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Supplier selection
              _buildLabel('Select Supplier *'),
              const SizedBox(height: 8),
              Consumer<SupplierProvider>(
                builder: (context, supplierProvider, _) {
                  if (supplierProvider.isLoading &&
                      supplierProvider.suppliers.isEmpty) {
                    return _buildLoadingDropdown('Loading Suppliers...');
                  }
                  return Container(
                    decoration: _containerDecoration(
                      Icons.local_shipping_outlined,
                      borderColor: _showSupplierError
                          ? AppColors.error
                          : Colors.grey.shade300,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        key: ValueKey(
                            'supplier_id_dropdown_${supplierProvider.isLoading}_${_selectedSupplierId == null}'),
                        isExpanded: true,
                        value: _selectedSupplierId,
                        hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Choose a supplier'),
                        ),
                        items: supplierProvider.suppliers
                            .map((s) => s.id)
                            .toSet()
                            .map((id) {
                          final s = supplierProvider.suppliers
                              .firstWhere((sup) => sup.id == id);
                          return DropdownMenuItem(
                            value: id,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(s.name),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedSupplierId = value;
                            final supplier =
                                supplierProvider.suppliers.firstWhere(
                              (s) => s.id == value,
                            );
                            _selectedSupplierName = supplier.name;
                            _showSupplierError = false;
                          });
                        },
                        icon: const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.arrow_drop_down,
                              color: AppColors.primary),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Product Selection
              _buildLabel('Add Products to Stock *'),
              const SizedBox(height: 8),
              _buildProductSelector(),
              const SizedBox(height: 16),

              if (_purchasedItems.isNotEmpty) ...[
                const Text(
                  'Purchased Items',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _purchasedItems.length,
                  itemBuilder: (context, index) {
                    final item = _purchasedItems[index];
                    return _buildPurchasedItemCard(index, item);
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Invoice number
              _buildLabel('Invoice Number (Optional)'),
              const SizedBox(height: 4),
              const Text(
                'Leave empty to auto-generate',
                style: TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _invoiceController,
                decoration: const InputDecoration(
                  hintText: 'e.g. INV-0001',
                  prefixIcon: Icon(
                    Icons.receipt_outlined,
                    color: AppColors.textLight,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Amounts
              _buildLabel('Subtotal'),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Rs ',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _subtotal.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildLabel('Tax Amount'),
              const SizedBox(height: 8),
              TextField(
                controller: _taxController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.percent, color: AppColors.textLight),
                ),
              ),
              const SizedBox(height: 20),

              _buildLabel('Amount Paid'),
              const SizedBox(height: 8),
              TextField(
                controller: _amountPaidController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: '0.00',
                  prefixIcon: Icon(
                    Icons.payments_outlined,
                    color: AppColors.textLight,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      'Subtotal',
                      'Rs ${_subtotal.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Tax', 'Rs ${_tax.toStringAsFixed(2)}'),
                    const Divider(height: 20),
                    _buildSummaryRow(
                      'Total Amount',
                      'Rs ${_totalAmount.toStringAsFixed(2)}',
                      isBold: true,
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Amount Paid',
                      'Rs ${_amountPaid.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Remaining',
                      'Rs ${_remaining.toStringAsFixed(2)}',
                      isBold: true,
                      valueColor:
                          _remaining > 0 ? AppColors.error : AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Record Purchase',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: AppColors.textMedium),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: valueColor ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildProductSelector() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        if (productProvider.isLoading) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Row(
              children: [
                Icon(Icons.sync, color: AppColors.textLight, size: 20),
                SizedBox(width: 12),
                Text('Loading products...', style: TextStyle(color: AppColors.textLight)),
              ],
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _showProductError ? AppColors.error : Colors.grey.shade300,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              key: ValueKey('product_selector_${productProvider.isLoading}'),
              isExpanded: true,
              value: null, // Reset after each selection
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Select product to add'),
              ),
              icon: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.add_circle_outline, color: AppColors.primary),
              ),
              items: productProvider.products
                  .map((p) => p.id)
                  .toSet()
                  .map((id) {
                final p = productProvider.products.firstWhere((prod) => prod.id == id);
                return DropdownMenuItem(
                  value: id,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(p.name),
                  ),
                );
              }).toList(),
              onChanged: (productId) {
                if (productId != null) {
                  final product = productProvider.products.firstWhere((p) => p.id == productId);
                  _addItem(product);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPurchasedItemCard(int index, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item['name'],
                  style:
                      const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: AppColors.error, size: 20),
                onPressed: () => _removeItem(index),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Qty (${item['unit'] ?? ''})',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMedium)),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: item['quantity'].toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (val) =>
                          _updateItem(index, quantity: int.tryParse(val) ?? 0),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cost Price',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMedium)),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: item['costPrice'].toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => _updateItem(index,
                          costPrice: double.tryParse(val) ?? 0.0),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixText: 'Rs ',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textMedium)),
                  const SizedBox(height: 8),
                  Text(
                    'Rs ${(item['quantity'] * item['costPrice']).toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _containerDecoration(IconData icon, {Color? borderColor}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor ?? Colors.grey.shade300),
    );
  }

  Widget _buildLoadingDropdown(String hint) {
    return Container(
      decoration: _containerDecoration(Icons.sync),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          items: const [],
          onChanged: null,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(hint),
              ],
            ),
          ),
          icon: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.arrow_drop_down, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
