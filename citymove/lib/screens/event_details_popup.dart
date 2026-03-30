import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/role.dart';
import '../models/tag.dart';

class EventDetailsPopup extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;
  final Role role;

  const EventDetailsPopup({
    super.key,
    required this.eventId,
    required this.eventData,
    required this.role,
  });

  @override
  State<EventDetailsPopup> createState() => _EventDetailsPopupState();
}

class _EventDetailsPopupState extends State<EventDetailsPopup> {
  // L'identifiant de l'utilisateur connecté
  String get currentUserId {
    return FirebaseAuth.instance.currentUser?.uid ?? 'id_test';
  }

  // Fonction pour ouvrir le lien web
  Future<void> _ouvrirLien(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impossible d'ouvrir le lien.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Extraction des données ---
    String titre = widget.eventData['nom'] ?? 'Sans titre';
    String description = widget.eventData['description'] ?? '';
    String lieu = widget.eventData['lieu'] ?? '';
    String dateEvent = widget.eventData['date_event'] ?? '';

    // --- CORRECTION ICI : On utilise bien 'createur_nom' ---
    String organisateurNom = widget.eventData['createur_nom'] ?? 'Inconnu';

    Tag? eventTag = getTagFromString(widget.eventData['tag']);

    bool aUnLien = widget.eventData['a_un_lien'] ?? false;
    String lienInscription = widget.eventData['lien_inscription'] ?? '';
    bool compterParticipations = widget.eventData['compter_participations'] ?? false;

    // Récupération de la liste des participants
    List<dynamic> participantsIds = widget.eventData['participants_ids'] ?? [];
    int nombreParticipants = participantsIds.length;
    bool aDejaParticipe = participantsIds.contains(currentUserId);

    // --- Le Widget ---
    return Padding(
      // Padding dynamique pour éviter que le clavier (si jamais on en avait besoin) ne cache la vue
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // La pop-up prend juste la hauteur nécessaire
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : Titre et bouton de fermeture
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(titre, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context), // Fermer la pop-up
              )
            ],
          ),

          // Tag
          if (eventTag != null) ...[
            const SizedBox(height: 8),
            Chip(
              label: Text(eventTag.displayName, style: TextStyle(color: eventTag.color.withOpacity(0.9))),
              backgroundColor: eventTag.color.withOpacity(0.1),
              side: BorderSide(color: eventTag.color.withOpacity(0.5)),
            ),
          ],

          const Divider(height: 36),

          // Informations de base
          if (dateEvent.isNotEmpty)
            Row(children: [const Icon(Icons.calendar_today, color: Colors.deepPurple, size: 20), const SizedBox(width: 12), Text(dateEvent, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),

          if (lieu.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: [const Icon(Icons.location_on, color: Colors.redAccent, size: 20), const SizedBox(width: 12), Text(lieu, style: const TextStyle(fontSize: 16))]),
          ],

          // Affichage de l'organisateur (utilisation de la nouvelle variable)
          if (organisateurNom.isNotEmpty && organisateurNom != 'Inconnu') ...[
            const SizedBox(height: 12),
            Row(children: [const Icon(Icons.person, color: Colors.blueGrey, size: 20), const SizedBox(width: 12), Text("Organisé par : $organisateurNom", style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic))]),
          ],

          const SizedBox(height: 24),

          // Description
          if (description.isNotEmpty) ...[
            const Text("À propos de l'événement :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(fontSize: 15)),
          ],

          // Compteur (Information)
          if (compterParticipations) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.people, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Text('$nombreParticipants personnes participent', style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              ],
            ),
          ],

          const SizedBox(height: 32),

          // Bouton d'action
          if (aUnLien || compterParticipations)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(aUnLien ? Icons.open_in_new : (aDejaParticipe ? Icons.check : Icons.thumb_up)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: aDejaParticipe ? Colors.grey.shade400 : Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                // Logique du bouton
                onPressed: (compterParticipations && aDejaParticipe && !aUnLien) ? null : () async {

                  // 1. Ajouter l'utilisateur à Firestore s'il n'y est pas
                  if (compterParticipations && !aDejaParticipe) {
                    await FirebaseFirestore.instance.collection('evenements').doc(widget.eventId).update({
                      'participants_ids': FieldValue.arrayUnion([currentUserId]),
                    });

                    if (context.mounted) {
                      // On met à jour l'état local pour que le bouton devienne gris instantanément
                      setState(() {
                        widget.eventData['participants_ids'].add(currentUserId);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Votre participation a été enregistrée !')));
                    }
                  }

                  // 2. Ouvrir le lien
                  if (aUnLien && lienInscription.isNotEmpty) {
                    _ouvrirLien(lienInscription);
                  }
                },
                label: Text(aUnLien ? "S'inscrire sur le site" : (aDejaParticipe ? "Vous êtes inscrit" : "Je participe !"), style: const TextStyle(fontSize: 18)),
              ),
            ),

          const SizedBox(height: 24), // Espace en bas
        ],
      ),
    );
  }
}