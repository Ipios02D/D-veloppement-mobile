import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/role.dart';
import 'home_pages.dart';



class LoginPage extends StatefulWidget {
  final Function(int,Role) onNavigate;
  const LoginPage({super.key,required this.onNavigate});

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
          widget.onNavigate(1,Role.mairie);
        } else {
          Role userRole = statut == 'Association' ? Role.association : Role.habitant;
          widget.onNavigate(1,userRole);
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
              onPressed: () => widget.onNavigate(6,Role.habitant),
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
                ActionChip(label: const Text('Habitant'), onPressed: () => widget.onNavigate(1,Role.habitant)),
                ActionChip(label: const Text('Association'), onPressed: () => widget.onNavigate(1,Role.association)),
                ActionChip(label: const Text('Mairie'), onPressed: () => widget.onNavigate(1,Role.mairie)),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _loginAs(BuildContext context, Role role) {
      widget.onNavigate(1,role);
  }
}

// --- CHOIX DE CRÉATION DE COMPTE ---
class RegisterChoicePage extends StatelessWidget {
  final Function(int,Role) onNavigate;
  const RegisterChoicePage({super.key,required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => onNavigate(0, Role.habitant), // Retour à LoginPage (index 0 ou selon votre Main)
        ),
      ),
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
  final Function(int, Role) onNavigate;
  const RegisterHabitantPage({super.key, required this.onNavigate});

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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000), // Date par défaut (ex: né en 2000)
      firstDate: DateTime(1920), // Date la plus ancienne
      lastDate: DateTime.now(), // Pas de date dans le futur
    );
    if (picked != null) {
      setState(() {
        // Formate la date en JJ/MM/AAAA
        dateNaissanceController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _creerCompteHabitant() async {
    // 1. Validations
    if (emailController.text.isEmpty || dateNaissanceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez remplir tous les champs.')));
      return;
    } else if (mdpController.text != mdpConfirmationController.text) {
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
      appBar: AppBar(
        title: const Text('Inscription Habitant'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.onNavigate(0, Role.habitant), // Retour à LoginPage (index 0 ou selon votre Main)
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: emailController, decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(
            controller: dateNaissanceController,
            readOnly: true, // Empêche d'ouvrir le clavier
            onTap: () => _selectDate(context), // Ouvre le calendrier
            decoration: const InputDecoration(
              labelText: 'Date de naissance *',
              suffixIcon: Icon(Icons.calendar_today), // Icône pour indiquer qu'on peut cliquer
              border: OutlineInputBorder(),
            ),
          ),
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
  final Function(int, Role) onNavigate;
  const RegisterAssoPage({super.key, required this.onNavigate});

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

      // 3. Enregistrement Firestore
      String uid = userCredential.user!.uid;
      await FirebaseFirestore.instance.collection('utilisateurs').doc(uid).set({
        'uid': uid,
        'email': emailController.text.trim(),
        'nom': nomController.text,
        'sujet': sujetController.text,
        'siret': siretController.text,
        'statut': 'Association',
        'validee' : false,
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
      appBar: AppBar(
          title: const Text('Inscription Association'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => widget.onNavigate(0, Role.association), // Retour à LoginPage (index 0 ou selon votre Main)
          ),
      ),
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