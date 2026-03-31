// refactor bottom navigation bar into custom floating design
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:frontend/features/home/presentation/screens/home_screen.dart';
import 'package:frontend/features/products/presentation/screens/inventory_screen.dart';
import 'package:frontend/features/sales/presentation/screens/new_sale_screen.dart';
import 'package:frontend/features/credit/presentation/screens/credit_list_screen.dart';
import 'package:frontend/features/account/presentation/screens/account_screen.dart';

class MainShell extends StatefulWidget {
  static final GlobalKey<HomeScreenState> homeKey =
      GlobalKey<HomeScreenState>();
  static final GlobalKey<InventoryScreenState> inventoryKey =
      GlobalKey<InventoryScreenState>();
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationProvider>().fetchNotifications();
    });
  }

  final List<Widget> _screens = [
    HomeScreen(key: MainShell.homeKey),
    InventoryScreen(key: MainShell.inventoryKey),
    const NewSaleScreen(),
    const CreditListScreen(),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows content to appear behind the floating bar
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        height: 80,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
            _buildNavItem(
              1,
              Icons.inventory_2_outlined,
              Icons.inventory_2,
              'Products',
            ),
            _buildNavItem(
              2,
              Icons.shopping_cart_outlined,
              Icons.shopping_cart,
              'Cart',
            ),
            _buildNavItem(
              3,
              Icons.people_outline,
              Icons.people,
              'Credit',
            ),
            _buildNavItem(
              4,
              Icons.person_outline,
              Icons.person,
              'Account',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (_currentIndex == index && index == 0) {
          MainShell.homeKey.currentState?.refresh();
        }
        if (_currentIndex == index && index == 1) {
          MainShell.inventoryKey.currentState?.refresh();
        }

        setState(() => _currentIndex = index);
        if (index == 0) MainShell.homeKey.currentState?.refresh();
        if (index == 1) MainShell.inventoryKey.currentState?.refresh();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : Colors.white.withValues(alpha: 0.8),
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
