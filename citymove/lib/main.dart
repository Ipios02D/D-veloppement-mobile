import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Import de vos pages et de votre thème
import 'screens/auth_pages.dart';
import 'models/theme.dart'; // Fichier contenant CityTheme que nous allons créer

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CitymoveApp());
}

class CitymoveApp extends StatefulWidget {
  const CitymoveApp({super.key});

  @override
  State<CitymoveApp> createState() => _CitymoveAppState();
}

class _CitymoveAppState extends State<CitymoveApp> {
  // Gestion de l'état du thème (Clair par défaut)
  ThemeMode _themeMode = ThemeMode.light;

  // Fonction pour basculer le thème
  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Citymove',
      debugShowCheckedModeBanner: false,

      // --- CONFIGURATION DU THÈME ---
      theme: CityTheme.light,
      darkTheme: CityTheme.dark,
      themeMode: _themeMode,

      // On passe les paramètres du thème à notre première page (LoginPage)
      home: LoginPage(
        isDarkMode: _themeMode == ThemeMode.dark,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}