import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/role.dart';
import '../main.dart';

// =============================================================================
// VotesPage — Liste des votes citoyens en temps réel
//
// Affiche tous les documents de la collection "votes" Firestore,
// triés par date de création décroissante (les plus récents en premier).
//
// Accès selon le rôle :
//   - habitant    : lecture et participation uniquement.
//   - association : peut créer ses propres votes et les supprimer.
//   - mairie      : peut créer et supprimer tous les votes.
//
// Chaque vote affiche son nom, le total des voix et la date de fin.
// Un tap navigue vers VoteDetailsPage pour voter.
// =============================================================================
class VotesPage extends StatelessWidget {
  final Role role;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get currentUserId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'id_utilisateur_test';

  VotesPage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Votes Citoyens')),
      body: StreamBuilder<QuerySnapshot>(
        // Flux temps réel : toute création ou suppression dans Firestore
        // est immédiatement répercutée dans la liste.
        stream: _db
            .collection('votes')
            .orderBy('date_creation', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text("Erreur de chargement des votes"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
                child: Text("Aucun vote en cours pour le moment."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var vote = docs[index];
              Map<String, dynamic> data =
              vote.data() as Map<String, dynamic>;

              String nom =
              data.containsKey('nom') ? data['nom'] : 'Sondage sans nom';
              String dateFin =
              data.containsKey('dateFin') ? data['dateFin'] : 'Inconnue';

              // Total des voix = somme des trois choix possibles.
              int totalVotes = (data['pour'] ?? 0) +
                  (data['contre'] ?? 0) +
                  (data['abstention'] ?? 0);

              String createurId = data['createur_id'] ?? '';

              // La mairie peut tout supprimer.
              // Une association ne peut supprimer que ses propres votes.
              bool peutSupprimer = role == Role.mairie ||
                  (role == Role.association && createurId == currentUserId);

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(nom,
                      style:
                      const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Total des votes: $totalVotes\nFinit le: $dateFin'),
                  isThreeLine: true,
                  // Tap → VoteDetailsPage pour lire les détails et voter.
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => VoteDetailsPage(
                              voteId: vote.id, voteData: data))),
                  trailing: peutSupprimer
                      ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () =>
                        _showDeleteConfirm(context, vote.id),
                  )
                      : const Icon(Icons.how_to_vote),
                ),
              );
            },
          );
        },
      ),
      // Bouton de création visible uniquement pour association et mairie.
      floatingActionButton:
      (role == Role.association || role == Role.mairie)
          ? FloatingActionButton(
        onPressed: () => _showCreateVotePopup(context),
        child: const Icon(Icons.add),
      )
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // _showDeleteConfirm — Dialogue de confirmation avant suppression
  //
  // La suppression est irréversible. Toutes les voix enregistrées sont
  // perdues car le document Firestore est supprimé définitivement.
  // ---------------------------------------------------------------------------
  void _showDeleteConfirm(BuildContext context, String documentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
            'Voulez-vous vraiment supprimer ce vote ? Toute progression sera perdue.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () {
                _db.collection('votes').doc(documentId).delete();
                Navigator.pop(context);
              },
              child: const Text('Supprimer',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // _showCreateVotePopup — Formulaire de création d'un vote
  //
  // Utilise StatefulBuilder pour mettre à jour le DatePicker à l'intérieur
  // du bottom sheet sans reconstruire toute la page.
  //
  // Données écrites dans Firestore à la validation :
  //   nom, description, ageMin, ageMax, quorum, dateFin,
  //   date_creation, createur_id, pour, contre, abstention (initialisés à 0).
  //
  // ageMin / ageMax permettent de restreindre le vote à une tranche d'âge
  // (fonctionnalité de filtrage à implémenter côté logique de vote).
  // quorum est le pourcentage minimum de participation requis pour que
  // le résultat soit considéré comme valide.
  // ---------------------------------------------------------------------------
  void _showCreateVotePopup(BuildContext context) {
    final nomController = TextEditingController();
    final descController = TextEditingController();
    final ageMinController = TextEditingController();
    final ageMaxController = TextEditingController();
    final quorumController = TextEditingController();
    final dateFinController = TextEditingController();

    // Ouvre le DatePicker et formate la date choisie en JJ/MM/AAAA.
    // La date minimale est aujourd'hui pour éviter des votes déjà expirés.
    Future<void> selectDate(
        BuildContext context, StateSetter setModalState) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 7)),
        firstDate: DateTime.now(),
        lastDate: DateTime(2101),
      );
      if (picked != null) {
        setModalState(() {
          dateFinController.text =
          "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Créer un Vote',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                TextField(
                    controller: nomController,
                    decoration: const InputDecoration(
                        labelText: 'Nom du vote',
                        border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder()),
                    maxLines: 2),
                const SizedBox(height: 10),
                // Tranche d'âge des votants autorisés.
                Row(
                  children: [
                    Expanded(
                        child: TextField(
                            controller: ageMinController,
                            decoration: const InputDecoration(
                                labelText: 'Âge Min',
                                border: OutlineInputBorder()),
                            keyboardType: TextInputType.number)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: TextField(
                            controller: ageMaxController,
                            decoration: const InputDecoration(
                                labelText: 'Âge Max',
                                border: OutlineInputBorder()),
                            keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: quorumController,
                    decoration: const InputDecoration(
                        labelText: 'Quorum requis (%)',
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                // Champ date en lecture seule : la saisie passe par le DatePicker.
                TextField(
                  controller: dateFinController,
                  readOnly: true,
                  onTap: () => selectDate(context, setModalState),
                  decoration: const InputDecoration(
                    labelText: 'Date de fin du vote *',
                    suffixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Validation minimale : nom et date de fin obligatoires.
                      if (nomController.text.isNotEmpty &&
                          dateFinController.text.isNotEmpty) {
                        await _db.collection('votes').add({
                          'nom': nomController.text,
                          'description': descController.text,
                          'ageMin':
                          int.tryParse(ageMinController.text) ?? 0,
                          'ageMax':
                          int.tryParse(ageMaxController.text) ?? 120,
                          'quorum':
                          int.tryParse(quorumController.text) ?? 0,
                          'dateFin': dateFinController.text,
                          'date_creation': FieldValue.serverTimestamp(),
                          'createur_id': currentUserId,
                          // Les compteurs démarrent à 0 et sont incrémentés
                          // dans Firestore via FieldValue.increment dans VoteDetailsPage.
                          'pour': 0,
                          'contre': 0,
                          'abstention': 0,
                        });
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    child: const Text('Créer le vote'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// VoteDetailsPage — Détail d'un vote et formulaire de participation
//
// Reçoit les données du vote depuis VotesPage (pas de lecture Firestore ici).
// L'utilisateur choisit parmi trois options via RadioListTile, puis valide.
//
// La soumission utilise FieldValue.increment(1) sur le champ correspondant
// ('pour', 'contre' ou 'abstention') pour un incrément atomique côté serveur,
// ce qui évite les conditions de course en cas de votes simultanés.
//
// Limitation : aucune protection contre le vote multiple n'est implémentée
// ici (pas de liste voted_ids). À ajouter si nécessaire.
// =============================================================================
class VoteDetailsPage extends StatefulWidget {
  final String voteId;
  final Map<String, dynamic> voteData;

  const VoteDetailsPage(
      {super.key, required this.voteId, required this.voteData});

  @override
  State<VoteDetailsPage> createState() => _VoteDetailsPageState();
}

class _VoteDetailsPageState extends State<VoteDetailsPage> {
  // Choix de l'utilisateur : 'Pour', 'Contre' ou 'Abstention'. null = rien sélectionné.
  String? _choixVote;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // _soumettreVote — Enregistre le vote dans Firestore et ferme la page
  //
  // On convertit le choix en minuscules pour correspondre aux champs Firestore
  // ('pour', 'contre', 'abstention') puis on incrémente le compteur atomiquement.
  // ---------------------------------------------------------------------------
  void _soumettreVote() async {
    if (_choixVote != null) {
      String champAIncrementer = _choixVote!.toLowerCase();

      await _db.collection('votes').doc(widget.voteId).update({
        champAIncrementer: FieldValue.increment(1),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Votre vote a bien été pris en compte !')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String nom = widget.voteData['nom'] ?? 'Sans nom';
    String description =
        widget.voteData['description'] ?? 'Pas de description.';
    String dateFin = widget.voteData['dateFin'] ?? 'Inconnue';
    int quorum = widget.voteData['quorum'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Participer au vote')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nom,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Finit le $dateFin - Quorum requis : $quorum%'),
            const SizedBox(height: 16),
            Text(description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 32),
            const Text('Faites votre choix :',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600)),

            // Les trois options de vote. La valeur du RadioListTile correspond
            // exactement au texte affiché ; elle est passée en minuscules
            // dans _soumettreVote pour cibler le bon champ Firestore.
            RadioListTile<String>(
              title: const Text('Pour'),
              value: 'Pour',
              groupValue: _choixVote,
              onChanged: (val) => setState(() => _choixVote = val),
            ),
            RadioListTile<String>(
              title: const Text('Contre'),
              value: 'Contre',
              groupValue: _choixVote,
              onChanged: (val) => setState(() => _choixVote = val),
            ),
            RadioListTile<String>(
              title: const Text('Abstention'),
              value: 'Abstention',
              groupValue: _choixVote,
              onChanged: (val) => setState(() => _choixVote = val),
            ),

            const Spacer(),

            // Bouton désactivé tant qu'aucun choix n'est sélectionné.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _choixVote == null ? null : _soumettreVote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Valider mon vote',
                    style: TextStyle(fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }
}