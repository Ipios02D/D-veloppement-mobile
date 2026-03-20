import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/role.dart';

class NewsPage extends StatefulWidget {
  final Role role;
  const NewsPage({super.key, required this.role});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  bool _showMap = false;

  // Instance de Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
      // Remplacement de la ListView par le StreamBuilder
      body: _showMap ? const Center(child: Text('Carte interactive ici')) : StreamBuilder<QuerySnapshot>(
        stream: _db.collection('evenements').orderBy('date_creation', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Erreur de chargement"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("Aucun événement pour le moment."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var event = docs[index];

              // Sécurisation de la récupération des champs (au cas où ils sont vides)
              String titre = event.data().toString().contains('nom') ? event['nom'] : 'Sans titre';
              String lieu = event.data().toString().contains('lieu') ? event['lieu'] : 'Lieu non précisé';
              String tag = event.data().toString().contains('tag') ? event['tag'] : 'Général';

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(titre),
                  subtitle: Text('Type: $tag\nLieu: $lieu'),
                  isThreeLine: true,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventDetailsPage())),
                  trailing: widget.role == Role.mairie
                      ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirm(context, event.id) // On passe l'ID du document
                  )
                      : null,
                ),
              );
            },
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

  void _showDeleteConfirm(BuildContext context, String documentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cet événement ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
              onPressed: () {
                // Suppression réelle dans Firestore
                _db.collection('evenements').doc(documentId).delete();
                Navigator.pop(context);
              },
              child: const Text('Supprimer', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  void _showCreateEventPopup(BuildContext context) {
    // Contrôleurs pour récupérer le texte des champs
    final nomController = TextEditingController();
    final tagController = TextEditingController();
    final lieuController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ajouter un Événement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            TextField(controller: nomController, decoration: const InputDecoration(labelText: 'Nom de l\'événement')),
            TextField(controller: tagController, decoration: const InputDecoration(labelText: 'Tag (Sportif, Culturel...)')),
            TextField(controller: lieuController, decoration: const InputDecoration(labelText: 'Lieu')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Descriptif'), maxLines: 3),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () async {
                  // Ajout réel dans Firestore
                  if (nomController.text.isNotEmpty) {
                    await _db.collection('evenements').add({
                      'nom': nomController.text,
                      'tag': tagController.text,
                      'lieu': lieuController.text,
                      'description': descController.text,
                      'date_creation': FieldValue.serverTimestamp(),
                    });
                    if (context.mounted) Navigator.pop(context); // Ferme la popup
                  }
                },
                child: const Text('Créer l\'événement')
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ... Gardez la classe EventDetailsPage que vous aviez déjà en dessous
class EventDetailsPage extends StatelessWidget {
  const EventDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détails de l\'événement')),
      body: const Center(child: Text("Détails à relier à Firestore")),
    );
  }
}