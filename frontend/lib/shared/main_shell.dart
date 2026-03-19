import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/products/presentation/screens/inventory_screen.dart';

// MainShell acts as the container providing the permanent bottom navigation bar.
// It keeps the selected screens (Home, Products, etc.) in an 'IndexedStack', 
// meaning they stay alive in memory (don't reload) when switching tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Keeps track of the currently selected tab (0 = Home)
  int _currentIndex = 0;

  // The list of screens mapping to each tab
  final List<Widget> _screens = [
    const HomeScreen(),
    const InventoryScreen(),
    const _PlaceholderScreen(title: 'Sales', icon: Icons.receipt_outlined),
    const _PlaceholderScreen(title: 'Credit', icon: Icons.people_outline),
    const _PlaceholderScreen(title: 'Account', icon: Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack shows only one child (based on index) but preserves state of all others
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // The custom built bottom navigation bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                _buildNavItem(1, Icons.inventory_2_outlined, Icons.inventory_2, 'Products'),
                _buildNavItem(2, Icons.receipt_outlined, Icons.receipt, 'Sales'),
                _buildNavItem(3, Icons.people_outline, Icons.people, 'Credit'),
                _buildNavItem(4, Icons.person_outline, Icons.person, 'Account'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build individual navigation buttons
  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    // ... (rest of implementation)
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? AppColors.primary : AppColors.textLight,
                size: 26,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.textLight),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
