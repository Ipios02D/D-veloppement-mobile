import 'package:flutter/material.dart';

void main() {
  runApp(const MonApp());
}

class MonApp extends StatelessWidget {
  const MonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mon Application',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AccueilPage(),
    );
  }
}

// --- PAGE D'ACCUEIL ---
class AccueilPage extends StatelessWidget {
  const AccueilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Widget Météo (Données simulées)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.lightBlue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(Icons.wb_sunny, size: 64, color: Colors.orange),
                    SizedBox(height: 12),
                    Text(
                      'Trith-Saint-Léger',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '18°C - Ensoleillé',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // 2. Bouton Sondages
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SondagesPage()),
                );
              },
              icon: const Icon(Icons.poll, size: 28),
              label: const Text('Liste des Sondages', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Bouton Événements
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EvenementsPage()),
                );
              },
              icon: const Icon(Icons.event, size: 28),
              label: const Text('Liste des Événements', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- PAGE DES SONDAGES ---
class SondagesPage extends StatelessWidget {
  const SondagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sondages'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        itemCount: 8, // Nombre de sondages simulés
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.shade100,
              child: const Icon(Icons.question_mark, color: Colors.deepPurple),
            ),
            title: Text('Sondage #${index + 1}'),
            subtitle: const Text('Appuyez pour participer à ce sondage...'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Action lors du clic sur un sondage
            },
          );
        },
      ),
    );
  }
}

// --- PAGE DES ÉVÉNEMENTS ---
class EvenementsPage extends StatefulWidget {
  const EvenementsPage({super.key});

  @override
  State<EvenementsPage> createState() => _EvenementsPageState();
}

class _EvenementsPageState extends State<EvenementsPage> {
  // Variable d'état pour basculer entre la liste et la carte
  bool _afficherCarte = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Le bouton qui permet de basculer la vue
          IconButton(
            icon: Icon(_afficherCarte ? Icons.list : Icons.map),
            tooltip: _afficherCarte ? 'Voir la liste' : 'Voir la carte',
            onPressed: () {
              setState(() {
                _afficherCarte = !_afficherCarte; // Inverse l'état
              });
            },
          ),
        ],
      ),
      // Affiche soit la carte, soit la liste en fonction de l'état
      body: _afficherCarte ? _construireCarte() : _construireListe(),
    );
  }

  // --- Vue Liste ---
  Widget _construireListe() {
    return ListView.builder(
      itemCount: 6, // Nombre d'événements simulés
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.location_on, color: Colors.redAccent, size: 32),
            title: Text('Événement #${index + 1}'),
            subtitle: Text('Lieu: Salle des fêtes\nDate: le ${10 + index} du mois à 20h00'),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  // --- Vue Carte (Simulée) ---
  Widget _construireCarte() {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade300,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 120, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'L\'intégration Google Maps\nou OpenStreetMap ira ici.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}