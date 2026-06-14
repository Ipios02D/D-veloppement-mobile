import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/role.dart';
import 'home_pages.dart';

// =============================================================================
// LoginPage — Page de connexion
//
// Flux d'authentification en deux étapes :
//   1. Firebase Auth : vérifie email + mot de passe.
//   2. Firestore     : lit le document utilisateur pour connaître le statut
//                      ('Citoyen', 'Association', 'Mairie') et en déduire le Role.
//
// Cas particulier des associations : une association dont le champ 'validee'
// est absent ou false est déconnectée immédiatement (signOut) et informée
// que son compte est en attente de validation par la mairie.
//
// Des ActionChips de test permettent de bypasser Firebase Auth en développement.
// Ils doivent être supprimés avant mise en production.
// =============================================================================
class LoginPage extends StatefulWidget {
  final Function(int, Role) onNavigate;
  const LoginPage({super.key, required this.onNavigate});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final mdpController   = TextEditingController();

  // ---------------------------------------------------------------------------
  // _seConnecter — Authentification Firebase + résolution du rôle Firestore
  //
  // Étape 1 : signInWithEmailAndPassword → lève FirebaseAuthException si
  //           les identifiants sont incorrects.
  // Étape 2 : lecture du document 'utilisateurs/{uid}' pour obtenir 'statut'.
  // Étape 3 : redirection via onNavigate(1, role) vers la page d'accueil
  //           adaptée au rôle (HomeMairiePage ou HomeCitoyenPage).
  // ---------------------------------------------------------------------------
  Future<void> _seConnecter() async {
    if (emailController.text.isEmpty || mdpController.text.isEmpty) return;

    try {
      UserCredential user = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: mdpController.text,
      );

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(user.user!.uid)
          .get();

      if (doc.exists && mounted) {
        String statut = doc['statut'];

        // Vérification de la validation pour les associations.
        // La mairie valide via AdminConsolePage (_PendingAssosTab).
        // Si non validée : signOut + SnackBar d'information.
        if (statut == 'Association') {
          bool validee = doc.data().toString().contains('validee')
              ? (doc['validee'] ?? false)
              : false;
          if (!validee) {
            await FirebaseAuth.instance.signOut();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Votre compte association est en attente de validation par la mairie.'),
              duration: Duration(seconds: 4),
            ));
            return;
          }
        }

