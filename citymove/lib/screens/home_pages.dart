import 'package:flutter/material.dart';
import '../models/role.dart';
import 'news_pages.dart';
import 'votes_pages.dart';
import 'admin_page.dart';

class HomeCitoyenPage extends StatelessWidget {
  final Role role;
  const HomeCitoyenPage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(role == Role.habitant ? 'Accueil Habitant' : 'Accueil Association')),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://picsum.photos/800/1200'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Card(
                  color: Colors.white70,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.wb_sunny, size: 48, color: Colors.orange),
                        Text('Trith-Saint-Léger - 18°C', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsPage(role: role))),
                  child: const Text('News de la ville', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VotesPage(role: role))),
                  child: const Text('Participer aux Votes', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeMairiePage extends StatelessWidget {
  const HomeMairiePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de Bord Mairie'), backgroundColor: Colors.deepPurple.shade200),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.event), label: const Text('Gérer les News / Événements'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsPage(role: Role.mairie))),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.how_to_vote), label: const Text('Gérer les Votes'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>  VotesPage(role: Role.mairie))),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.admin_panel_settings), label: const Text('Console d\'Administration'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminConsolePage())),
            ),
          ],
        ),
      ),
    );
  }
}