import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/products/presentation/providers/product_provider.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/suppliers/presentation/providers/supplier_provider.dart';
import 'package:frontend/features/suppliers/presentation/providers/purchase_provider.dart';
import 'package:frontend/features/credit/presentation/providers/credit_provider.dart';
import 'package:frontend/features/sales/presentation/providers/sale_provider.dart';
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:frontend/features/auth/presentation/screens/splash_screen.dart';
import 'package:frontend/features/admin/presentation/providers/admin_provider.dart';
import 'package:frontend/features/account/presentation/providers/feedback_provider.dart';
import 'package:frontend/core/services/notification_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  runApp(const ClickBuyApp());
}

class ClickBuyApp extends StatelessWidget {
  const ClickBuyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The MultiProvider is the 'brain' of the app's state. 
    // It initializes all our Providers at once so any screen can access them.
    return MultiProvider(
      providers: [
        // Manages inventory, stock levels, and product details.
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        // Handles user login, registration, and profile state.
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Manages the list of wholesalers/suppliers.
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        // Tracks bulk stock purchases from suppliers.
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        // Manages customer loans and credit transaction history.
        ChangeNotifierProvider(create: (_) => CreditProvider()),
        // Handles the shopping cart and finalizes customer sales.
        ChangeNotifierProvider(create: (_) => SaleProvider()),
        // Manages in-app alerts (e.g., low stock notifications).
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        // Provides admin-level data (like owner lists).
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        // Manages user feedback, error reports, and improvement ideas.
        ChangeNotifierProvider(create: (_) => FeedbackProvider()),
      ],

      child: MaterialApp(
        title: 'ClickBuy - Shop Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
      ),
    );
  }
}
