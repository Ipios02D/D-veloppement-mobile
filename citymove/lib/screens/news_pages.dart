import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/role.dart';
import '../main.dart';
import '../models/tag.dart';
import 'event_details_popup.dart';

// =============================================================================
// NewsPage — Liste des événements en temps réel
//
// Affiche tous les documents de la collection "evenements" Firestore,
// triés par date de création décroissante.
//
// Accès selon le rôle :
//   - habitant    : lecture seule, pas de bouton de création ni de suppression.
//   - association : peut créer ses propres événements et les supprimer.
//   - mairie      : peut créer et supprimer tous les événements.
//
// Le bouton carte (AppBar) navigue vers la MapScreen via onNavigate(2, role).
// =============================================================================
class NewsPage extends StatefulWidget {
  final Role role;
  final Function(int, Role) onNavigate;
  const NewsPage({super.key, required this.role, required this.onNavigate});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  bool _showMap = false;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get currentUserId {
    return FirebaseAuth.instance.currentUser?.uid ?? 'id_utilisateur_test';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News et Événements'),
        actions: [
          // Icône de bascule vers la carte. Navigue via onNavigate plutôt que
          // de changer _showMap localement, car MapScreen est une page à part
          // entière gérée par NavBarre dans main.dart.
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () => widget.onNavigate(2, widget.role),
          )
        ],
      ),
      body: _showMap
          ? const Center(child: Text('Carte interactive ici'))
          : StreamBuilder<QuerySnapshot>(
        // StreamBuilder maintient la liste à jour en temps réel :
        // tout ajout ou suppression dans Firestore est reflété
        // immédiatement sans recharger la page.
        stream: _db
            .collection('evenements')
            .orderBy('date_creation', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Erreur de chargement"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
                child: Text("Aucun événement pour le moment."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var event = docs[index];
              Map<String, dynamic> data =
              event.data() as Map<String, dynamic>;

              String titre = data['nom'] ?? '';
              String lieu = data['lieu'] ?? '';
              String dateEvent = data['date_event'] ?? '';
              String tagString = data['tag'] ?? '';
              String organisateurNom = data['createur_nom'] ?? 'Inconnu';
              // createur_id est la valeur canonique ; createur est l'ancien
              // nom de champ conservé pour la rétrocompatibilité.
              String organisateurId =
                  data['createur_id'] ?? data['createur'] ?? '';

              Tag? eventTag = getTagFromString(tagString);

              // La mairie peut tout supprimer.
              // Une association ne peut supprimer que ses propres événements.
              bool peutSupprimer = (widget.role == Role.mairie) ||
                  (organisateurId == currentUserId);

              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(titre,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      if (dateEvent.isNotEmpty)
                        Text('Date: $dateEvent'),
                      if (organisateurNom.isNotEmpty)
                        Text('Organisateur : $organisateurNom',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      if (lieu.isNotEmpty) Text('Lieu: $lieu'),
                      const SizedBox(height: 8),
                      if (eventTag != null)
                        Chip(
                          label: Text(eventTag.displayName,
                              style:
                              TextStyle(color: eventTag.color)),
                          backgroundColor:
                          eventTag.color.withOpacity(0.1),
                        ),
                    ],
                  ),
                  // Tap sur la carte → ouvre EventDetailsPopup en bottom sheet.
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20)),
                      ),
                      builder: (context) => EventDetailsPopup(
                        eventId: event.id,
                        eventData: data,
                        role: widget.role,
                      ),
                    );
                  },
                  // Icône de suppression visible uniquement si peutSupprimer.
                  trailing: peutSupprimer
                      ? IconButton(
                    icon: const Icon(Icons.delete,
                        color: Colors.red),
                    onPressed: () =>
                        _showDeleteConfirm(context, event.id),
                  )
                      : null,
                ),
              );
            },
          );
        },
      ),
      // Bouton "+" de création d'événement, visible uniquement pour
      // les associations et la mairie.
      floatingActionButton:
      (widget.role == Role.association || widget.role == Role.mairie)
          ? FloatingActionButton(
        onPressed: () => _showCreateEventPopup(context),
        child: const Icon(Icons.add),
      )
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // _showDeleteConfirm — Dialogue de confirmation avant suppression
  //
  // La suppression est définitive côté Firestore. Le StreamBuilder met
  // automatiquement à jour la liste une fois le document supprimé.
  // ---------------------------------------------------------------------------
  void _showDeleteConfirm(BuildContext context, String documentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content:
        const Text('Voulez-vous vraiment supprimer cet événement ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () {
                _db.collection('evenements').doc(documentId).delete();
                Navigator.pop(context);
              },
              child: const Text('Supprimer',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // _showCreateEventPopup — Formulaire de création d'événement
  //
  // Utilise StatefulBuilder pour que les champs dynamiques (switch lien,
  // switch participations, datepicker) se mettent à jour à l'intérieur
  // du bottom sheet sans reconstruire toute la page.
  //
  // Données écrites dans Firestore à la validation :
  //   nom, date_event, tag, lieu, description,
  //   a_un_lien, lien_inscription, compter_participations,
  //   participants_ids (liste vide), date_creation, createur_id, createur_nom.
  //
  // createur_nom est résolu depuis la collection "utilisateurs" au moment
  // de la soumission pour afficher le nom de l'organisateur dans la liste.
  // ---------------------------------------------------------------------------
  void _showCreateEventPopup(BuildContext context) {
    final nomController = TextEditingController();
    final dateController = TextEditingController();
    final lieuController = TextEditingController();
    final descController = TextEditingController();
    final lienController = TextEditingController();
    Tag? selectedTag;
    bool aUnLien = false;
    bool compterParticipations = false;

    // Ouvre le DatePicker natif et formate la date choisie en JJ/MM/AAAA.
    Future<void> selectDate(
        BuildContext context, StateSetter setModalState) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2101),
      );
      if (picked != null) {
        setModalState(() {
          dateController.text =
          "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ajouter un Événement',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  TextField(
                      controller: nomController,
                      decoration:
                      const InputDecoration(labelText: 'Nom *')),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'Date *',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => selectDate(context, setModalState),
                  ),
                  DropdownButtonFormField<Tag>(
                    value: selectedTag,
                    items: Tag.values
                        .map((t) => DropdownMenuItem(
                        value: t, child: Text(t.displayName)))
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedTag = val),
                    decoration:
                    const InputDecoration(labelText: 'Type'),
                  ),
                  TextField(
                      controller: lieuController,
                      decoration:
                      const InputDecoration(labelText: 'Lieu')),
                  TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                          labelText: 'Description'),
                      maxLines: 2),
                  // Switch : active le champ URL du lien d'inscription.
                  SwitchListTile(
                      title: const Text("Lien d'inscription"),
                      value: aUnLien,
                      onChanged: (v) =>
                          setModalState(() => aUnLien = v)),
                  if (aUnLien)
                    TextField(
                        controller: lienController,
                        decoration:
                        const InputDecoration(labelText: 'URL')),
                  // Switch : active le compteur de participants dans la popup.
                  SwitchListTile(
                      title: const Text("Suivi participations"),
                      value: compterParticipations,
                      onChanged: (v) =>
                          setModalState(() => compterParticipations = v)),
                  ElevatedButton(
                    onPressed: () async {
                      // Validation minimale : nom et date obligatoires.
                      if (nomController.text.isNotEmpty &&
                          dateController.text.isNotEmpty) {
                        // Récupération du nom de l'organisateur depuis Firestore
                        // pour l'afficher dans la liste et la popup.
                        String organisateur = 'Inconnu';
                        DocumentSnapshot userDoc = await FirebaseFirestore
                            .instance
                            .collection('utilisateurs')
                            .doc(currentUserId)
                            .get();

                        if (userDoc.exists &&
                            userDoc.data().toString().contains('nom')) {
                          organisateur = userDoc['nom'];
                        }
                        await _db.collection('evenements').add({
                          'nom': nomController.text,
                          'date_event': dateController.text,
                          'tag': selectedTag?.name ?? '',
                          'lieu': lieuController.text,
                          'description': descController.text,
                          'a_un_lien': aUnLien,
                          'lien_inscription': lienController.text,
                          'compter_participations': compterParticipations,
                          'participants_ids': [],
                          'date_creation': FieldValue.serverTimestamp(),
                          'createur_id': currentUserId,
                          'createur_nom': organisateur,
                        });
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    child: const Text('Créer'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// EventDetailsPage — Page de détail complète (non utilisée en pratique)
//
// Alternative pleine page à EventDetailsPopup. Conservée pour compatibilité
// mais remplacée fonctionnellement par le bottom sheet EventDetailsPopup,
// qui offre une meilleure expérience utilisateur sur mobile.
// =============================================================================
class EventDetailsPage extends StatelessWidget {
  final Role role;
  final String eventId;
  final Map<String, dynamic> eventData;

  const EventDetailsPage(
      {super.key,
        required this.eventId,
        required this.eventData,
        required this.role});

  @override
  Widget build(BuildContext context) {
    String titre = eventData['nom'] ?? 'Sans titre';
    String description = eventData['description'] ?? '';
    String lieu = eventData['lieu'] ?? '';
    String dateEvent = eventData['date_event'] ?? '';
    Tag? eventTag = getTagFromString(eventData['tag']);
    bool aUnLien = eventData['a_un_lien'] ?? false;
    String lienInscription = eventData['lien_inscription'] ?? '';
    bool compterParticipations =
        eventData['compter_participations'] ?? false;
    List<dynamic> participantsIds = eventData['participants_ids'] ?? [];
    String currentUserId =
        FirebaseAuth.instance.currentUser?.uid ?? 'id_test';
    bool aDejaParticipe = participantsIds.contains(currentUserId);

    return Scaffold(
      appBar: AppBar(title: const Text('Détails')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titre,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            if (eventTag != null) Chip(label: Text(eventTag.displayName)),
            const SizedBox(height: 16),
            if (dateEvent.isNotEmpty)
              Row(children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                Text(dateEvent)
              ]),
            if (lieu.isNotEmpty)
              Row(children: [
                const Icon(Icons.location_on),
                const SizedBox(width: 8),
                Text(lieu)
              ]),
            const SizedBox(height: 16),
            Text(description),
            const Spacer(),
            if (aUnLien || compterParticipations)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                      aDejaParticipe ? Colors.grey : Colors.blue),
                  onPressed: (aDejaParticipe && !aUnLien)
                      ? null
                      : () async {
                    if (compterParticipations && !aDejaParticipe) {
                      await FirebaseFirestore.instance
                          .collection('evenements')
                          .doc(eventId)
                          .update({
                        'participants_ids':
                        FieldValue.arrayUnion([currentUserId]),
                      });
                    }
                    if (aUnLien && lienInscription.isNotEmpty) {
                      final uri = Uri.parse(lienInscription);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    }
                  },
                  child: Text(aUnLien
                      ? "S'inscrire (Lien)"
                      : (aDejaParticipe ? "Inscrit" : "Participer")),
                ),
              ),
          ],
        ),
      ),
    );
  }
}