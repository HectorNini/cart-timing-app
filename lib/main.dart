import 'package:cart_timing_app/screens/heat_list_screen.dart';
import 'package:flutter/material.dart';
import 'theme/f1_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cart Timing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: F1.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: F1.accent,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: F1.panel,
          foregroundColor: Colors.white,
        ),
      ),
      home: const HeatListScreen(),
    );
  }
}
