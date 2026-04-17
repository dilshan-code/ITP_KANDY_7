// ------------------------------------------------------------------------------
// File: record_purchase_screen.dart
// Purpose: Complex Batch Procurement and Inventory Intake Engine.
// Rationale: Manages the end-to-end lifecycle of stock acquisition from 
//   external suppliers. Supports dynamic multi-product line items, advanced 
//   tax calculations, and automated debt/payable tracking. Orchestrates 
//   system-wide synchronization across Inventory, CRM, and Dashboard services.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // UI: Flutter Material widgets
import 'package:google_fonts/google_fonts.dart'; // UI: Poppins typography
import 'package:provider/provider.dart'; // State: Provider read/watch
import 'package:intl/intl.dart'; // Format: Date formatting
import 'package:frontend/core/theme/app_colors.dart'; // Theme: Brand colour tokens
import 'package:frontend/core/utils/snackbar_utils.dart'; // UX: Feedback toasts with diagnostics
import 'package:frontend/features/suppliers/presentation/providers/purchase_provider.dart'; // State: Purchase records
import 'package:frontend/features/suppliers/presentation/providers/supplier_provider.dart'; // State: Supplier directory
import 'package:frontend/features/products/presentation/providers/product_provider.dart'; // State: Product catalogue
import 'package:frontend/features/products/domain/entities/product.dart'; // Domain: Product model
import 'package:frontend/features/suppliers/domain/entities/purchase.dart'; // Domain: Purchase entity
import 'package:frontend/features/suppliers/presentation/utils/export_utils.dart'; // Export Utilities
import 'package:frontend/shared/main_shell.dart'; // Shell: Dashboard refresh trigger
import 'package:frontend/shared/widgets/app_back_button.dart'; // Standardized navigation trigger
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart'; // State: Identity management

class RecordPurchaseScreen extends StatefulWidget {
  final Purchase? purchase;

  const RecordPurchaseScreen({super.key, this.purchase});

  @override
  State<RecordPurchaseScreen> createState() => _RecordPurchaseScreenState();
}

class _RecordPurchaseScreenState extends State<RecordPurchaseScreen> {
  final _invoiceController = TextEditingController();
  final _subtotalController = TextEditingController();
  final _taxController = TextEditingController();
  final _amountPaidController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();

  String? _selectedSupplierId;
  String _selectedSupplierName = '';
  final List<Map<String, dynamic>> _purchasedItems = [];
  bool _isSubmitting = false;
  bool _showSupplierError = false;
  bool _showProductError = false;

  String _paymentStatus = 'Paid'; // Default status
  String _paymentMethod = 'Cash'; // Default method
  DateTime _selectedDate = DateTime.now();

  bool get _isReadOnly => widget.purchase != null;

