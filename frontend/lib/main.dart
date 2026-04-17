// ------------------------------------------------------------------------------
// File: main.dart
// Purpose: Application Entry Point and Dependency Injection Root.
// Rationale: Initializes the Flutter framework, cloud services (Firebase), 
//   and the distributed service layer (UDP discovery, API client). 
//   Orchestrates the MultiProvider tree for global state management and 
//   registers top-level error boundaries for system resilience.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // UI: Framework core
import 'package:provider/provider.dart'; // State: Dependency injection
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
import 'package:frontend/core/utils/restart_widget.dart';
import 'package:frontend/shared/widgets/global_error_widget.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/network/backend_discovery.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:frontend/firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required by Flutter to run async code in main()
  
  // Register a global error builder to provide a premium error design.
  // This replaces the default Flutter "red screen" for the entire app.
  ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
    return GlobalErrorWidget(errorDetails: errorDetails); // Use our custom premium error UI
  };

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Initialize Firebase for the correct OS
  );
  
  // Initialize dynamic API client and start local network discovery
  await ApiClient.init(); // Setup base URL from local storage or defaults
  BackendDiscovery.startDiscovery(); // Begin listening for server heatbeats (UDP)
  
  await NotificationService().initialize(); // Setup local notifications for Android/iOS
  
  // Wrap the entire application in a RestartWidget to allow for full app reloads.
  runApp(
    const RestartWidget(
      child: ClickBuyApp(), // The main application entry widget
    ),
  );
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
        title: 'ClickBuy - Shop Manager', // App title for system task switcher
        debugShowCheckedModeBanner: false, // Remove the "Debug" banner in the corner
        theme: AppTheme.lightTheme, // Apply out custom sleek light theme
        themeMode: ThemeMode.light, // Forces light mode for consistency
        home: const SplashScreen(), // The first screen shown when app starts
        
        // Final frame builder (useful for global overlay or theme scoping)
        builder: (context, widget) {
          return widget!; // Pass through the widget (screen)
        },
      ),
    );
  }
}

