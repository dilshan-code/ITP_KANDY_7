import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/products/presentation/providers/product_provider.dart';
import 'shared/main_shell.dart';

// main() is the starting point where the Flutter framework begins executing the app.
void main() {
  runApp(const ClickBuyApp());
}

// ClickBuyApp is the root widget of the entire application.
// It sets up global state (MultiProvider) and the basic app configuration (MaterialApp).
class ClickBuyApp extends StatelessWidget {
  const ClickBuyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider wraps the app to provide state objects (like ProductProvider)
    // so any screen deeper in the app can easily access them without passing data manually.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      // MaterialApp handles navigation structure, themes, and general app settings.
      child: MaterialApp(
        title: 'ClickBuy - Shop Manager',
        debugShowCheckedModeBanner: false, // Hides the "DEBUG" banner
        theme: AppTheme.lightTheme, // Applies our custom color/font theme
        themeMode: ThemeMode.light,
        home: const MainShell(), // The first screen shown is the bottom navigation shell
      ),
    );
  }
}
