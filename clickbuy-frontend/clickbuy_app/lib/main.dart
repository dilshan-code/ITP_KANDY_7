import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAeBx9LWyDs6TT-QELPbvUwourVlgtGEPI",
      authDomain: "studio-1424340345-c4815.firebaseapp.com",
      projectId: "studio-1424340345-c4815",
      storageBucket: "studio-1424340345-c4815.firebasestorage.app",
      messagingSenderId: "922798036179",
      appId: "1:922798036179:web:c4dca78f7e590930e0b026",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClickBuy',
      theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32),
      primary: const Color(0xFF2E7D32),
      surface: Colors.white,
      background: const Color(0xFFF8FAF8),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFF2E7D32),
    elevation: 0,
  ),
),
      home: const LoginPage(),
    );
  }
}
