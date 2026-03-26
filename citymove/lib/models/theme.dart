import 'package:flutter/material.dart';

class CityTheme {
  // Couleurs réutilisables
  static const Color primaryBlue = Color(0xFF1A5276);
  static const Color accentGreen = Color(0xFF2ECC71);

  // Thème Clair
  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryBlue,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
      secondary: accentGreen,
    ),
    scaffoldBackgroundColor: const Color(0xFFF4F7F6),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  // Thème Sombre
  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.dark,
      secondary: accentGreen,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}