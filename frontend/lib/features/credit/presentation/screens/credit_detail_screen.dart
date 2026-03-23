import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/utils/snackbar_utils.dart';
import 'package:frontend/features/credit/domain/entities/customer.dart';
import 'package:frontend/features/credit/presentation/providers/credit_provider.dart';
import 'package:frontend/features/sales/presentation/screens/invoice_dialog.dart';

class CreditDetailScreen extends StatefulWidget {
  final Customer customer;
  const CreditDetailScreen({super.key, required this.customer});

  @override
  State<CreditDetailScreen> createState() => _CreditDetailScreenState();
}

class _CreditDetailScreenState extends State<CreditDetailScreen> {
  late Customer _currentCustomer;

  @override
  void initState() {
    super.initState();
    _currentCustomer = widget.customer;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<CreditProvider>(
          context,
          listen: false,
        ).fetchTransactions(_currentCustomer.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentCustomer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditCustomerDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _showDeleteConfirmation(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<CreditProvider>(
        builder: (context, provider, _) {
          // Update character if found in provider list (to reflect edits)
          final updatedCustomer = provider.customers.isEmpty
              ? null
              : provider.customers.cast<Customer?>().firstWhere(
                  (c) => c?.id == _currentCustomer.id,
                  orElse: () => null,
                );

          if (updatedCustomer != null) {
            _currentCustomer = updatedCustomer;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer header card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          _currentCustomer.name.isNotEmpty
                              ? _currentCustomer.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentCustomer.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentCustomer.phone,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            'Outstanding',
                            'Rs ${_currentCustomer.totalOutstanding.toStringAsFixed(0)}',
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          _buildStatItem(
                            'Limit',
                            'Rs ${_currentCustomer.creditLimit.toStringAsFixed(0)}',
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          _buildStatItem(
                            'Status',
                            _currentCustomer.status.toUpperCase(),
                          ),
                        ],
                      ),
                      if (_currentCustomer.totalOutstanding > 0) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showSettleConfirmation(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Settle Full Balance',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // History section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'History & Invoices',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (provider.isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (!provider.isLoading &&
                    provider.transactions.isEmpty &&
                    provider.customerSales.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: Colors.grey.shade200,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No history found',
                            style: TextStyle(color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  _buildCombinedHistory(context, provider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'credit_add_transaction_btn',
        onPressed: () => _showAddTransactionDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
        ),
      ],
    );
  }

  Widget _buildCombinedHistory(BuildContext context, CreditProvider provider) {
    // Combine sales and transactions into a single list sorted by date
    final List<dynamic> combined = [
      ...provider.transactions,
      ...provider.customerSales,
    ];

    combined.sort((a, b) {
      final dateA = DateTime.parse(a is Map ? a['createdAt'] : a.createdAt);
      final dateB = DateTime.parse(b is Map ? b['createdAt'] : b.createdAt);
      return dateB.compareTo(dateA);
    });

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: combined.length,
      itemBuilder: (context, index) {
        final item = combined[index];
        if (item is Map) {
          return _buildSaleCard(Map<String, dynamic>.from(item));
        } else {
          return _buildTransactionCard(item);
        }
      },
    );
  }

  Widget _buildSaleCard(Map<String, dynamic> sale) {
    final date = DateTime.parse(sale['createdAt'] ?? DateTime.now().toString());
    final formattedTime = DateFormat('hh:mm a').format(date);
    final amount = (sale['totalAmount'] ?? 0.0) as double;
    final customerName = sale['customerName'] ?? 'Walk-in Customer';
    final invoiceId = sale['id']?.toString().toUpperCase() ?? 'N/A';
    final paymentMethod = sale['paymentMethod'] ?? 'credit';
    final isCredit = paymentMethod.toLowerCase() == 'credit';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: '',
              pageBuilder: (context, anim1, anim2) =>
                  InvoiceDialog(saleDetails: sale),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (isCredit ? Colors.orange : AppColors.primary).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: isCredit ? Colors.orange : AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#${invoiceId.length > 5 ? invoiceId.substring(0, 5) : invoiceId} • $formattedTime',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildPaymentBadge(paymentMethod),
                    ],
                  ),
                ),
                Text(
                  '${isCredit ? '-' : ''} Rs ${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isCredit ? AppColors.error : AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentBadge(String method) {
    final isCredit = method.toLowerCase() == 'credit';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isCredit ? Colors.orange : AppColors.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: isCredit ? Colors.orange.shade800 : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTransactionCard(dynamic txn) {
    final date = DateTime.parse(txn.createdAt);
    final isPayment = txn.type == 'payment';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPayment
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPayment
                  ? Icons.account_balance_wallet_outlined
                  : Icons.info_outline,
              color: isPayment ? AppColors.primary : AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  DateFormat('dd MMM, hh:mm a').format(date),
                  style: TextStyle(fontSize: 11, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          Text(
            '${isPayment ? '+' : '-'} Rs ${txn.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isPayment ? AppColors.primary : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettleConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Settle Balance'),
        content: Text(
          'Confirm payment of Rs ${_currentCustomer.totalOutstanding.toStringAsFixed(0)} for ${_currentCustomer.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<CreditProvider>().settleFullBalance(
                _currentCustomer,
              );
              if (context.mounted) {
                SnackBarUtils.showTopSnackBar(
                  context,
                  'Credit settled successfully',
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showEditCustomerDialog(BuildContext context) {
    final nameController = TextEditingController(text: _currentCustomer.name);
    final phoneController = TextEditingController(text: _currentCustomer.phone);
    final limitController = TextEditingController(
      text: _currentCustomer.creditLimit.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Customer name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(hintText: 'Phone number'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: limitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Credit Limit (Rs)',
                prefixText: 'Rs ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final double? limit = double.tryParse(limitController.text);
                final success =
                    await Provider.of<CreditProvider>(
                      context,
                      listen: false,
                    ).updateCustomer(_currentCustomer.id, {
                      'name': nameController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'creditLimit': limit ?? _currentCustomer.creditLimit,
                    });

                if (context.mounted) {
                  if (success) {
                    SnackBarUtils.showTopSnackBar(
                      context,
                      'Customer updated successfully',
                    );
                    Navigator.pop(ctx);
                  } else {
                    SnackBarUtils.showTopSnackBar(
                      context,
                      context.read<CreditProvider>().error ??
                          'Failed to update customer',
                      isError: true,
                    );
                  }
                }
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          _currentCustomer.totalOutstanding > 0
              ? 'Warning: This customer has Rs ${_currentCustomer.totalOutstanding.toStringAsFixed(0)} outstanding credit. Are you sure you want to delete them?'
              : 'Are you sure you want to delete ${_currentCustomer.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final id = _currentCustomer.id;
              final success = await Provider.of<CreditProvider>(
                context,
                listen: false,
              ).deleteCustomer(id);
              if (context.mounted) {
                if (success) {
                  SnackBarUtils.showTopSnackBar(
                    context,
                    'Customer deleted successfully',
                  );
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Go back from detail screen
                } else {
                  SnackBarUtils.showTopSnackBar(
                    context,
                    context.read<CreditProvider>().error ??
                        'Failed to delete customer',
                    isError: true,
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'credit';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'credit', label: Text('Credit')),
                  ButtonSegment(value: 'payment', label: Text('Payment')),
                ],
                selected: {type},
                onSelectionChanged: (v) => setDialogState(() => type = v.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: 'Description'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Amount'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  await Provider.of<CreditProvider>(
                    context,
                    listen: false,
                  ).addTransaction({
                    'customerId': widget.customer.id,
                    'type': type,
                    'title': titleController.text.trim(),
                    'amount': amount,
                  });
                  if (!context.mounted) return;
                  if (ctx.mounted) Navigator.pop(ctx);
                  context.read<CreditProvider>().fetchTransactions(
                    widget.customer.id,
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
