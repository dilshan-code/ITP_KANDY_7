import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/products/presentation/screens/add_product_screen.dart';
import 'package:frontend/features/products/presentation/providers/product_provider.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/credit/presentation/screens/credit_list_screen.dart';
import 'package:frontend/features/suppliers/presentation/screens/add_supplier_screen.dart';
import 'package:frontend/features/sales/presentation/screens/recent_transactions_screen.dart';
import 'package:frontend/features/sales/presentation/screens/invoice_history_screen.dart';
import 'package:frontend/shared/widgets/notification_icon.dart';
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:frontend/features/credit/presentation/providers/credit_provider.dart';
import 'package:frontend/features/suppliers/presentation/providers/supplier_provider.dart';
import 'package:frontend/features/home/presentation/utils/dashboard_pdf_utils.dart';

// The HomeScreen is the central command center for the shop owner.
// It displays a high-level summary of the business, including real-time sales,
// inventory alerts, and quick access buttons for common tasks.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    // Set up a periodic timer to refresh dashboard data every 30 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadDashboard(isSilent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboard({bool isSilent = false}) async {
    if (!isSilent) {
      setState(() => _loading = true);
    }
    try {
      // Trigger API fetch for the dashboard statistics object
      final result = await ApiClient.get('/dashboard');
      
      // Also refresh notifications and credit summaries in the background
      if (mounted) {
        context.read<NotificationProvider>().fetchNotifications();
        context.read<CreditProvider>().fetchCustomers();
        context.read<SupplierProvider>().fetchSuppliers();
      }

      // mounted checks if the widget is still on-screen before updating UI
      if (mounted) {
        // setState tells the Flutter framework to re-render this specific widget and its children
        setState(() {
          _dashboardData = result['data']; // Store the data
          _loading = false; // Turn off the loading spinner
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// Public method to trigger a refresh from parent widgets
  void refresh() {
    _loadDashboard();
  }

  Future<void> _downloadDashboardPdf() async {
    if (_dashboardData == null) return;
    
    final authProvider = context.read<AuthProvider>();
    final shopName = authProvider.currentOwner?.shopName ?? 'GreenValley Mart';
    
    await DashboardPdfUtils.generateAndDownloadDashboardSummary(
      shopName: shopName,
      dashboardData: _dashboardData!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final ownerName =
        (authProvider.currentOwner?.shopName != null &&
            authProvider.currentOwner!.shopName.isNotEmpty)
        ? authProvider.currentOwner!.shopName
        : (authProvider.currentOwner?.name ?? 'GreenValley Mart');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadDashboard,
                child: _dashboardData == null
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.7,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: AppColors.error,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Failed to load dashboard data.\nPlease check your connection.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textMedium),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _loadDashboard,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(ownerName),
                            const SizedBox(height: 24),
                            _buildStatCards(),
                            const SizedBox(height: 28),
                            _buildQuickActions(),
                            const SizedBox(height: 28),
                            _buildRecentTransactions(),
                          ],
                        ),
                      ),
              ),
      ),
    );
  }

  Widget _buildHeader(String ownerName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, $ownerName',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'CLICKBUY PARTNER',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
              onPressed: _downloadDashboardPdf,
              tooltip: 'Download Summary',
            ),
            const NotificationIcon(size: 24),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    final data = _dashboardData;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.payments_outlined,
                iconBgColor: const Color(0xFFD1FAE5),
                iconColor: AppColors.primary,
                circleBgColor: const Color(0xFFD1FAE5),
                label: "Today's Sales",
                value:
                    'Rs. ${(data?['todaysSales'] ?? 0.00).toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.inventory_2_outlined,
                iconBgColor: const Color(0xFFFEE2E2),
                iconColor: AppColors.error,
                circleBgColor: const Color(0xFFFEE2E2),
                label: 'Low Stock Items',
                value: '${data?['lowStockCount'] ?? 0} Items',
                badge: 'Alert',
                badgeBgColor: const Color(0xFFFEF2F2),
                badgeColor: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.account_balance_wallet_outlined,
                iconBgColor: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFF59E0B),
                circleBgColor: const Color(0xFFFEF3C7),
                label: 'Customer Credit',
                value:
                    'Rs. ${(data?['customerCredit'] ?? 0.00).toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.local_shipping_outlined,
                iconBgColor: const Color(0xFFDBEAFE),
                iconColor: const Color(0xFF3B82F6),
                circleBgColor: const Color(0xFFDBEAFE),
                label: 'To Suppliers',
                value:
                    'Rs. ${(data?['toSuppliers'] ?? 0.00).toStringAsFixed(2)}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _QuickActionButton(
              icon: Icons.add_box_outlined,
              label: 'Add Product',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                ).then((_) {
                  if (!mounted) return;
                  context.read<ProductProvider>().fetchProducts();
                });
              },
            ),
            _QuickActionButton(
              icon: Icons.person_add_outlined,
              label: 'Add\nCustomer',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreditListScreen()),
                );
              },
            ),
            _QuickActionButton(
              icon: Icons.local_shipping_outlined,
              label: 'Add\nSupplier',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddSupplierScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    final transactions = (_dashboardData?['recentTransactions'] as List?) ?? [];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RecentTransactionsScreen(),
                  ),
                );
              },
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < transactions.length; i++) ...[
                if (i > 0) Divider(height: 1, color: Colors.grey.shade100),
                _buildTransactionItem(transactions[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> txn) {
    final isOrder = txn['type'] == 'order';
    return InkWell(
      onTap: () {
        if (isOrder || txn['type'] == 'credit') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvoiceHistoryScreen(initialInvoiceId: txn['id']),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isOrder
                    ? const Color(0xFFD1FAE5)
                    : const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOrder ? Icons.shopping_cart_outlined : Icons.history,
                size: 18,
                color: isOrder ? AppColors.primary : const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    txn['subtitle'] ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(txn['amount'] ?? 0) >= 0 ? '+' : '-'}Rs. ${(txn['amount']?.abs() ?? 0).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isOrder ? AppColors.primary : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  txn['time'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final Color circleBgColor;
  final String label;
  final String value;
  final String? badge;
  final Color? badgeBgColor;
  final Color? badgeColor;

  const _StatCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.circleBgColor,
    required this.label,
    required this.value,
    this.badge,
    this.badgeBgColor,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -16,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: circleBgColor.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: badgeColor,
                        ),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}
