import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/utils/snackbar_utils.dart';
import 'package:frontend/features/credit/presentation/providers/credit_provider.dart';
import 'package:frontend/features/credit/domain/entities/customer.dart';
import 'package:frontend/features/credit/presentation/screens/credit_detail_screen.dart';
import 'package:frontend/features/credit/presentation/utils/export_utils.dart';

class CreditListScreen extends StatefulWidget {
  final bool isSelectionMode;

  const CreditListScreen({super.key, this.isSelectionMode = false});

  @override
  State<CreditListScreen> createState() => _CreditListScreenState();
}

class _CreditListScreenState extends State<CreditListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CreditProvider>().fetchCustomers();
    });
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customer Credit'),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () {
                final outstanding = context.read<CreditProvider>().outstandingCustomers;
                if (outstanding.isNotEmpty) {
                  CreditExportUtils.exportActiveCreditsPdf(outstanding);
                }
              },
              tooltip: 'Download PDF',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMedium,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'Credit Users'),
                  Tab(text: 'Settled / Paid'),
                ],
              ),
            ),
          ),
        ),
        body: Consumer<CreditProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.customers.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final outstanding = provider.outstandingCustomers.where((c) {
              return c.name.toLowerCase().contains(_searchQuery) ||
                  c.phone.toLowerCase().contains(_searchQuery);
            }).toList();

            final settled = provider.settledCustomers.where((c) {
              return c.name.toLowerCase().contains(_searchQuery) ||
                  c.phone.toLowerCase().contains(_searchQuery);
            }).toList();

            return TabBarView(
              children: [
                _buildCustomerList(
                  context,
                  outstanding,
                  'No active credit users',
                ),
                _buildCustomerList(
                  context,
                  settled,
                  'No settled customers yet',
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'credit_add_customer_btn',
          onPressed: () => _showAddCustomerDialog(context),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.person_add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCustomerList(
    BuildContext context,
    List<Customer> customers,
    String emptyMessage,
  ) {
    return Column(
      children: [
        if (emptyMessage == 'No active credit users')
          _buildSummaryCard(context),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search customers...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: customers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        emptyMessage,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return GestureDetector(
                      onTap: () {
                        if (widget.isSelectionMode) {
                          Navigator.pop(context, customer);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CreditDetailScreen(customer: customer),
                            ),
                          ).then((_) {
                            if (context.mounted) {
                              context.read<CreditProvider>().fetchCustomers();
                            }
                          });
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: customer.totalOutstanding > 0
                                  ? AppColors.accentGreen
                                  : Colors.blue.shade50,
                              child: Text(
                                customer.name.isNotEmpty
                                    ? customer.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: customer.totalOutstanding > 0
                                      ? AppColors.primary
                                      : Colors.blue,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    customer.totalOutstanding > 0
                                        ? 'Rs ${customer.totalOutstanding.toStringAsFixed(0)} active credit'
                                        : 'All clear / Paid',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: customer.totalOutstanding > 0
                                          ? AppColors.textMedium
                                          : AppColors.primary,
                                      fontWeight: customer.totalOutstanding > 0
                                          ? FontWeight.normal
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildStatusBadge(
                              customer.totalOutstanding,
                              customer.creditLimit,
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: AppColors.textLight,
                              ),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditCustomerDialog(context, customer);
                                } else if (value == 'delete') {
                                  _showDeleteConfirmation(context, customer);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 18),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: AppColors.error,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showEditCustomerDialog(BuildContext context, Customer customer) {
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone);
    final limitController = TextEditingController(
      text: customer.creditLimit.toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
                    ).updateCustomer(customer.id, {
                      'name': nameController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'creditLimit': limit ?? customer.creditLimit,
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
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          customer.totalOutstanding > 0
              ? 'Warning: This customer has Rs ${customer.totalOutstanding.toStringAsFixed(0)} active credit. Are you sure you want to delete them?'
              : 'Are you sure you want to delete ${customer.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final success = await Provider.of<CreditProvider>(
                context,
                listen: false,
              ).deleteCustomer(customer.id);
              if (context.mounted) {
                if (success) {
                  SnackBarUtils.showTopSnackBar(
                    context,
                    'Customer deleted successfully',
                  );
                  Navigator.pop(ctx);
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

  Widget _buildSummaryCard(BuildContext context) {
    final provider = context.watch<CreditProvider>();
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Active Credit',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rs ${provider.totalOutstanding.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  provider.activeCredits.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(double outstanding, double limit) {
    String text;
    Color color;
    if (outstanding <= 0) {
      text = 'Paid';
      color = AppColors.primary;
    } else if (outstanding >= limit) {
      text = 'At Limit';
      color = AppColors.error;
    } else {
      text = 'Active';
      color = AppColors.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final limitController = TextEditingController(text: '5000');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
                final newCustomerRef = {
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'creditLimit': limit ?? 5000.0,
                };
                final success = await Provider.of<CreditProvider>(
                  context,
                  listen: false,
                ).addCustomer(newCustomerRef);
                if (context.mounted) {
                  if (success) {
                    SnackBarUtils.showTopSnackBar(
                      context,
                      'Customer added successfully',
                    );
                    Navigator.pop(ctx);
                  } else if (ctx.mounted) {
                    SnackBarUtils.showTopSnackBar(
                      context,
                      context.read<CreditProvider>().error ??
                          'Failed to add customer',
                      isError: true,
                    );
                  }
                }

                if (widget.isSelectionMode) {
                  // Refresh and return the newly created customer (they will be at the end or we can fetch them)
                  // It's easier just to pop back the map (simulating a customer) or
                  // pop nothing and let user select from list (simplest for now).
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
