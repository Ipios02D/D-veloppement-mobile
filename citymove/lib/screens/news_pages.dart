import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart'; // --- NOUVEAU: Pour récupérer l'ID
import '../models/role.dart';
import '../models/tag.dart';

class NewsPage extends StatefulWidget {
  final Role role;
  const NewsPage({super.key, required this.role});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  bool _showMap = false;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- NOUVEAU : Fonction pour récupérer l'ID de l'utilisateur de manière sécurisée
  String get currentUserId {
    return FirebaseAuth.instance.currentUser?.uid ?? 'id_utilisateur_test';
  }

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
      body: _showMap
          ? const Center(child: Text('Carte interactive ici'))
          : StreamBuilder<QuerySnapshot>(
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
              Map<String, dynamic> data = event.data() as Map<String, dynamic>;

              String titre = data.containsKey('nom') ? data['nom'] : '';
              String lieu = data.containsKey('lieu') ? data['lieu'] : '';
              String dateEvent = data.containsKey('date_event') ? data['date_event'] : '';
              String tagString = data.containsKey('tag') ? data['tag'] : '';
              String organisateur = data.containsKey('createur') ? data['createur'] : ''; // Correction ici

              Tag? eventTag = getTagFromString(tagString);

              // --- NOUVEAU : Vérification des droits de suppression ---
              // On peut supprimer si on est la Mairie OU si on est le créateur
              bool peutSupprimer = (widget.role == Role.mairie) || (organisateur == currentUserId);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(titre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      if (dateEvent.isNotEmpty)
                        Text('Date: $dateEvent'),

                      // J'ai corrigé $createur en $organisateur ici
                      if (organisateur.isNotEmpty)
                        Text('Organisateur ID : $organisateur', style: const TextStyle(fontSize: 12, color: Colors.grey)),

                      if (lieu.isNotEmpty)
                        Text('Lieu: $lieu'),
                      const SizedBox(height: 8),
                      if (eventTag != null)
                        Chip(
                          label: Text(eventTag.displayName, style: TextStyle(color: eventTag.color.withOpacity(0.9))),
                          backgroundColor: eventTag.color.withOpacity(0.1),
                          side: BorderSide(color: eventTag.color.withOpacity(0.5)),
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EventDetailsPage(eventId: event.id, eventData: data))
                  ),
                  trailing: peutSupprimer // --- NOUVEAU : Application de la condition
                      ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirm(context, event.id)
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
    final nomController = TextEditingController();
    final dateController = TextEditingController();
    final lieuController = TextEditingController();
    final descController = TextEditingController();
    final lienController = TextEditingController();

    Tag? selectedTag;

    bool aUnLien = false;
    bool compterParticipations = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Ajouter un Événement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    TextField(controller: nomController, decoration: const InputDecoration(labelText: 'Nom de l\'événement *')),
                    TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date de l\'événement (ex: 24/10/2024) *')),

                    DropdownButtonFormField<Tag>(
                      decoration: const InputDecoration(labelText: 'Type d\'événement (Optionnel)'),
                      value: selectedTag,
                      items: Tag.values.map((Tag tag) {
                        return DropdownMenuItem<Tag>(
                          value: tag,
                          child: Text(tag.displayName),
                        );
                      }).toList(),
                      onChanged: (Tag? newValue) {
                        setModalState(() {
                          selectedTag = newValue;
                        });
                      },
                    ),

                    TextField(controller: lieuController, decoration: const InputDecoration(labelText: 'Lieu')),
                    TextField(controller: descController, decoration: const InputDecoration(labelText: 'Descriptif'), maxLines: 3),
                    const Divider(height: 32),

                    SwitchListTile(
                      title: const Text("Ajouter un lien d'inscription"),
                      value: aUnLien,
                      onChanged: (bool value) {
                        setModalState(() {
                          aUnLien = value;
                        });
                      },
                    ),

                    if (aUnLien)
                      TextField(
                        controller: lienController,
                        decoration: const InputDecoration(labelText: 'URL (ex: https://monsite.com)'),
                        keyboardType: TextInputType.url,
                      ),

                    SwitchListTile(
                      title: const Text("Compter les clics sur 'Participer'"),
                      value: compterParticipations,
                      onChanged: (bool value) {
                        setModalState(() {
                          compterParticipations = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: () async {
                          if (nomController.text.isNotEmpty && dateController.text.isNotEmpty) {
                            await _db.collection('evenements').add({
                              'nom': nomController.text,
                              'date_event': dateController.text,
                              'tag': selectedTag?.name ?? '',
                              'lieu': lieuController.text,
                              'description': descController.text,
                              'a_un_lien': aUnLien,
                              'lien_inscription': aUnLien ? lienController.text : '',
                              'compter_participations': compterParticipations,

                              // --- NOUVEAU : On utilise un tableau vide au lieu d'un simple 0 ---
                              'participants_ids': compterParticipations ? [] : null,

                              'date_creation': FieldValue.serverTimestamp(),
                              'createur': currentUserId, // --- NOUVEAU : Sauvegarde de l'ID
                            });
                            if (context.mounted) Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Veuillez au moins remplir le nom et la date.')),
                            );
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
      ),
    );
  }
}

// --- PAGE DE DÉTAILS ---
class EventDetailsPage extends StatelessWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const EventDetailsPage({super.key, required this.eventId, required this.eventData});

  Future<void> _ouvrirLien(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Impossible de lancer $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    String titre = eventData['nom'] ?? 'Sans titre';
    String description = eventData['description'] ?? '';
    String lieu = eventData['lieu'] ?? '';
    String dateEvent = eventData['date_event'] ?? '';
    Tag? eventTag = getTagFromString(eventData['tag']);

    bool aUnLien = eventData['a_un_lien'] ?? false;
    String lienInscription = eventData['lien_inscription'] ?? '';
    bool compterParticipations = eventData['compter_participations'] ?? false;

    // --- NOUVEAU : Gestion de la liste des participants ---
    List<dynamic> participantsIds = eventData['participants_ids'] ?? [];
    int nombreParticipants = participantsIds.length;

    // On vérifie si l'utilisateur actuel est déjà dans le tableau
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'id_utilisateur_test';
    bool aDejaParticipe = participantsIds.contains(currentUserId);

    return Scaffold(
      appBar: AppBar(title: const Text('Détails de l\'événement')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titre, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            if (eventTag != null)
              Chip(
                label: Text(eventTag.displayName, style: TextStyle(color: eventTag.color.withOpacity(0.9))),
                backgroundColor: eventTag.color.withOpacity(0.1),
                side: BorderSide(color: eventTag.color.withOpacity(0.5)),
              ),

            const SizedBox(height: 16),

            if (dateEvent.isNotEmpty)
              Row(children: [const Icon(Icons.calendar_today, color: Colors.deepPurple), const SizedBox(width: 8), Text(dateEvent, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),

            if (lieu.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: [const Icon(Icons.location_on), const SizedBox(width: 8), Text(lieu, style: const TextStyle(fontSize: 16))]),
            ],

            const SizedBox(height: 24),
            if (description.isNotEmpty)
              Text(description, style: const TextStyle(fontSize: 16)),

            if (compterParticipations) ...[
              const SizedBox(height: 24),
              Text('$nombreParticipants personnes participent !', style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            ],

            const Spacer(),

            if (aUnLien || compterParticipations)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      // Si l'utilisateur a déjà cliqué, on grise le bouton
                      backgroundColor: aDejaParticipe ? Colors.grey : Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    // Si l'utilisateur a déjà participé (et qu'il n'y a pas de lien web), on désactive le bouton (null)
                    onPressed: (compterParticipations && aDejaParticipe && !aUnLien) ? null : () async {

                      // 1. Inscription dans Firebase (seulement s'il n'est pas déjà dans la liste)
                      if (compterParticipations && !aDejaParticipe) {
                        await FirebaseFirestore.instance.collection('evenements').doc(eventId).update({
                          // arrayUnion ajoute l'ID seulement s'il n'existe pas déjà
                          'participants_ids': FieldValue.arrayUnion([currentUserId]),
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Votre participation a été signalée !')));
                        }
                      }

                      // 2. S'il y a un lien, on ouvre le navigateur
                      if (aUnLien && lienInscription.isNotEmpty) {
                        _ouvrirLien(lienInscription);
                      }
                    },

                    // --- NOUVEAU : Changement du texte selon l'état ---
                    child: Text(
                        aUnLien ? 'S\'inscrire sur le site' : (aDejaParticipe ? 'Vous participez déjà' : 'Je participe !'),
                        style: const TextStyle(fontSize: 18)
                    )
                ),
              )
          ],
        ),
      ),
    );
  }
}