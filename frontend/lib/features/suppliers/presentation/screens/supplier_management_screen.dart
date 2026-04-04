import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/utils/snackbar_utils.dart';
import 'package:frontend/features/suppliers/presentation/providers/supplier_provider.dart';
import 'package:frontend/features/suppliers/presentation/providers/purchase_provider.dart';
import 'package:frontend/features/suppliers/presentation/screens/add_supplier_screen.dart';
import 'package:frontend/features/suppliers/presentation/screens/supplier_purchase_record_screen.dart';
import 'package:frontend/features/suppliers/presentation/utils/export_utils.dart';

class SupplierManagementScreen extends StatefulWidget {
  const SupplierManagementScreen({super.key});

  @override
  State<SupplierManagementScreen> createState() =>
      _SupplierManagementScreenState();
}

class _SupplierManagementScreenState extends State<SupplierManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _purchaseScrollController = ScrollController();
  final ScrollController _supplierScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));

    _purchaseScrollController.addListener(_onPurchaseScroll);
    _supplierScrollController.addListener(_onSupplierScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SupplierProvider>().fetchSuppliers();
        context.read<PurchaseProvider>().fetchPurchases();
      }
    });
  }

  void _onPurchaseScroll() {
    if (_purchaseScrollController.position.pixels >=
        _purchaseScrollController.position.maxScrollExtent - 200) {
      context.read<PurchaseProvider>().fetchPurchases(refresh: false);
    }
  }

  void _onSupplierScroll() {
    if (_supplierScrollController.position.pixels >=
        _supplierScrollController.position.maxScrollExtent - 200) {
      context.read<SupplierProvider>().fetchSuppliers(refresh: false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _purchaseScrollController.dispose();
    _supplierScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                title: const Text('Supplier Management'),
                floating: true,
                pinned: true,
                expandedHeight: 0,
                forceElevated: innerBoxIsScrolled,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    onPressed: () {
                      if (_tabController.index == 0) {
                        final suppliers =
                            context.read<SupplierProvider>().suppliers;
                        if (suppliers.isNotEmpty) {
                          SupplierExportUtils.exportSuppliersPdf(suppliers);
                        }
                      } else {
                        final purchases =
                            context.read<PurchaseProvider>().purchases;
                        if (purchases.isNotEmpty) {
                          SupplierExportUtils.exportPurchasesPdf(purchases);
                        }
                      }
                    },
                    tooltip: 'Download PDF',
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Consumer<SupplierProvider>(
                  builder: (context, provider, _) => _buildSummaryCards(provider),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    dividerColor: Colors.transparent,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textLight,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    tabs: const [
                      Tab(text: 'Suppliers'),
                      Tab(text: 'Purchase Records'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildSuppliersTab(),
              _buildPurchaseRecordsTab(),
            ],
          ),
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              heroTag: 'fab_supplier_prod_id_unique_1',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddSupplierScreen()),
              ).then((_) {
                if (context.mounted) {
                  context.read<SupplierProvider>().fetchSuppliers();
                }
              }),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Add Supplier'),
              backgroundColor: AppColors.primary,
            )
          : FloatingActionButton.extended(
              heroTag: 'fab_purchase_prod_id_unique_2',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SupplierPurchaseRecordScreen(),
                ),
              ).then((_) {
                if (context.mounted) {
                  context.read<PurchaseProvider>().fetchPurchases();
                  context.read<SupplierProvider>().fetchSuppliers();
                }
              }),
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: const Text('Record New Purchase'),
              backgroundColor: AppColors.primary,
            ),
    );
  }

  Widget _buildSummaryCards(SupplierProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Active Suppliers',
              provider.suppliers.length.toString(),
              Icons.people_outline,
              [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Total Payable',
              'Rs ${NumberFormat('#,###').format(provider.totalPayable)}',
              Icons.account_balance_wallet_outlined,
              [Colors.green.shade600, Colors.green.shade400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    List<Color> colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuppliersTab() {
    return Consumer<SupplierProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.suppliers.isEmpty) {
          return _buildEmptyState(
            'No Suppliers',
            'Start by adding your first supplier.',
            Icons.person_add_disabled_outlined,
          );
        }
        return ListView.builder(
          controller: _supplierScrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: provider.suppliers.length + (provider.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.suppliers.length) {
              return provider.isFetchingMore
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : const SizedBox.shrink();
            }
            final supplier = provider.suppliers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person_outline,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                supplier.name,
                                style:
                                    const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                supplier.phone,
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddSupplierScreen(supplier: supplier),
                              ),
                            ).then((_) {
                              if (context.mounted) {
                                context.read<SupplierProvider>().fetchSuppliers();
                              }
                            });
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit'),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.green),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _confirmDeleteSupplier(supplier),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete'),
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPurchaseRecordsTab() {
    return Consumer<PurchaseProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.purchases.isEmpty) {
          return _buildEmptyState(
            'No Records',
            'Your purchase history will appear here.',
            Icons.receipt_outlined,
          );
        }
        return ListView.builder(
          controller: _purchaseScrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: provider.purchases.length + (provider.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.purchases.length) {
              return provider.isFetchingMore
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : const SizedBox.shrink();
            }
            final purchase = provider.purchases[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_shopping_cart_outlined,
                              color: Colors.blue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                purchase.supplierName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              Text(
                                DateFormat('MMM dd, yyyy').format(
                                    (DateTime.tryParse(purchase.purchaseDate) ??
                                            DateTime.now())
                                        .toLocal()),
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Rs ${NumberFormat('#,###').format(purchase.totalAmount)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SupplierPurchaseRecordScreen(
                                  purchase: purchase),
                            ),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit'),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.green),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _confirmDeletePurchase(purchase),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete'),
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textLight.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSupplier(dynamic supplier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text('Are you sure you want to delete ${supplier.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context
                  .read<SupplierProvider>()
                  .removeSupplier(supplier.id);
              if (context.mounted) {
                if (success) {
                  SnackBarUtils.showSnackBar(context, 'Supplier removed');
                } else {
                  SnackBarUtils.showSnackBar(
                    context,
                    context.read<SupplierProvider>().error ??
                        'Failed to remove supplier',
                    isError: true,
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePurchase(dynamic purchase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this purchase record?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context
                  .read<PurchaseProvider>()
                  .deletePurchase(purchase.id);
              if (context.mounted) {
                if (success) {
                  SnackBarUtils.showSnackBar(context, 'Record deleted');
                  context.read<SupplierProvider>().fetchSuppliers();
                } else {
                  SnackBarUtils.showSnackBar(
                    context,
                    context.read<PurchaseProvider>().error ??
                        'Failed to delete record',
                    isError: true,
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}


  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
