import 'package:flutter/material.dart';
import '../models/role.dart';

class NewsPage extends StatefulWidget {
  final Role role;
  const NewsPage({super.key, required this.role});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News et Événements'),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () => setState(() => _showMap = !_showMap),
          )
        ],
      ),
      body: _showMap ? const Center(child: Text('Carte interactive ici')) : ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text('Événement ${index + 1}'),
              subtitle: const Text('Type: Culturel\nLieu: Salle des fêtes'),
              isThreeLine: true,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventDetailsPage())),
              trailing: widget.role == Role.mairie
                  ? IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _showDeleteConfirm(context))
                  : null,
            ),
          );
        },
      ),
      floatingActionButton: (widget.role == Role.association || widget.role == Role.mairie)
          ? FloatingActionButton(
        onPressed: () => _showCreateEventPopup(context),
        child: const Icon(Icons.add),
      )
          : null,
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cet événement ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _showCreateEventPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ajouter un Événement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const TextField(decoration: InputDecoration(labelText: 'Nom de l\'événement')),
            const TextField(decoration: InputDecoration(labelText: 'Tag (Sportif, Culturel...)')),
            const TextField(decoration: InputDecoration(labelText: 'Lieu')),
            const TextField(decoration: InputDecoration(labelText: 'Descriptif'), maxLines: 3),
            const TextField(decoration: InputDecoration(labelText: 'Lien de participation (optionnel)')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Créer l\'événement')),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class EventDetailsPage extends StatelessWidget {
  const EventDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détails de l\'événement')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Titre de l\'événement', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Chip(label: const Text('Culturel'), backgroundColor: Colors.purple.shade100),
            const SizedBox(height: 16),
            const Row(children: [Icon(Icons.location_on), SizedBox(width: 8), Text('Salle des fêtes, Trith-Saint-Léger')]),
            const SizedBox(height: 16),
            const Text('Description longue de l\'événement. Venez nombreux assister à ce moment unique de la vie de notre commune...'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () {}, child: const Text('Participer')),
            )
          ],
        ),
      ),
    );
  }
}