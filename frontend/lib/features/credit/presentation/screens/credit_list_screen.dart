// ------------------------------------------------------------------------------
// File: credit_list_screen.dart
// Purpose: Dual-purpose CRM and Credit Selection Interface.
// Rationale: Serves as the central repository for customer relationship
//   management, supporting standalone profile administration (Add/Edit/Delete)
//   and real-time debtor identification. Operates in 'Selection Mode' for
//   POS checkout flows and provides deep-link navigation to customer ledgers.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // UI: Flutter Material widgets
import 'package:google_fonts/google_fonts.dart'; // UI: Poppins typography
import 'package:provider/provider.dart'; // State: Provider read/watch
import 'package:frontend/core/theme/app_colors.dart'; // Theme: Brand colour tokens
import 'package:frontend/core/utils/snackbar_utils.dart'; // UX: Feedback toasts with diagnostics
import 'package:frontend/features/credit/presentation/providers/credit_provider.dart'; // State: Customer data manager
import 'package:frontend/features/credit/domain/entities/customer.dart'; // Domain: Customer model
import 'package:frontend/features/credit/presentation/screens/credit_detail_screen.dart'; // Navigation: Customer ledger
import 'package:frontend/features/credit/presentation/utils/export_utils.dart'; // PDF: Batch credit export
import 'package:frontend/shared/widgets/modern_pdf_icon.dart'; // UI: Brand-consistent PDF trigger icon
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart'; // State: Identity management
import 'package:frontend/shared/widgets/screen_header.dart'; // UI: Reusable page header

/// CreditListScreen: A dual-purpose screen for managing customer credit.
/// Works as both a standalone CRM view and a selection picker for the checkout flow.
class CreditListScreen extends StatefulWidget {
  final bool isSelectionMode;

  const CreditListScreen({super.key, this.isSelectionMode = false});

  @override
  State<CreditListScreen> createState() => _CreditListScreenState();
}

