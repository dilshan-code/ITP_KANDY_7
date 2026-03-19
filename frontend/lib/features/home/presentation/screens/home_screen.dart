import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../products/presentation/screens/add_product_screen.dart';
import '../../../products/presentation/providers/product_provider.dart';

// HomeScreen is the first screen the user sees after opening the app.
// It serves as a dashboard showing today's sales, low stock alerts,
// clear actions (like 'Add Product'), and recent transactions.
// It fetches this data from the backend API '/dashboard'.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      // Trigger API fetch for the dashboard statistics object
      final result = await ApiClient.get('/dashboard');
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
        // Turn off spinner even if it failed so the user isn't stuck waiting forever
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadDashboard,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildStatCards(),
                      const SizedBox(height: 28),
                      _buildQuickActions(),
                      const SizedBox(height: 28),
                      _buildRecentTransactions(),
                      const SizedBox(height: 20),
                      _buildWeeklyInsight(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final dateStr = '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateStr,
              style: const TextStyle(fontSize: 14, color: AppColors.textMedium, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hi, GreenValley Mart',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
            const SizedBox(height: 2),
            const Text(
              'CLICKBUY PARTNER',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary, letterSpacing: 1.2),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Stack(
            children: [
              const Icon(Icons.notifications_outlined, color: AppColors.textMedium, size: 24),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
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
                value: '\$${(data?['todaysSales'] ?? 1240.50).toStringAsFixed(2)}',
                badge: '↗ ${data?['salesTrend'] ?? 12}%',
                badgeBgColor: const Color(0xFFECFDF5),
                badgeColor: const Color(0xFF059669),
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
                value: '${data?['lowStockCount'] ?? 8} Items',
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
                value: '\$${(data?['customerCredit'] ?? 345.00).toStringAsFixed(2)}',
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
                value: '\$${(data?['toSuppliers'] ?? 890.00).toStringAsFixed(2)}',
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
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            TextButton(
              onPressed: () {},
              child: const Text('Edit', style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _QuickActionButton(
              icon: Icons.point_of_sale,
              label: 'New Sale',
              isPrimary: true,
              onTap: () {},
            ),
            _QuickActionButton(
              icon: Icons.add_box_outlined,
              label: 'Add Product',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                ).then((_) {
                  context.read<ProductProvider>().fetchProducts();
                });
              },
            ),
            _QuickActionButton(
              icon: Icons.person_add_outlined,
              label: 'Add\nCustomer',
              onTap: () {},
            ),
            _QuickActionButton(
              icon: Icons.local_shipping_outlined,
              label: 'Add\nSupplier',
              onTap: () {},
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
            const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            TextButton(
              onPressed: () {},
              child: const Text('See all', style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 4)),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isOrder ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
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
                Text(txn['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(txn['subtitle'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+\$${(txn['amount'] ?? 0).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isOrder ? AppColors.primary : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(txn['time'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyInsight() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF0D9488)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Insight',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sales up by 15%\nthis week!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'View Report',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.insights, size: 48, color: Colors.white70),
            ],
          ),
        ],
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 4)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: badgeColor),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMedium, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
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
  final bool isPrimary;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    this.isPrimary = false,
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
              color: isPrimary ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: isPrimary ? null : Border.all(color: Colors.grey.shade200),
              boxShadow: isPrimary
                  ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
            ),
            child: Icon(icon, color: isPrimary ? Colors.white : AppColors.primary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMedium),
          ),
        ],
      ),
    );
  }
}
