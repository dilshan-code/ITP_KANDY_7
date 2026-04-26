// ------------------------------------------------------------------------------
// File: credit_detail_screen.dart
// Purpose: Unified Financial Ledger and Debt Lifecycle Monitor.
// Rationale: Merges diverse transaction types (Credit, Payments, Sales) into 
//   a single chronological timeline for deep-dive customer audits. Supports 
//   payment reconciliation, automated statement generation, and proactive 
//   balance monitoring with administrative guards.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // UI: Flutter Material widgets
import 'package:google_fonts/google_fonts.dart'; // UI: Poppins typography
import 'package:provider/provider.dart'; // State: Provider read/watch
import 'package:intl/intl.dart'; // Format: Date and currency formatting
import 'package:frontend/core/theme/app_colors.dart'; // Theme: Brand colour tokens
import 'package:frontend/core/utils/snackbar_utils.dart'; // UX: Feedback toasts with diagnostics
import 'package:frontend/features/credit/domain/entities/customer.dart'; // Domain: Customer model
import 'package:frontend/features/credit/domain/entities/credit_transaction.dart'; // Domain: Ledger entry model
import 'package:frontend/features/credit/presentation/providers/credit_provider.dart'; // State: Customer data manager
import 'package:frontend/features/sales/presentation/providers/sale_provider.dart'; // State: Sales history for ledger merge
import 'package:frontend/features/sales/presentation/screens/invoice_dialog.dart'; // Navigation: Sale invoice detail
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart'; // State: In-app alert logging
import 'package:frontend/features/credit/presentation/utils/credit_pdf_utils.dart'; // PDF: Customer statement generator
import 'package:frontend/shared/widgets/modern_pdf_icon.dart'; // UI: Brand-consistent PDF trigger icon
import 'package:frontend/shared/main_shell.dart'; // Shell: Global app state anchor for dashboard refresh
import 'package:frontend/shared/widgets/app_back_button.dart'; // UI: Standardized navigation trigger
import 'package:frontend/shared/widgets/tactile_scale.dart'; // UI: Interaction physics
import 'package:animate_do/animate_do.dart'; // UI: Motion design framework
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart'; // Auth: User context

/// CreditDetailScreen: An in-depth financial ledger for a specific customer.
/// Displays a unified chronological view of sales, payments, and credit adjustments.
class CreditDetailScreen extends StatefulWidget {
  final Customer customer;
  const CreditDetailScreen({super.key, required this.customer});

  @override
  State<CreditDetailScreen> createState() => _CreditDetailScreenState();
}

class _CreditDetailScreenState extends State<CreditDetailScreen> {
  late Customer _currentCustomer;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentCustomer = widget.customer;
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final creditProvider = Provider.of<CreditProvider>(context, listen: false);
        final saleProvider = Provider.of<SaleProvider>(context, listen: false);
        
        creditProvider.fetchCustomers();
        creditProvider.fetchTransactions(_currentCustomer.id);
        saleProvider.fetchSalesByCustomer(_currentCustomer.id);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final creditProvider = context.read<CreditProvider>();
      final saleProvider = context.read<SaleProvider>();

