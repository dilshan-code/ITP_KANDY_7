// refactor bottom navigation bar into custom floating design
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

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      if (index == 0) MainShell.homeKey.currentState?.refresh();
      if (index == 1) MainShell.inventoryKey.currentState?.refresh();
      return;
    }

    setState(() => _currentIndex = index);
    if (index == 0) MainShell.homeKey.currentState?.refresh();
    if (index == 1) MainShell.inventoryKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true, // Crucial for glassmorphism to show content behind
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildPremiumNavbar(),
    );
  }

  Widget _buildPremiumNavbar() {
    const double barHeight = 72;
    const double horizontalPadding = 20;
    const double bottomMargin = 24;

    return Container(
      height: barHeight + MediaQuery.of(context).padding.bottom + bottomMargin,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        10,
        horizontalPadding,
        MediaQuery.of(context).padding.bottom + bottomMargin,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double itemWidth = constraints.maxWidth / 5;
                return Stack(
                  children: [
                    // Sliding Indicator Background
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                      left: _currentIndex * itemWidth + 6,
                      top: 6,
                      bottom: 6,
                      child: Container(
                        width: itemWidth - 12,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Nav Items Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                        _buildNavItem(1, Icons.inventory_2_outlined, Icons.inventory_2, 'Products'),
                        _buildNavItem(2, Icons.shopping_cart_outlined, Icons.shopping_cart, 'Sales'),
                        _buildNavItem(3, Icons.people_outline, Icons.people, 'Credit'),
                        _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile'),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final bool isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isActive ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? Colors.white : AppColors.textMedium,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.white : AppColors.textMedium,
                letterSpacing: 0.2,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

