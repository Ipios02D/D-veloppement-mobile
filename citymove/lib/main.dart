import 'package:flutter/material.dart';
// On importe le fichier qui contient la page de connexion
import 'screens/auth_pages.dart';

void main() {
  runApp(const CitymoveApp());
}

class CitymoveApp extends StatelessWidget {
  const CitymoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Citymove',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(), // On lance l'application sur la page de Login
    );
  }
}