        // Conversion statut Firestore (String) → Role Dart.
        if (statut == 'Mairie') {
          widget.onNavigate(1, Role.mairie);
        } else {
          Role userRole =
          statut == 'Association' ? Role.association : Role.habitant;
          widget.onNavigate(1, userRole);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${e.message}')));
      }
    }
  }

  // Raccourci interne utilisé par les ActionChips de test.
  void _loginAs(BuildContext context, Role role) {
    widget.onNavigate(1, role);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Connexion Citymove'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                  labelText: 'Adresse e-mail',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: mdpController,
              decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: _seConnecter,
                child: const Text('Se connecter')),
            // Navigue vers RegisterChoicePage (index 6) pour créer un compte.
            TextButton(
              onPressed: () => widget.onNavigate(6, Role.habitant),
              child: const Text('Créer un compte'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// RegisterChoicePage — Écran de choix du type de compte
//
// Écran intermédiaire simple entre la page de connexion et les formulaires
// d'inscription. Oriente vers :
//   - RegisterHabitantPage (index 7) : compte activé immédiatement.
//   - RegisterAssoPage     (index 8) : compte en attente de validation mairie.
// =============================================================================
class RegisterChoicePage extends StatelessWidget {
  final Function(int, Role) onNavigate;
  const RegisterChoicePage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
        // Retour explicite vers LoginPage plutôt que Navigator.pop,
        // car NavBarre gère la navigation par index et non par pile.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => onNavigate(0, Role.habitant),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.person),
              label: const Text('Je suis un Habitant'),
              onPressed: () => onNavigate(7, Role.habitant),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.group),
              label: const Text('Je suis une Association'),
              onPressed: () => onNavigate(8, Role.association),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// RegisterHabitantPage — Formulaire d'inscription pour un habitant
//
// Crée simultanément :
//   - Un compte Firebase Auth (email + mot de passe).
//   - Un document Firestore dans 'utilisateurs/{uid}' avec statut 'Citoyen'.
//
// Le compte est directement utilisable après création (pas de validation).
//
// Validations côté client avant tout appel réseau :
//   - Email et date de naissance obligatoires.
//   - Mots de passe identiques et d'au moins 6 caractères.
// =============================================================================
class RegisterHabitantPage extends StatefulWidget {
  final Function(int, Role) onNavigate;
  const RegisterHabitantPage({super.key, required this.onNavigate});

  @override
  State<RegisterHabitantPage> createState() => _RegisterHabitantPageState();
}

class _RegisterHabitantPageState extends State<RegisterHabitantPage> {
  final emailController           = TextEditingController();
  final mdpController             = TextEditingController();
  final mdpConfirmationController = TextEditingController();
  final dateNaissanceController   = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    mdpController.dispose();
    mdpConfirmationController.dispose();
    dateNaissanceController.dispose();
    super.dispose();
  }

  // Ouvre le sélecteur de date natif et formate le résultat en JJ/MM/AAAA.
  // La plage autorisée est 1920 → aujourd'hui pour couvrir toutes les générations.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dateNaissanceController.text =
        '${picked.day.toString().padLeft(2, '0')}/'
            '${picked.month.toString().padLeft(2, '0')}/'
            '${picked.year}';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // _creerCompteHabitant — Création du compte habitant
  //
  // Ordre des opérations :
  //   1. Validations locales (champs vides, mots de passe).
  //   2. createUserWithEmailAndPassword → crée le compte Firebase Auth.
  //   3. set() dans Firestore → enregistre le profil avec statut 'Citoyen'.
  //   4. Dialog de confirmation, puis retour à la page de connexion.
  //
  // La date de naissance est stockée en texte (JJ/MM/AAAA) pour faciliter
  // l'affichage. Elle pourra être utilisée pour la restriction d'âge des votes.
  // ---------------------------------------------------------------------------
  Future<void> _creerCompteHabitant() async {
    if (emailController.text.isEmpty ||
        dateNaissanceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Veuillez remplir tous les champs.')));
      return;
    }
    if (mdpController.text != mdpConfirmationController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Les mots de passe ne sont pas identiques.')));
      return;
    }
    if (mdpController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Le mot de passe doit contenir au moins 6 caractères')));
      return;
    }

    try {
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: mdpController.text,
      );

      String uid = userCredential.user!.uid;
      await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(uid)
          .set({
        'uid': uid,
        'email': emailController.text.trim(),
        'date_naissance': dateNaissanceController.text,
        'statut': 'Citoyen',
        'date_creation': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Compte créé !'),
            content:
            const Text('Vous pouvez maintenant vous connecter.'),
            actions: [
              TextButton(
                // popUntil(isFirst) ferme tous les écrans empilés pour
                // retourner directement à LoginPage.
                onPressed: () =>
                    Navigator.popUntil(context, (r) => r.isFirst),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${e.message}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription Habitant'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.onNavigate(0, Role.habitant),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: emailController,
            decoration: const InputDecoration(
                labelText: 'E-mail', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          // Champ en lecture seule : toute saisie passe par le DatePicker
          // pour garantir un format cohérent.
          TextField(
            controller: dateNaissanceController,
            readOnly: true,
            onTap: () => _selectDate(context),
            decoration: const InputDecoration(
              labelText: 'Date de naissance *',
              suffixIcon: Icon(Icons.calendar_today),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: mdpController,
            decoration: const InputDecoration(
                labelText: 'Mot de passe', border: OutlineInputBorder()),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: mdpConfirmationController,
            decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe',
                border: OutlineInputBorder()),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
              onPressed: _creerCompteHabitant,
              child: const Text('S\'inscrire')),
        ],
      ),
    );
  }
}

// =============================================================================
// RegisterAssoPage — Formulaire d'inscription pour une association
//
// Crée simultanément :
//   - Un compte Firebase Auth (email + mot de passe).
//   - Un document Firestore dans 'utilisateurs/{uid}' avec :
//       statut  = 'Association'
//       validee = false   ← bloque la connexion jusqu'à validation mairie
//
// Après création, l'utilisateur est immédiatement déconnecté (signOut)
// et ne pourra se connecter qu'une fois que la mairie aura passé
// 'validee' à true via l'onglet "En attente" de AdminConsolePage.
//
// Champs spécifiques aux associations :
//   - nom    : nom de l'association affiché dans la liste des événements.
//   - sujet  : domaine d'activité (culture, sport, etc.).
//   - siret  : 14 chiffres, sans espaces (InputFormatter appliqué).
// =============================================================================
class RegisterAssoPage extends StatefulWidget {
  final Function(int, Role) onNavigate;
  const RegisterAssoPage({super.key, required this.onNavigate});

  @override
  State<RegisterAssoPage> createState() => _RegisterAssoPageState();
}

class _RegisterAssoPageState extends State<RegisterAssoPage> {
  final emailController           = TextEditingController();
  final mdpController             = TextEditingController();
  final mdpConfirmationController = TextEditingController();
  final nomController             = TextEditingController();
  final sujetController           = TextEditingController();
  final siretController           = TextEditingController();

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

  // ---------------------------------------------------------------------------
  // _creerCompteAsso — Création du compte association
  //
  // Ordre des opérations :
  //   1. Validations locales (mots de passe).
  //   2. createUserWithEmailAndPassword → crée le compte Firebase Auth.
  //   3. set() dans Firestore → profil avec validee = false.
  //   4. signOut() → l'association ne peut pas encore se connecter.
  //   5. Dialog d'information, puis retour à LoginPage (index 0).
  // ---------------------------------------------------------------------------
  Future<void> _creerCompteAsso() async {
    if (mdpController.text != mdpConfirmationController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Les mots de passe ne sont pas identiques.')));
      return;
    }
    if (mdpController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Le mot de passe doit contenir au moins 6 caractères')));
      return;
    }

    try {
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: mdpController.text,
      );

      // validee = false : LoginPage refusera la connexion tant que la mairie
      // n'a pas approuvé le compte depuis AdminConsolePage (_PendingAssosTab).
      String uid = userCredential.user!.uid;
      await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(uid)
          .set({
        'uid': uid,
        'email': emailController.text.trim(),
        'nom': nomController.text,
        'sujet': sujetController.text,
        'siret': siretController.text,
        'statut': 'Association',
        'validee': false,
        'date_creation': FieldValue.serverTimestamp(),
      });

      // Déconnexion immédiate : l'association doit attendre la validation.
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Demande envoyée !'),
            content: Text(
                'L\'association ${nomController.text} a bien été enregistrée. '
                    'Votre compte sera accessible une fois validé par la mairie.'),
            actions: [
              TextButton(
                onPressed: () => widget.onNavigate(0, Role.habitant),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${e.message}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription Association'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.onNavigate(0, Role.association),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: emailController,
            decoration: const InputDecoration(
                labelText: 'E-mail', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nomController,
            decoration: const InputDecoration(
                labelText: 'Nom de l\'association',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: sujetController,
            decoration: const InputDecoration(
                labelText: 'Sujet / Domaine',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          // Champ SIRET : 14 chiffres exactement, sans espaces.
          // InputFormatters : chiffres uniquement, max 14 caractères,
          // espaces refusés (les utilisateurs ont tendance à en mettre).
          TextField(
            controller: siretController,
            decoration: const InputDecoration(
                labelText: 'Numéro SIRET',
                border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(14),
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: mdpController,
            decoration: const InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder()),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: mdpConfirmationController,
            decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe',
                border: OutlineInputBorder()),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _creerCompteAsso,
            child: const Text('Demander l\'inscription'),
          ),
        ],
      ),
    );
  }
}