      if (creditProvider.hasMoreTransactions && !creditProvider.isFetchingMoreTransactions) {
        creditProvider.fetchTransactions(_currentCustomer.id, refresh: false);
      }
      if (saleProvider.hasMore && !saleProvider.isFetchingMore) {
        saleProvider.fetchSalesByCustomer(_currentCustomer.id, refresh: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentCustomer.name),
        leading: AppBackButton(
          onTap: () => Navigator.pop(context),
          margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_rounded),
            onPressed: () => _showEditCustomerDialog(context),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: AppColors.error),
            onPressed: () => _showDeleteConfirmation(context),
          ),
          IconButton(
            icon: const ModernPdfIcon(),
            onPressed: () {
              final creditProvider = context.read<CreditProvider>();
              final saleProvider = context.read<SaleProvider>();
              
              // Filter logic to unify disparate data streams for the PDF statement.
              final customerSales = saleProvider.sales.where((sale) {
                if (sale is Map) {
                  return sale['customerId'] == _currentCustomer.id;
                }
                return false;
              }).toList();

              // Exclude automated system transactions that pollute the human-readable statement.
              final filteredTransactions = creditProvider.transactions.where(
                (txn) => !(txn.type == 'credit' && txn.title.startsWith('Purchase Loan')) &&
                         !(txn.type == 'payment' && (txn.title == 'Full Balance Settlement' || txn.title == 'Partial Credit Payment')),
              ).toList();

              final List<dynamic> combined = [
                ...filteredTransactions,
                ...customerSales,
              ];

              // Chronological sorting for financial auditing.
              combined.sort((a, b) {
                final dateA = DateTime.parse(a is Map ? a['createdAt'] : a.createdAt).toLocal();
                final dateB = DateTime.parse(b is Map ? b['createdAt'] : b.createdAt).toLocal();
                return dateB.compareTo(dateA);
              });


              final owner = context.read<AuthProvider>().currentOwner;
              CreditPdfUtils.generateAndDownloadStatement(
                customer: _currentCustomer,
                history: combined,
                owner: owner,
              );
            },
            tooltip: 'Download Statement',
          ),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Consumer2<CreditProvider, SaleProvider>(
          builder: (context, provider, saleProvider, _) {
            // Chronological Merger: Sorting disparate data sources for the ledger view
            final customerSales = saleProvider.sales.where((sale) {
              if (sale is Map) {
                return sale['customerId'] == _currentCustomer.id;
              }
              return false;
            }).toList();

            // Real-time synchronization: Update the local entity if the provider data changes.
            final updatedCustomer = provider.customers.isEmpty
                ? null
                : provider.customers.cast<Customer?>().firstWhere(
                    (c) => c?.id == _currentCustomer.id,
                    orElse: () => null,
                  );

            if (updatedCustomer != null) {
              _currentCustomer = updatedCustomer;
            }

            // Noise Reduction: Filter out system-generated metadata transactions for cleaner UI.
            final filteredTransactions = provider.transactions.where(
              (txn) => !(txn.type == 'credit' && txn.title.startsWith('Purchase Loan')) &&
                       !(txn.type == 'payment' && (txn.title == 'Full Balance Settlement' || txn.title == 'Partial Credit Payment')),
            ).toList();

            return SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer header card: Premium Financial Identity Card
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0F4C3F), Color(0xFF166534), Color(0xFF22C55E)],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F4C3F).withValues(alpha: 0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Stack(
                          children: [
                            // Decorative depth circles
                            Positioned(
                              top: -60,
                              right: -60,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -40,
                              left: -40,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                children: [
                                  // Identity Block
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                                    ),
                                    child: CircleAvatar(
                                      radius: 36,
                                      backgroundColor: Colors.white,
                                      child: Text(
                                        _currentCustomer.name.isNotEmpty
                                            ? _currentCustomer.name[0].toUpperCase()
                                            : '?',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF0F4C3F),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 32,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _currentCustomer.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _currentCustomer.phone,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // Glassmorphic Statistics
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatNode(
                                          'BALANCE',
                                          'Rs.${_currentCustomer.totalOutstanding.toStringAsFixed(0)}',
                                          Icons.account_balance_wallet_rounded,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildStatNode(
                                          'LIMIT',
                                          'Rs.${_currentCustomer.creditLimit.toStringAsFixed(0)}',
                                          Icons.speed_rounded,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildStatNode(
                                          'STATUS',
                                          _currentCustomer.totalOutstanding <= 0 ? 'CLEAR' : _currentCustomer.status.toUpperCase(),
                                          Icons.shield_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_currentCustomer.totalOutstanding > 0) ...[
                                    const SizedBox(height: 28),
                                    TactileScale(
                                      onTap: () => _showSettleConfirmation(context),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          'SETTLE FULL BALANCE',
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF0F4C3F),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // History section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'History & Invoices',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (provider.isLoading)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  SizedBox(height: 12),

                  if (!provider.isLoading &&
                      !saleProvider.isLoading &&
                      filteredTransactions.isEmpty &&
                      customerSales.isEmpty)
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
                            SizedBox(height: 12),
                            Text(
                              'No history found',
                              style: GoogleFonts.poppins(color: AppColors.textLight),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    _buildCombinedHistory(context, filteredTransactions, customerSales, provider.isFetchingMoreTransactions || saleProvider.isFetchingMore),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'credit_add_transaction_btn',
        onPressed: () => _showAddTransactionDialog(context),
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatNode(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.6),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedHistory(BuildContext context, List<CreditTransaction> transactions, List<dynamic> customerSales, bool isFetchingMore) {
    // Combine sales and transactions into a single list sorted by date
    final List<dynamic> combined = [
      ...transactions,
      ...customerSales,
    ];

    combined.sort((a, b) {
      final dateA = DateTime.parse(a is Map ? a['createdAt'] : a.createdAt).toLocal();
      final dateB = DateTime.parse(b is Map ? b['createdAt'] : b.createdAt).toLocal();
      return dateB.compareTo(dateA);
    });

    return Column(
      children: [
        ListView.builder(
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
        ),
        if (isFetchingMore)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      ],
    );
  }

  Widget _buildSaleCard(Map<String, dynamic> sale) {
    final date = DateTime.parse(sale['createdAt'] ?? DateTime.now().toString()).toLocal();
    final formattedTime = DateFormat('hh:mm a').format(date);
    final amount = (sale['totalAmount'] ?? 0.0).toDouble();
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
            color: AppColors.textDark.withValues(alpha: 0.04),
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
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '#${invoiceId.length > 5 ? invoiceId.substring(0, 5) : invoiceId} • $formattedTime',
                        style: GoogleFonts.poppins(
                          color: AppColors.textLight,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(height: 4),
                      _buildPaymentBadge(paymentMethod),
                    ],
                  ),
                ),
                Text(
                  '${isCredit ? '-' : ''} Rs ${amount.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
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
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: isCredit ? Colors.orange.shade800 : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTransactionCard(dynamic txn) {
    final date = DateTime.parse(txn.createdAt).toLocal();
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
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  DateFormat('dd MMM, hh:mm a').format(date),
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          Text(
            '${isPayment ? '+' : '-'} Rs ${txn.amount.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
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
        title: Text('Settle Balance'),
        content: Text(
          'Confirm payment of Rs ${_currentCustomer.totalOutstanding.toStringAsFixed(0)} for ${_currentCustomer.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Multi-provider settlement: Clearing debt across logic layers.
              await context.read<CreditProvider>().settleFullBalance(
                _currentCustomer,
              );
              if (context.mounted) {
                // Background cache invalidation to keep the app shell consistent.
                context.read<NotificationProvider>().fetchNotifications();
                context.read<SaleProvider>().fetchSales();
                
                // Refresh dashboard statistics on Home Screen
                MainShell.homeKey.currentState?.refresh();

                SnackBarUtils.showSnackBar(
                  context,
                  'Credit settled successfully',
                );
              }
            },
            child: Text('Confirm'),
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
        title: Text('Edit Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Customer name'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(hintText: 'Phone number'),
            ),
            SizedBox(height: 12),
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
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final double? limit = double.tryParse(limitController.text);
                // Synchronous update triggering local state rebuild via Provider.
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
                    SnackBarUtils.showSnackBar(
                      context,
                      'Customer updated successfully',
                    );
                    Navigator.pop(ctx);
                  } else {
                    SnackBarUtils.showSnackBar(
                      context,
                      context.read<CreditProvider>().error ??
                          'Failed to update customer',
                      isError: true,
                    );
                  }
                }
              }
            },
            child: Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Customer'),
        content: Text(
          _currentCustomer.totalOutstanding > 0
              ? 'Warning: This customer has Rs ${_currentCustomer.totalOutstanding.toStringAsFixed(0)} outstanding credit. Are you sure you want to delete them?'
              : 'Are you sure you want to delete ${_currentCustomer.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
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
                  SnackBarUtils.showSnackBar(
                    context,
                    'Customer deleted successfully',
                  );
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Go back from detail screen
                } else {
                  SnackBarUtils.showSnackBar(
                    context,
                    context.read<CreditProvider>().error ??
                        'Failed to delete customer',
                    isError: true,
                  );
                }
              }
            },
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
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
          title: Text('Add Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'credit', label: Text('Credit')),
                  ButtonSegment(value: 'payment', label: Text('Payment')),
                ],
                selected: {type},
                onSelectionChanged: (v) => setDialogState(() => type = v.first),
              ),
              SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: 'Description'),
              ),
              SizedBox(height: 12),
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
              child: Text('Cancel'),
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

                  // Refresh dashboard statistics on Home Screen
                  MainShell.homeKey.currentState?.refresh();
                }
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

