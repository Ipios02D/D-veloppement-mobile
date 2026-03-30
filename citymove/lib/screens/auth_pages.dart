import 'package:flutter/material.dart';
import '../models/role.dart';
import 'home_pages.dart';

class LoginPage extends StatelessWidget {
  final Function(int,Role) onNavigate;
  LoginPage({super.key,required this.onNavigate});

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
            const TextField(decoration: InputDecoration(labelText: 'Adresse e-mail', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Mot de passe', border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () {}, child: const Text('Se connecter')),
            TextButton(
              onPressed: () => onNavigate(6,Role.habitant),
              child: const Text('Créer un compte'),
            ),
            const Divider(height: 40),
            const Text('Tester l\'application en tant que :', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                ActionChip(label: const Text('Habitant'), onPressed: () => _loginAs(context, Role.habitant)),
                ActionChip(label: const Text('Association'), onPressed: () => _loginAs(context, Role.association)),
                ActionChip(label: const Text('Mairie'), onPressed: () => _loginAs(context, Role.mairie)),
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

class RegisterHabitantPage extends StatelessWidget {
  const RegisterHabitantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription Habitant')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const TextField(decoration: InputDecoration(labelText: 'E-mail')),
          const TextField(decoration: InputDecoration(labelText: 'Mot de passe'), obscureText: true),
          const TextField(decoration: InputDecoration(labelText: 'Date de naissance (JJ/MM/AAAA)')),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), child: const Text('S\'inscrire'))
        ],
      ),
    );
  }
}

class RegisterAssoPage extends StatelessWidget {
  const RegisterAssoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription Association')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const TextField(decoration: InputDecoration(labelText: 'Nom de l\'association')),
          const TextField(decoration: InputDecoration(labelText: 'Sujet / Domaine')),
          const TextField(decoration: InputDecoration(labelText: 'Numéro SIRET')),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), child: const Text('Demander l\'inscription'))
        ],
      ),
    );
  }
}