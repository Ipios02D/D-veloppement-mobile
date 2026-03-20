import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/auth_pages.dart';

void main() async {
  // 1. S'assurer que les widgets Flutter sont liés avant d'initialiser Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialisation de Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Lancement de l'application
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
      home: const LoginPage(),
    );
  }
}