class _CreditListScreenState extends State<CreditListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initial data load on mount.
      if (mounted) context.read<CreditProvider>().fetchCustomers();
    });
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Pagination trigger when reaching the 200px threshold from bottom.
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<CreditProvider>().fetchCustomers(refresh: false);
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handlePdfExport(BuildContext context) {
    final provider = context.read<CreditProvider>();
    final owner = context.read<AuthProvider>().currentOwner;
    // Branching export logic based on active tab view.
    if (_tabController.index == 0) {
      final outstanding = provider.outstandingCustomers;
      if (outstanding.isNotEmpty) {
        CreditExportUtils.exportActiveCreditsPdf(outstanding, owner: owner);
      } else {
        SnackBarUtils.showSnackBar(context, 'No active credit users to export');
      }
    } else {
      final settled = provider.settledCustomers;
      if (settled.isNotEmpty) {
        CreditExportUtils.exportSettledCreditsPdf(settled, owner: owner);
      } else {
        SnackBarUtils.showSnackBar(context, 'No settled customers to export');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ScreenHeader(
                  title: 'Customer Credit',
                  showBackButton:
                      widget.isSelectionMode || Navigator.canPop(context),
                  onBack: () => Navigator.pop(context),
                  action: const ModernPdfIcon(),
                  onActionTap: () => _handlePdfExport(context),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textDark.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMedium,
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  tabs: [
                    Tab(
                      text: 'Credit Users',
                    ), // Displaying customers with active liabilities
                    Tab(
                      text: 'Settled / Paid',
                    ), // Displaying customers with zero balances
                  ],
                ),
              ),
              Expanded(
                child: Consumer<CreditProvider>(
                  builder: (context, provider, _) {
                    // Auto-trigger: Opens the "Add New Customer" dialog if signaled from the Home screen.
                    if (provider.shouldOpenAddCustomer) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _showAddCustomerDialog(context);
                          provider.setShouldOpenAddCustomer(false);
                        }
                      });
                    }
                    // Guard: Initial data retrieval state
                    if (provider.isLoading && provider.customers.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Filtering Logic: Dynamic search across name and phone fields
                    final outstanding = provider.outstandingCustomers.where((
                      c,
                    ) {
                      return c.name.toLowerCase().contains(_searchQuery) ||
                          c.phone.toLowerCase().contains(_searchQuery);
                    }).toList();

                    final settled = provider.settledCustomers.where((c) {
                      return c.name.toLowerCase().contains(_searchQuery) ||
                          c.phone.toLowerCase().contains(_searchQuery);
                    }).toList();

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCustomerList(
                          context,
                          provider,
                          outstanding,
                          'No active credit users',
                        ),
                        _buildCustomerList(
                          context,
                          provider,
                          settled,
                          'No settled customers yet',
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'credit_add_customer_btn',
          onPressed: () =>
              _showAddCustomerDialog(context), // Registration entry point
          backgroundColor: AppColors.primary,
          child: Icon(Icons.person_add, color: Colors.white),
        ),
        bottomNavigationBar: const SizedBox(
          height: 110,
        ), // Buffer to clear the floating navbar in MainShell
      ),
    );
  }

  Widget _buildCustomerList(
    BuildContext context,
    CreditProvider provider,
    List<Customer> customers,
    String emptyMessage,
  ) {
    return Column(
      children: [
        if (emptyMessage == 'No active credit users')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildSummaryCard(context),
          ),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search customers...',
              prefixIcon: Icon(Icons.search, color: AppColors.textLight),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: provider.fetchCustomers,
            color: AppColors.primary,
            child: customers.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.5,
                      alignment: Alignment.center,
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
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: AppColors.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 180),
                    itemCount:
                        customers.length + (provider.hasMoreCustomers ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == customers.length) {
                        return provider.isFetchingMoreCustomers
                            ? Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox.shrink();
                      }
                      final customer = customers[index];
                      return GestureDetector(
                        onTap: () {
                          // Routing logic based on app context (Sales selection vs CRM view)
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
                              // Conditional refresh on return to ensure data consistency
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
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        customer.totalOutstanding > 0
                                        ? AppColors
                                              .accentGreen // Alert color for debtors
                                        : Colors
                                              .blue
                                              .shade50, // Neutral color for clear accounts
                                    child: Text(
                                      customer.name.isNotEmpty
                                          ? customer.name[0]
                                                .toUpperCase() // Initial-based avatar
                                          : '?',
                                      style: GoogleFonts.poppins(
                                        color: customer.totalOutstanding > 0
                                            ? AppColors.primary
                                            : Colors.blue,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Customer Identity: Displays name and real-time balance
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          customer
                                              .name, // The registered buyer name
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          customer.totalOutstanding > 0
                                              ? 'Rs ${customer.totalOutstanding.toStringAsFixed(0)} active credit'
                                              : 'All clear / Paid', // UX: Positive reinforcement for clear accounts
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: customer.totalOutstanding > 0
                                                ? AppColors.textMedium
                                                : AppColors.primary,
                                            fontWeight:
                                                customer.totalOutstanding > 0
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
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(
                                height: 1,
                                color: Color(0xFFF1F5F9),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _showEditCustomerDialog(
                                      context,
                                      customer,
                                    ),
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'Edit',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.green.shade700,
                                      backgroundColor: Colors.green.shade50,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => _showDeleteConfirmation(
                                      context,
                                      customer,
                                    ),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'Delete',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red.shade700,
                                      backgroundColor: Colors.red.shade50,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Edit Customer',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogField(
              controller: nameController,
              label: 'Customer Name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildDialogField(
              controller: phoneController,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildDialogField(
              controller: limitController,
              label: 'Credit Limit',
              icon: Icons.account_balance_wallet_outlined,
              prefixText: 'Rs ',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppColors.textMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final double? limit = double.tryParse(limitController.text);
                final success = await Provider.of<CreditProvider>(
                  context,
                  listen: false,
                ).updateCustomer(customer.id, {
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'creditLimit': limit ?? customer.creditLimit,
                });
                if (context.mounted) {
                  if (success) {
                    SnackBarUtils.showSnackBar(
                      context,
                      'Customer updated successfully',
                    );
                    Navigator.pop(ctx);
                  } else {
                    final creditProvider = context.read<CreditProvider>();
                    SnackBarUtils.showSnackBar(
                      context,
                      creditProvider.error ?? 'Failed to update customer',
                      isError: true,
                      technicalDetails: creditProvider.technicalDetails,
                    );
                  }
                }
              }
            },
            child: Text(
              'Update',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? prefixText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
        prefixText: prefixText,
        labelStyle: GoogleFonts.poppins(color: AppColors.textMedium),
        filled: true,
        fillColor: Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Customer'),
        content: Text(
          // Conditional warning for active liabilities
          customer.totalOutstanding > 0
              ? 'Warning: This customer has Rs ${customer.totalOutstanding.toStringAsFixed(0)} active credit. Are you sure you want to delete them?'
              : 'Are you sure you want to delete ${customer.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
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
                  SnackBarUtils.showSnackBar(
                    context,
                    'Customer deleted successfully',
                  );
                  Navigator.pop(ctx);
                } else {
                  final creditProvider = context.read<CreditProvider>();
                  SnackBarUtils.showSnackBar(
                    context,
                    creditProvider.error ?? 'Failed to delete customer',
                    isError: true,
                    technicalDetails: creditProvider.technicalDetails,
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final provider = context.watch<CreditProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                  'Total Active Credit', // Aggregate system liability
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Rs ${provider.totalOutstanding.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
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
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Active',
                  style: GoogleFonts.poppins(
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Add New Customer',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogField(
              controller: nameController,
              label: 'Customer Name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildDialogField(
              controller: phoneController,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildDialogField(
              controller: limitController,
              label: 'Credit Limit',
              icon: Icons.account_balance_wallet_outlined,
              prefixText: 'Rs ',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppColors.textMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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
                    SnackBarUtils.showSnackBar(
                      context,
                      'Customer added successfully',
                    );
                    Navigator.pop(ctx);
                  } else if (ctx.mounted) {
                    final creditProvider = context.read<CreditProvider>();
                    SnackBarUtils.showSnackBar(
                      context,
                      creditProvider.error ?? 'Failed to add customer',
                      isError: true,
                      technicalDetails: creditProvider.technicalDetails,
                    );
                  }
                }
              }
            },
            child: Text(
              'Add Customer',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