  @override
  void initState() {
    super.initState();
    if (widget.purchase != null) {
      final p = widget.purchase!;
      _selectedSupplierId = p.supplierId;
      _selectedSupplierName = p.supplierName;
      _selectedDate =
          (DateTime.tryParse(p.purchaseDate) ?? DateTime.now()).toLocal();
      _paymentStatus = p.status.isNotEmpty 
          ? p.status[0].toUpperCase() + p.status.substring(1).toLowerCase()
          : 'Paid';
      _paymentMethod = p.paymentMethod.isNotEmpty
          ? p.paymentMethod[0].toUpperCase() + p.paymentMethod.substring(1).toLowerCase()
          : 'Cash';
      _notesController.text = p.notes;
      _invoiceController.text = p.invoiceNumber;
      _amountPaidController.text = p.amountPaid.toString();
      _taxController.text = p.tax.toString();
      
      for (var item in p.items) {
        if (item is Map) {
          _purchasedItems.add({
            'productId': item['productId'],
            'name': item['productName'] ?? item['name'] ?? '',
            'quantity': item['quantity'],
            'unit': item['unit'],
            'costPrice': item['costPrice'] ?? item['price'] ?? 0.0,
            'qtyController': TextEditingController(text: item['quantity'].toString()),
            'costController': TextEditingController(text: (item['costPrice'] ?? item['price'] ?? 0.0).toString()),
          });
        }
      }
    }
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
    _invoiceController.dispose();
    _subtotalController.dispose();
    _taxController.dispose();
    _amountPaidController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    for (var item in _purchasedItems) {
      item['qtyController']?.dispose();
      item['costController']?.dispose();
    }
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

  double get _subtotal {
    // Aggregation logic: Summing up the base cost of all selected products.
    return _purchasedItems.fold(0.0, (sum, item) {
      final price = item['costPrice'] ?? 0.0; // Per-unit acquisition cost
      final qty = item['quantity'] ?? 0; // Number of units received
      return sum + (price * qty); // Cumulative subtotal
    });
  }

  double get _tax => double.tryParse(_taxController.text) ?? 0; // Value-added or sales tax
  double get _totalAmount => _subtotal + _tax; // Gross liability to the supplier
  double get _amountPaid => double.tryParse(_amountPaidController.text) ?? 0; // Cash outflow today
  double get _remaining => _totalAmount - _amountPaid; // Residual debt to be recorded as 'payable'

  void _addItem(Product product) {
    setState(() {
      // Logic: If product already exists in the batch, increment quantity instead of adding duplicate line.
      final existingIndex = _purchasedItems.indexWhere((item) => item['productId'] == product.id);
      
      if (existingIndex != -1) {
        _purchasedItems[existingIndex]['quantity'] += 1;
        // UX: Update the controller so the UI reflects the new quantity immediately
        _purchasedItems[existingIndex]['qtyController'].text = _purchasedItems[existingIndex]['quantity'].toString();
      } else {
        _purchasedItems.add({
          'productId': product.id,
          'name': product.name,
          'quantity': 1,
          'unit': product.unit,
          'costPrice': product.sellingPrice,
          'qtyController': TextEditingController(text: '1'),
          'costController': TextEditingController(text: product.sellingPrice.toString()),
        });
      }
      _showProductError = false;

      // Locked-in Logic: If status is 'Paid', keep amountPaid in sync with the new total
      if (_paymentStatus == 'Paid') {
        _amountPaidController.text = _totalAmount.toStringAsFixed(2);
      }
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
      
      // Locked-in Logic: If status is 'Paid', keep amountPaid in sync with the new total
      if (_paymentStatus == 'Paid') {
        _amountPaidController.text = _totalAmount.toStringAsFixed(2);
      }
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
    final String rawInvoice = _invoiceController.text.trim();
    final String invoiceNumber = rawInvoice.isEmpty
        ? 'PUR-${DateFormat('yyMMdd-HHmmss').format(DateTime.now())}'
        : rawInvoice;

    final provider = Provider.of<PurchaseProvider>(context, listen: false);
    final success = await provider.addPurchase({
      'supplierId': _selectedSupplierId,
      'supplierName': _selectedSupplierName,
      'invoiceNumber': invoiceNumber,
      'purchaseDate': _selectedDate.toIso8601String(),
      'items': _purchasedItems,
      'subtotal': _subtotal,
      'tax': _tax,
      'totalAmount': _totalAmount,
      'amountPaid': _amountPaid,
      'remaining': _remaining,
      'notes': _notesController.text.trim(),
      'status': _paymentStatus.toLowerCase(),
      'paymentMethod': _paymentMethod.toLowerCase(),
    });
    if (success && mounted) {
      final productProvider = context.read<ProductProvider>();
      
      // Reset state BEFORE fetching new data to prevent UI glitches during rebuilt.
      setState(() {
        _isSubmitting = false;
        _selectedSupplierId = null;
        _purchasedItems.clear();
        _invoiceController.clear();
        _taxController.clear();
        _amountPaidController.clear();
      });

      // Stock reconciliation: Ensure local product list matches server after batch purchase.
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
      appBar: AppBar(
        title: Text(_isReadOnly ? 'Purchase Details' : 'Record Purchase'),
        leading: AppBackButton(
          onTap: () => Navigator.pop(context),
          margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        ),
        actions: [
          if (_isReadOnly)
            IconButton(
              icon: Icon(Icons.receipt_long, color: AppColors.primary),
              onPressed: () {
                final owner = context.read<AuthProvider>().currentOwner;
                SupplierExportUtils.exportPaymentReceiptPdf(widget.purchase!, owner: owner);
              },
              tooltip: 'Export Receipt',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Supplier selection
              _buildLabel('Select Supplier *'),
              SizedBox(height: 8),
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
                          ? AppColors.error // Alert user if selection is missing
                          : Colors.grey.shade300,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        key: ValueKey(
                            'supplier_id_dropdown_${supplierProvider.isLoading}_${_selectedSupplierId == null}'),
                        isExpanded: true,
                        value: _selectedSupplierId,
                        hint: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Choose a supplier'), // UX: Prompt user to select partner
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
                              child: Text(s.name), // Textual representation of the partner
                            ),
                          );
                        }).toList(),
                        onChanged: _isReadOnly ? null : (value) {
                          if (value == null) return;
                          setState(() {
                            // Link selected ID to the supplier entity for data bundling.
                            _selectedSupplierId = value;
                            final supplier =
                                supplierProvider.suppliers.firstWhere(
                              (s) => s.id == value,
                            );
                            _selectedSupplierName = supplier.name;
                            _showSupplierError = false;
                          });
                        },
                        icon: Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.arrow_drop_down,
                              color: AppColors.primary),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),

              // Product Selection
              if (!_isReadOnly) ...[
                _buildLabel('Add Products to Stock *'),
                SizedBox(height: 8),
                _buildProductSelector(),
                SizedBox(height: 16),
              ],

              if (_purchasedItems.isNotEmpty) ...[
                Text(
                  'Purchased Items',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textMedium,
                  ),
                ),
                SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _purchasedItems.length,
                  itemBuilder: (context, index) {
                    final item = _purchasedItems[index];
                    return _buildPurchasedItemCard(index, item);
                  },
                ),
                SizedBox(height: 20),
              ],

