import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/role.dart';
import 'home_pages.dart';

class LoginPage extends StatelessWidget {
  final Function(int,Role) onNavigate;
  LoginPage({super.key,required this.onNavigate});
// --- PAGE DE CONNEXION ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final mdpController = TextEditingController();

  Future<void> _seConnecter() async {
    if (emailController.text.isEmpty || mdpController.text.isEmpty) return;

    try {
      // 1. Connexion via Auth
      UserCredential user = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: mdpController.text,
      );

      // 2. Récupération du rôle dans Firestore pour rediriger vers la bonne page
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('utilisateurs').doc(user.user!.uid).get();

      if (doc.exists && mounted) {
        String statut = doc['statut'];
        if (statut == 'Mairie') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeMairiePage()));
        } else {
          Role userRole = statut == 'Association' ? Role.association : Role.habitant;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeCitoyenPage(role: userRole)));
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.message}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion Citymove'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Adresse e-mail', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: mdpController, decoration: const InputDecoration(labelText: 'Mot de passe', border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _seConnecter,
              child: const Text('Se connecter'),
            ),
            TextButton(
              onPressed: () => onNavigate(6,Role.habitant),
              child: const Text('Créer un compte'),
            ),
            const Divider(height: 40),

            // --- BOUTONS DE TEST RAPIDE (À retirer en production) ---
            const Text('Tester l\'application sans mot de passe :', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                ActionChip(label: const Text('Habitant'), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeCitoyenPage(role: Role.habitant)))),
                ActionChip(label: const Text('Association'), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeCitoyenPage(role: Role.association)))),
                ActionChip(label: const Text('Mairie'), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeMairiePage()))),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _loginAs(BuildContext context, Role role) {
      onNavigate(1,role);
  }
}

// --- CHOIX DE CRÉATION DE COMPTE ---
class RegisterChoicePage extends StatelessWidget {
  final Function(int,Role) onNavigate;
  const RegisterChoicePage({super.key,required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.person), label: const Text('Je suis un Habitant'),
              onPressed: () => onNavigate(7,Role.habitant),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.group), label: const Text('Je suis une Association'),
              onPressed: () => onNavigate(8,Role.association),
            ),
          ],
        ),
      ),
    );
  }
}

// --- INSCRIPTION HABITANT ---
class RegisterHabitantPage extends StatefulWidget {
  const RegisterHabitantPage({super.key});

  @override
  State<RegisterHabitantPage> createState() => _RegisterHabitantPageState();
}

class _RegisterHabitantPageState extends State<RegisterHabitantPage> {
  // Les contrôleurs sont placés ICI, dans le State
  final emailController = TextEditingController();
  final mdpController = TextEditingController();
  final mdpConfirmationController = TextEditingController();
  final dateNaissanceController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    mdpController.dispose();
    mdpConfirmationController.dispose();
    dateNaissanceController.dispose();
    super.dispose();
  }

  Future<void> _creerCompteHabitant() async {
    // 1. Validation issue du code de votre camarade
    if (mdpController.text != mdpConfirmationController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Les mots de passe ne sont pas identiques.')));
      return;
    } else if (mdpController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le mot de passe doit contenir au moins 6 caractères')));
      return;
    }

    try {
      // 2. Création dans Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: mdpController.text,
      );

      // 3. Sauvegarde dans Firestore
      String uid = userCredential.user!.uid;
      await FirebaseFirestore.instance.collection('utilisateurs').doc(uid).set({
        'uid': uid,
        'email': emailController.text.trim(),
        'date_naissance': dateNaissanceController.text,
        'statut': 'Citoyen',
        'date_creation': FieldValue.serverTimestamp(),
      });

      // 4. Succès
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Compte créé !'),
            content: const Text('Vous pouvez maintenant vous connecter.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), // Retour à l'accueil
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription Habitant')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: emailController, decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: dateNaissanceController, decoration: const InputDecoration(labelText: 'Date de naissance (JJ/MM/AAAA)', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: mdpController, decoration: const InputDecoration(labelText: 'Mot de passe', border: OutlineInputBorder()), obscureText: true),
          const SizedBox(height: 16),
          TextField(controller: mdpConfirmationController, decoration: const InputDecoration(labelText: 'Confirmer le mot de passe', border: OutlineInputBorder()), obscureText: true),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _creerCompteHabitant, child: const Text('S\'inscrire'))
        ],
      ),
    );
  }
}

// --- INSCRIPTION ASSOCIATION ---
class RegisterAssoPage extends StatefulWidget {
  const RegisterAssoPage({super.key});

  @override
  State<RegisterAssoPage> createState() => _RegisterAssoPageState();
}

class _RegisterAssoPageState extends State<RegisterAssoPage> {
  final emailController = TextEditingController();
  final mdpController = TextEditingController();
  final mdpConfirmationController = TextEditingController();
  final nomController = TextEditingController();
  final sujetController = TextEditingController();
  final siretController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    mdpController.dispose();
    mdpConfirmationController.dispose();
    nomController.dispose();
    sujetController.dispose();
    siretController.dispose();
    super.dispose();
  }

  Future<void> _creerCompteAsso() async {
    // 1. Validation
    if (mdpController.text != mdpConfirmationController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Les mots de passe ne sont pas identiques.')));
      return;
    } else if (mdpController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le mot de passe doit contenir au moins 6 caractères')));
      return;
    }

    try {
      // 2. Auth Firebase
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: mdpController.text,
      );

      // 3. Enregistrement Firestore (avec le SIRET de votre camarade)
      String uid = userCredential.user!.uid;
      await FirebaseFirestore.instance.collection('utilisateurs').doc(uid).set({
        'uid': uid,
        'email': emailController.text.trim(),
        'nom': nomController.text,
        'sujet': sujetController.text,
        'siret': siretController.text,
        'statut': 'Association',
        'date_creation': FieldValue.serverTimestamp(),
      });

      // 4. Succès
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Demande envoyée !'),
            content: Text('L\'association ${nomController.text} a bien été enregistrée. Vous pouvez vous connecter.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription Association')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: emailController, decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: nomController, decoration: const InputDecoration(labelText: 'Nom de l\'association', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: sujetController, decoration: const InputDecoration(labelText: 'Sujet / Domaine', border: OutlineInputBorder())),
          const SizedBox(height: 16),

          // Le champ SIRET formaté selon le code de votre camarade
          TextField(
            controller: siretController,
            decoration: const InputDecoration(labelText: 'Numéro SIRET', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(14),
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
            ],
          ),

          const SizedBox(height: 16),
          TextField(controller: mdpController, decoration: const InputDecoration(labelText: 'Mot de passe', border: OutlineInputBorder()), obscureText: true),
          const SizedBox(height: 16),
          TextField(controller: mdpConfirmationController, decoration: const InputDecoration(labelText: 'Confirmer le mot de passe', border: OutlineInputBorder()), obscureText: true),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _creerCompteAsso, child: const Text('Demander l\'inscription'))
        ],
      ),
    );
  }
}