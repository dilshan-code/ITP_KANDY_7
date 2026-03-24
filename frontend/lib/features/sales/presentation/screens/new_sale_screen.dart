import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/utils/snackbar_utils.dart';
import 'package:frontend/features/sales/presentation/providers/sale_provider.dart';
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:frontend/features/products/presentation/providers/product_provider.dart';
import 'package:frontend/features/credit/presentation/providers/credit_provider.dart';
import 'package:frontend/features/credit/presentation/screens/credit_list_screen.dart';
import 'package:frontend/features/credit/domain/entities/customer.dart';
import 'package:frontend/features/sales/presentation/screens/invoice_dialog.dart';
import 'package:frontend/features/sales/presentation/screens/payment_confirmation_dialog.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Cart',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<SaleProvider>(
            builder: (context, provider, _) {
              if (provider.cartItems.isEmpty) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => provider.clearCart(),
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                label: const Text(
                  'Clear Cart',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<SaleProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 60,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add products from the Inventory to begin a sale.',
                    style: TextStyle(fontSize: 14, color: AppColors.textMedium),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Cart items list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.cartItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = provider.cartItems[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rs. ${(item['price'] as num).toDouble().toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildQuantityButton(
                                icon: Icons.remove,
                                color: AppColors.textMedium,
                                onPressed: () => provider.updateQuantity(
                                  index,
                                  (item['quantity'] as int) - 1,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                constraints: const BoxConstraints(minWidth: 40),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${item['quantity']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '${item['unit']}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMedium,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildQuantityButton(
                                icon: Icons.add,
                                color:
                                    (item['quantity'] as int) <
                                        (item['stockQuantity'] as int)
                                    ? AppColors.primary
                                    : Colors.grey,
                                isEnabled:
                                    (item['quantity'] as int) <
                                    (item['stockQuantity'] as int),
                                onPressed: () {
                                  if ((item['quantity'] as int) <
                                      (item['stockQuantity'] as int)) {
                                    provider.updateQuantity(
                                      index,
                                      (item['quantity'] as int) + 1,
                                    );
                                  } else {
                                    SnackBarUtils.showTopSnackBar(
                                      context,
                                      'Stock limit reached for ${item['name']}',
                                      isError: true,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Sticky Checkout Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Summary',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textMedium,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${provider.totalItems} Items',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Total Amount',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textMedium,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rs. ${provider.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showConfirmation(
                                context,
                                provider,
                                'credit',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                side: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              child: const Text(
                                'Credit Loan',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () =>
                                  _showConfirmation(context, provider, 'cash'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Pay Cash',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isEnabled = true,
  }) {
    return InkWell(
      onTap: isEnabled ? onPressed : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  void _showConfirmation(
    BuildContext context,
    SaleProvider provider,
    String method,
  ) async {
    Customer? selectedCustomer;

    if (method == 'credit') {
      selectedCustomer = await Navigator.push<Customer>(
        context,
        MaterialPageRoute(
          builder: (context) => const CreditListScreen(isSelectionMode: true),
        ),
      );
      if (selectedCustomer == null) return;
    }

    final String generatedInvoiceId =
        'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => PaymentConfirmationDialog(
        items: List<Map<String, dynamic>>.from(provider.cartItems),
        totalAmount: provider.totalAmount,
        paymentMethod: method,
        customerName: selectedCustomer?.name ?? 'Walk-in Customer',
        invoiceId: generatedInvoiceId,
        onConfirm: () => _completeSale(
          context,
          provider,
          method,
          generatedInvoiceId,
          selectedCustomer,
        ),
      ),
    );
  }

  void _completeSale(
    BuildContext context,
    SaleProvider provider,
    String method,
    String invoiceId,
    Customer? selectedCustomer,
  ) async {
    final saleDetails = await provider.completeSale(
      id: invoiceId,
      paymentMethod: method,
      customerId: selectedCustomer?.id ?? '',
      customerName: selectedCustomer?.name ?? '',
    );

    if (!context.mounted) return;

    if (saleDetails != null) {
      // Stock reduced on backend, now refresh local list in ProductProvider
      context.read<ProductProvider>().fetchProducts();

      // Trigger Notifications
      final notificationProvider = context.read<NotificationProvider>();

      // 1. Low Stock Trigger
      final products = context.read<ProductProvider>().products;
      for (var item in provider.cartItems) {
        final product = products.firstWhere(
          (p) => p.id == item['productId'],
          orElse: () => products.firstWhere((p) => p.name == item['name']),
        );
        // Check if stock is now low (using 10 as threshold)
        if (product.stockQuantity <= 10) {
          notificationProvider.createNotification(
            type: 'warning',
            title: 'Low Stock Alert',
            message:
                'Product "${product.name}" is running low (${product.stockQuantity} units left).',
          );
        }
      }

      // 2. Credit Limit Pass Trigger
      if (method == 'credit' && selectedCustomer != null) {
        // Fetch latest customer data to see new balance
        final creditProvider = context.read<CreditProvider>();
        await creditProvider.fetchCustomers();
        if (!context.mounted) return;
        final updatedCustomer = creditProvider.customers.firstWhere(
          (c) => c.id == selectedCustomer.id,
        );

        if (updatedCustomer.totalOutstanding > updatedCustomer.creditLimit) {
          notificationProvider.createNotification(
            type: 'alert',
            title: 'Credit Limit Exceeded',
            message:
                'Customer ${updatedCustomer.name} has passed their credit limit of Rs. ${updatedCustomer.creditLimit.toStringAsFixed(0)}.',
          );
        }
      }

      SnackBarUtils.showTopSnackBar(
        context,
        'Payment of Rs. ${saleDetails['totalAmount'].toStringAsFixed(2)} successful.',
      );
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => InvoiceDialog(saleDetails: saleDetails),
      );
    } else {
      SnackBarUtils.showTopSnackBar(
        context,
        'Failed to complete sale.',
        isError: true,
      );
    }
  }
}
