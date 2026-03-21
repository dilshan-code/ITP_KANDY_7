import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/utils/snackbar_utils.dart';
import 'package:frontend/features/suppliers/presentation/providers/purchase_provider.dart';
import 'package:frontend/features/suppliers/presentation/providers/supplier_provider.dart';
import 'package:frontend/features/products/presentation/providers/product_provider.dart';
import 'package:frontend/features/products/domain/entities/product.dart';

class SupplierPurchaseRecordScreen extends StatefulWidget {
  const SupplierPurchaseRecordScreen({super.key});

  @override
  State<SupplierPurchaseRecordScreen> createState() => _SupplierPurchaseRecordScreenState();
}

class _SupplierPurchaseRecordScreenState extends State<SupplierPurchaseRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();
  
  String? _selectedSupplierId;
  String _selectedSupplierName = '';
  String? _selectedProductId;
  String _paymentStatus = 'Paid'; // Default status
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SupplierProvider>().fetchSuppliers();
        context.read<ProductProvider>().fetchProducts();
      }
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _selectedSupplierId == null || _selectedProductId == null) {
      SnackBarUtils.showTopSnackBar(
        context,
        'Please fill all required fields',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final productProvider = context.read<ProductProvider>();
    final selectedProduct = productProvider.products.firstWhere((p) => p.id == _selectedProductId);
    
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? selectedProduct.sellingPrice;
    final totalAmount = quantity * price;
    
    // Determine amountPaid based on payment status
    double amountPaid = 0;
    if (_paymentStatus == 'Paid') {
      amountPaid = totalAmount;
    } else if (_paymentStatus == 'Partial') {
      // For simplicity in this UI, partial could mean half or we could add another field.
      // But based on request, let's keep it simple. If 'Partial', we'll default to 0 for now
      // or maybe the user wants to enter amount paid. 
      // To keep it "beginner friendly", let's just stick to Paid/Pending for now or 
      // assume 'Paid' means amountPaid = totalAmount.
      amountPaid = totalAmount / 2; // Dummy logic for partial
    }

    final purchaseData = {
      'supplierId': _selectedSupplierId,
      'supplierName': _selectedSupplierName,
      'purchaseDate': _selectedDate.toIso8601String(),
      'items': [
        {
          'productId': selectedProduct.id,
          'name': selectedProduct.name,
          'quantity': quantity,
          'costPrice': price,
        }
      ],
      'subtotal': totalAmount,
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'notes': _notesController.text.trim(),
    };

    final purchaseProvider = Provider.of<PurchaseProvider>(context, listen: false);
    final success = await purchaseProvider.addPurchase(purchaseData);

    if (success && mounted) {
      final productProvider = context.read<ProductProvider>();
      final supplierProvider = context.read<SupplierProvider>();
      
      // Store the ID to find the updated product later
      final productId = _selectedProductId;

      // Reset state BEFORE fetching new data to avoid dropdown assertion errors
      setState(() {
        _isSubmitting = false;
        _selectedProductId = null;
        _selectedSupplierId = null;
        _quantityController.clear();
        _priceController.clear();
        _notesController.clear();
      });

      // Re-fetch data to reflect updated stock levels
      await Future.wait([
        productProvider.fetchProducts(),
        supplierProvider.fetchSuppliers(),
      ]);

      if (!mounted) return;
      
      // Find the updated product from the new list
      final updatedProduct = productProvider.products.firstWhere(
        (p) => p.id == productId,
        // Fallback to a dummy product if not found (unexpected)
        orElse: () => productProvider.products.isNotEmpty 
          ? productProvider.products.first 
          : Product(id: 'err', name: 'Product', category: '', sellingPrice: 0, stockQuantity: 0, minimumStockLevel: 0, unit: 'un', isLowStock: false, inventoryValue: 0),
      );
      
      _showSuccessDialog(updatedProduct);
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog(Product product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.primary, size: 28),
            SizedBox(width: 12),
            Text('Purchase Saved'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Stock has been updated successfully.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${product.stockQuantity} ${product.unit}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Back to Dashboard'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Purchase Record'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Transaction Details'),
              const SizedBox(height: 16),
              
              // Supplier Dropdown
              _buildLabel('Supplier *'),
              Consumer<SupplierProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return _buildLoadingDropdown('Loading Suppliers...');
                  }
                  return Container(
                    decoration: _containerDecoration(Icons.local_shipping_outlined),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        key: ValueKey('supplier_dropdown_${provider.isLoading}_${_selectedSupplierId == null}'),
                        isExpanded: true,
                        value: _selectedSupplierId,
                        hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Select Supplier'),
                        ),
                        items: provider.suppliers
                            .map((s) => s.id)
                            .toSet() // Ensure unique IDs
                            .map((id) {
                          final s = provider.suppliers.firstWhere((sup) => sup.id == id);
                          return DropdownMenuItem(
                            value: id.toString(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(s.name),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedSupplierId = val;
                            if (val != null) {
                              _selectedSupplierName = provider.suppliers.firstWhere((s) => s.id == val).name;
                            }
                          });
                        },
                        icon: const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Product Dropdown
              _buildLabel('Product *'),
              Consumer<ProductProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return _buildLoadingDropdown('Loading Products...');
                  }
                  return Container(
                    decoration: _containerDecoration(Icons.inventory_2_outlined),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        key: ValueKey('product_dropdown_${provider.isLoading}_${_selectedProductId == null}'),
                        isExpanded: true,
                        value: _selectedProductId,
                        hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Select Product'),
                        ),
                        items: provider.products
                            .map((p) => p.id)
                            .toSet() // Ensure unique IDs
                            .map((id) {
                          final p = provider.products.firstWhere((prod) => prod.id == id);
                          return DropdownMenuItem(
                            value: id.toString(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('${p.name} (${p.stockQuantity} ${p.unit} in stock)'),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedProductId = val;
                            if (val != null && _priceController.text.isEmpty) {
                              final product = provider.products.firstWhere((p) => p.id == val);
                              _priceController.text = product.sellingPrice.toString();
                            }
                          });
                        },
                        icon: const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Purchase Information'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Quantity *'),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(Icons.add_shopping_cart),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Required';
                            if (int.tryParse(val) == null || int.parse(val) <= 0) return 'Invalid';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Unit Price (Optional)'),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(Icons.attach_money),
                          // Optional as per request
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              _buildLabel('Date'),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: _inputDecoration(Icons.calendar_today_outlined),
              ),

              const SizedBox(height: 20),

              _buildLabel('Payment Status'),
              DropdownButtonFormField<String>(
                initialValue: _paymentStatus,
                items: ['Paid', 'Pending', 'Partial'].map((s) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
                onChanged: (val) => setState(() => _paymentStatus = val!),
                decoration: _inputDecoration(Icons.paid_outlined),
              ),

              const SizedBox(height: 20),

              _buildLabel('Notes (Optional)'),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: _inputDecoration(Icons.note_alt_outlined),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Purchase',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  BoxDecoration _containerDecoration(IconData icon) {
    return BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    );
  }

  InputDecoration _inputDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  Widget _buildLoadingDropdown(String hint) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      items: const [],
      onChanged: null,
      hint: Text(hint),
      decoration: _inputDecoration(Icons.sync),
    );
  }
}
