import 'dart:ui';
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
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.8),
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
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
            ),
          ),
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
          // If already on Home and Home is tapped again, trigger refresh
          MainShell.homeKey.currentState?.refresh();
        }
        if (_currentIndex == index && index == 1) {
          // If already on Inventory and Products is tapped again, trigger refresh
          MainShell.inventoryKey.currentState?.refresh();
        }

        setState(() => _currentIndex = index);
        if (index == 0) {
          // Refresh when switching to Home tab
          MainShell.homeKey.currentState?.refresh();
        }
        if (index == 1) {
          // Refresh when switching to Products tab
          MainShell.inventoryKey.currentState?.refresh();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textLight,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
