import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/role.dart';
import '../models/tag.dart';

// =============================================================================
// EventDetailsPopup — Fiche détaillée d'un événement en bottom sheet
//
// Utilisé depuis deux endroits :
//   - news_pages.dart : au tap sur une carte d'événement dans la liste.
//   - carte_page.dart : au tap sur un marqueur de la carte interactive.
//
// Le widget reçoit les données brutes du document Firestore (eventData) et
// l'identifiant du document (eventId) pour pouvoir écrire dans Firestore
// si l'utilisateur clique sur "Je participe".
// =============================================================================
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
  // Récupère l'uid Firebase de l'utilisateur connecté.
  // La valeur de fallback 'id_test' ne sert qu'en mode développement sans auth.
  String get currentUserId {
    return FirebaseAuth.instance.currentUser?.uid ?? 'id_test';
  }

  // Ouvre une URL dans le navigateur externe de l'appareil.
  // Affiche un SnackBar si l'URL ne peut pas être ouverte (format invalide,
  // aucune application disponible, etc.).
  Future<void> _ouvrirLien(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'ouvrir le lien.")),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // build — Affichage de la fiche événement
  //
  // Données lues depuis widget.eventData (Map Firestore) :
  //   - nom, description, lieu, date_event, createur_nom, tag
  //   - a_un_lien, lien_inscription   → contrôle le bouton d'inscription externe
  //   - compter_participations         → active le compteur de participants
  //   - participants_ids               → liste des uid des participants
  //
  // Le bouton d'action en bas a trois états :
  //   1. Lien externe    → ouvre lien_inscription dans le navigateur.
  //   2. Participation   → ajoute l'uid dans participants_ids dans Firestore
  //                        et met à jour l'état local immédiatement.
  //   3. Déjà inscrit    → bouton désactivé (gris) si compterParticipations
  //                        est actif et qu'aucun lien n'est prévu.
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    String titre = widget.eventData['nom'] ?? 'Sans titre';
    String description = widget.eventData['description'] ?? '';
    String lieu = widget.eventData['lieu'] ?? '';
    String dateEvent = widget.eventData['date_event'] ?? '';
    String organisateurNom = widget.eventData['createur_nom'] ?? 'Inconnu';

    Tag? eventTag = getTagFromString(widget.eventData['tag']);

    bool aUnLien = widget.eventData['a_un_lien'] ?? false;
    String lienInscription = widget.eventData['lien_inscription'] ?? '';
    bool compterParticipations =
        widget.eventData['compter_participations'] ?? false;

    List<dynamic> participantsIds =
        widget.eventData['participants_ids'] ?? [];
    int nombreParticipants = participantsIds.length;
    bool aDejaParticipe = participantsIds.contains(currentUserId);

    return Padding(
      // Le padding bottom s'adapte à la hauteur du clavier pour ne pas
      // cacher le contenu si un champ de saisie venait à être ajouté.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : titre à gauche, croix de fermeture à droite.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(titre,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),

          // Chip colorée du tag (n'apparaît que si le tag est reconnu).
          if (eventTag != null) ...[
            const SizedBox(height: 8),
            Chip(
              label: Text(eventTag.displayName,
                  style:
                  TextStyle(color: eventTag.color.withOpacity(0.9))),
              backgroundColor: eventTag.color.withOpacity(0.1),
              side: BorderSide(color: eventTag.color.withOpacity(0.5)),
            ),
          ],

          const Divider(height: 36),

          // Ligne date.
          if (dateEvent.isNotEmpty)
            Row(children: [
              const Icon(Icons.calendar_today,
                  color: Colors.deepPurple, size: 20),
              const SizedBox(width: 12),
              Text(dateEvent,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ]),

          // Ligne lieu.
          if (lieu.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
              const SizedBox(width: 12),
              Text(lieu, style: const TextStyle(fontSize: 16)),
            ]),
          ],

          // Ligne organisateur (masquée si valeur absente ou "Inconnu").
          if (organisateurNom.isNotEmpty &&
              organisateurNom != 'Inconnu') ...[
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.person, color: Colors.blueGrey, size: 20),
              const SizedBox(width: 12),
              Text("Organisé par : $organisateurNom",
                  style: const TextStyle(
                      fontSize: 14, fontStyle: FontStyle.italic)),
            ]),
          ],

          const SizedBox(height: 24),

          // Bloc description.
          if (description.isNotEmpty) ...[
            const Text("À propos de l'événement :",
                style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(fontSize: 15)),
          ],

          // Compteur de participants (affiché uniquement si activé par l'organisateur).
          if (compterParticipations) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.people, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Text('$nombreParticipants personnes participent',
                    style: const TextStyle(
                        color: Colors.grey, fontStyle: FontStyle.italic)),
              ],
            ),
          ],

          const SizedBox(height: 32),

          // Bouton d'action principal.
          // Visible uniquement si l'événement a un lien ou suit les participations.
          if (aUnLien || compterParticipations)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(aUnLien
                    ? Icons.open_in_new
                    : (aDejaParticipe ? Icons.check : Icons.thumb_up)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  // Bouton grisé si l'utilisateur est déjà inscrit et qu'il
                  // n'y a pas de lien externe à ouvrir.
                  backgroundColor: aDejaParticipe
                      ? Colors.grey.shade400
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                // Le bouton est désactivé uniquement si participation déjà faite
                // et qu'il n'y a pas de lien à ouvrir en plus.
                onPressed:
                (compterParticipations && aDejaParticipe && !aUnLien)
                    ? null
                    : () async {
                  // Étape 1 : Enregistre la participation dans Firestore.
                  if (compterParticipations && !aDejaParticipe) {
                    await FirebaseFirestore.instance
                        .collection('evenements')
                        .doc(widget.eventId)
                        .update({
                      'participants_ids':
                      FieldValue.arrayUnion([currentUserId]),
                    });

                    if (context.mounted) {
                      // Mise à jour locale immédiate pour griser
                      // le bouton sans attendre le prochain snapshot.
                      setState(() {
                        widget.eventData['participants_ids']
                            .add(currentUserId);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Votre participation a été enregistrée !')),
                      );
                    }
                  }

                  // Étape 2 : Ouvre le lien externe si présent.
                  if (aUnLien && lienInscription.isNotEmpty) {
                    _ouvrirLien(lienInscription);
                  }
                },
                label: Text(
                  aUnLien
                      ? "S'inscrire sur le site"
                      : (aDejaParticipe ? "Vous êtes inscrit" : "Je participe !"),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}