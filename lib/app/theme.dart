import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6B4BFF),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }
}