              // Invoice number
              _buildLabel('Invoice Number (Optional)'),
              if (!_isReadOnly) ...[
                SizedBox(height: 4),
                Text(
                  'Leave empty to auto-generate',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                ),
              ],
              SizedBox(height: 8),
              TextField(
                controller: _invoiceController,
                enabled: !_isReadOnly,
                decoration: InputDecoration(
                  hintText: 'e.g. INV-0001',
                  prefixIcon: const Icon(
                    Icons.description_rounded,
                    color: AppColors.primary,
                  ),
                  filled: _isReadOnly,
                  fillColor: _isReadOnly ? Colors.grey.shade100 : null,
                ),
              ),
              SizedBox(height: 20),

              // Date
              _buildLabel('Purchase Date'),
              SizedBox(height: 8),
              GestureDetector(
                onTap: _isReadOnly ? null : () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextField(
                    controller: _dateController,
                    enabled: !_isReadOnly,
                    decoration: InputDecoration(
                      hintText: 'Select Date',
                      prefixIcon: const Icon(
                        Icons.calendar_month_rounded,
                        color: AppColors.primary,
                      ),
                      filled: _isReadOnly,
                      fillColor: _isReadOnly ? Colors.grey.shade100 : null,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Amounts
              _buildLabel('Subtotal'),
              SizedBox(height: 8),
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
                    Text(
                      'Rs ',
                      style: GoogleFonts.poppins(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      _subtotal.toStringAsFixed(2),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              _buildLabel('Tax Amount'),
              SizedBox(height: 8),
              TextField(
                controller: _taxController,
                enabled: !_isReadOnly,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.price_change_rounded, color: AppColors.primary),
                  filled: _isReadOnly,
                  fillColor: _isReadOnly ? Colors.grey.shade100 : null,
                ),
              ),
              SizedBox(height: 20),

              // Payment Status and Method
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Payment Status'),
                        SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: _containerDecoration(
                            Icons.pending_actions_outlined,
                            borderColor: Colors.grey.shade300,
                            bgColor: _isReadOnly ? Colors.grey.shade100 : null,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _paymentStatus,
                              items: ['Paid', 'Partial', 'Pending']
                                  .map((status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(status),
                                      ))
                                  .toList(),
                                onChanged: _isReadOnly ? null : (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _paymentStatus = value;
                                    if (value == 'Paid') {
                                      _amountPaidController.text = _totalAmount.toStringAsFixed(2);
                                    } else if (value == 'Pending') {
                                      _amountPaidController.text = '0';
                                    }
                                  });
                                },
                              icon: const Icon(Icons.arrow_drop_down,
                                  color: AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Payment Method'),
                        SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: _containerDecoration(
                            Icons.payment_outlined,
                            borderColor: Colors.grey.shade300,
                            bgColor: _isReadOnly ? Colors.grey.shade100 : null,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _paymentMethod,
                              items: ['Cash', 'Credit', 'Bank Transfer', 'App Transfer']
                                  .map((method) => DropdownMenuItem(
                                        value: method,
                                        child: Text(method),
                                      ))
                                  .toList(),
                              onChanged: _isReadOnly ? null : (value) {
                                if (value != null) {
                                  setState(() => _paymentMethod = value);
                                }
                              },
                              icon: const Icon(Icons.arrow_drop_down,
                                  color: AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              _buildLabel('Amount Paid'),
              SizedBox(height: 8),
              TextField(
                controller: _amountPaidController,
                enabled: !_isReadOnly && _paymentStatus == 'Partial',
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.poppins(
                  color: (!_isReadOnly && _paymentStatus == 'Partial') 
                    ? AppColors.textDark 
                    : AppColors.textMedium,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixIcon: const Icon(
                    Icons.payments_rounded,
                    color: AppColors.primary,
                  ),
                  filled: _isReadOnly || _paymentStatus != 'Partial',
                  fillColor: (_isReadOnly || _paymentStatus != 'Partial') 
                    ? Colors.grey.shade100 
                    : null,
                ),
              ),
              SizedBox(height: 20),

              // Notes
              _buildLabel('Additional Notes (Optional)'),
              SizedBox(height: 8),
              TextField(
                controller: _notesController,
                enabled: !_isReadOnly,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add remarks about this purchase...',
                  filled: _isReadOnly,
                  fillColor: _isReadOnly ? Colors.grey.shade100 : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      'Subtotal',
                      'Rs ${_subtotal.toStringAsFixed(2)}',
                      labelColor: Colors.white.withValues(alpha: 0.9),
                      valueColor: Colors.white,
                    ),
                    SizedBox(height: 8),
                    _buildSummaryRow(
                      'Tax', 
                      'Rs ${_tax.toStringAsFixed(2)}',
                      labelColor: Colors.white.withValues(alpha: 0.9),
                      valueColor: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      'Total Amount',
                      'Rs ${_totalAmount.toStringAsFixed(2)}',
                      isBold: true,
                      labelColor: Colors.white,
                      valueColor: Colors.white,
                    ),
                    SizedBox(height: 8),
                    _buildSummaryRow(
                      'Amount Paid',
                      'Rs ${_amountPaid.toStringAsFixed(2)}',
                      labelColor: Colors.white.withValues(alpha: 0.9),
                      valueColor: Colors.white,
                    ),
                    SizedBox(height: 8),
                    _buildSummaryRow(
                      'Remaining',
                      'Rs ${_remaining.toStringAsFixed(2)}',
                      isBold: true,
                      labelColor: Colors.white,
                      valueColor: Colors.white,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              if (_isReadOnly)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBlueBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'This record is locked for auditing.',
                      style: GoogleFonts.poppins(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
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
                        : Text(
                            'Record Purchase',
                            style: GoogleFonts.poppins(
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
      style: GoogleFonts.poppins(
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
    Color? labelColor,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14, 
            color: labelColor ?? AppColors.textMedium,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
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
            child: Row(
              children: [
                Icon(Icons.sync, color: AppColors.textLight, size: 20),
                SizedBox(width: 12),
                Text('Loading products...', style: GoogleFonts.poppins(color: AppColors.textLight)),
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
              hint: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Select product to add'),
              ),
              icon: Padding(
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.inventory_2_outlined,
                    size: 20, color: AppColors.primary),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  item['name'],
                  style:
                      GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              if (!_isReadOnly)
                IconButton(
                  icon: Icon(Icons.remove_circle_outline,
                      color: AppColors.error, size: 20),
                  onPressed: () => _removeItem(index),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Qty (${item['unit'] ?? ''})',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textMedium)),
                    SizedBox(height: 4),
                    TextFormField(
                      controller: item['qtyController'],
                      enabled: !_isReadOnly,
                      keyboardType: TextInputType.number,
                      onChanged: (val) =>
                          _updateItem(index, quantity: int.tryParse(val) ?? 0),
                      style: GoogleFonts.poppins(
                        color: _isReadOnly ? AppColors.textMedium : AppColors.textDark,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: _isReadOnly,
                        fillColor: _isReadOnly ? Colors.grey.shade100 : null,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cost Price',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textMedium)),
                    SizedBox(height: 4),
                    TextFormField(
                      controller: item['costController'],
                      enabled: !_isReadOnly,
                      keyboardType: TextInputType.number,
                      onChanged: (val) =>
                          _updateItem(index, costPrice: double.tryParse(val) ?? 0),
                      style: GoogleFonts.poppins(
                        color: _isReadOnly ? AppColors.textMedium : AppColors.textDark,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixText: 'Rs ',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: _isReadOnly,
                        fillColor: _isReadOnly ? Colors.grey.shade100 : null,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Total',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textMedium)),
                  SizedBox(height: 10),
                  Text(
                    'Rs ${( (item['quantity'] ?? 0) * (item['costPrice'] ?? 0.0) ).toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _containerDecoration(IconData icon,
      {Color? borderColor, Color? bgColor}) {
    return BoxDecoration(
      color: bgColor ?? Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor ?? Colors.grey.shade300),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    );
  }

  Widget _buildLoadingDropdown(String hint) {
    return Container(
      decoration: _containerDecoration(Icons.sync),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          items: [],
          onChanged: null,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text(hint),
              ],
            ),
          ),
          icon: Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.arrow_drop_down, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

