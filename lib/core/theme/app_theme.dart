import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0284C7), // soft sky blue
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0EA5E9), // slightly brighter accent for dark
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF020617), // deep navy
      useMaterial3: true,
    );
  }
}
