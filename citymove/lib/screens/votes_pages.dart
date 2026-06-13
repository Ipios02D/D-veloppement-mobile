import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/role.dart';
import '../main.dart';

class VotesPage extends StatelessWidget {
  final Role role;

  // Instance de Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get currentUserId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'id_utilisateur_test';

  VotesPage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Votes Citoyens')),
      // --- STREAMBUILDER POUR LIRE LES VOTES EN TEMPS RÉEL ---
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('votes').orderBy(
            'date_creation', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text("Erreur de chargement des votes"));
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
              Map<String, dynamic> data = vote.data() as Map<String, dynamic>;

              String nom = data.containsKey('nom')
                  ? data['nom']
                  : 'Sondage sans nom';
              String dateFin = data.containsKey('dateFin')
                  ? data['dateFin']
                  : 'Inconnue';
              int totalVotes = (data['pour'] ?? 0) + (data['contre'] ?? 0) +
                  (data['abstention'] ?? 0);
              String createurId = data['createur_id'] ?? '';

              // Mairie peut tout supprimer, asso uniquement ses propres votes
              bool peutSupprimer = role == Role.mairie ||
                  (role == Role.association && createurId == currentUserId);

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(
                      nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Total des votes: $totalVotes\nFinit le: $dateFin'),
                  isThreeLine: true,
                  onTap: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) =>
                          VoteDetailsPage(voteId: vote.id, voteData: data))),
                  trailing: peutSupprimer
                      ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirm(context, vote.id),
                  )
                      : const Icon(Icons.how_to_vote),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: (role == Role.association || role == Role.mairie)
          ? FloatingActionButton(
        onPressed: () => _showCreateVotePopup(context),
        child: const Icon(Icons.add),
      )
          : null,
    );
  }

  void _showDeleteConfirm(BuildContext context, String documentId) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: const Text(
                'Voulez-vous vraiment supprimer ce vote ? Toute progression sera perdue.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler')),
              TextButton(
                  onPressed: () {
                    _db.collection('votes').doc(documentId).delete();
                    Navigator.pop(context);
                  },
                  child: const Text(
                      'Supprimer', style: TextStyle(color: Colors.red))
              ),
            ],
          ),
    );
  }

  void _showCreateVotePopup(BuildContext context) {
    final nomController = TextEditingController();
    final descController = TextEditingController();
    final ageMinController = TextEditingController();
    final ageMaxController = TextEditingController();
    final quorumController = TextEditingController();
    final dateFinController = TextEditingController();

    // Fonction interne pour choisir la date
    Future<void> _selectDate(BuildContext context,
        StateSetter setModalState) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 7)),
        // Par défaut dans une semaine
        firstDate: DateTime.now(),
        // On ne peut pas finir un vote dans le passé
        lastDate: DateTime(2101),
      );
      if (picked != null) {
        setModalState(() {
          // Formatage JJ/MM/AAAA
          dateFinController.text =
          "${picked.day.toString().padLeft(2, '0')}/${picked.month
              .toString()
              .padLeft(2, '0')}/${picked.year}";
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          StatefulBuilder( // Utilisation de StatefulBuilder pour mettre à jour la date dans la popup
            builder: (context, setModalState) =>
                Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery
                          .of(context)
                          .viewInsets
                          .bottom,
                      left: 16, right: 16, top: 16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Créer un Vote', style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        TextField(controller: nomController,
                            decoration: const InputDecoration(
                                labelText: 'Nom du vote',
                                border: OutlineInputBorder())),
                        const SizedBox(height: 10),
                        TextField(controller: descController,
                            decoration: const InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder()),
                            maxLines: 2),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: TextField(
                                controller: ageMinController,
                                decoration: const InputDecoration(
                                    labelText: 'Âge Min',
                                    border: OutlineInputBorder()),
                                keyboardType: TextInputType.number)),
                            const SizedBox(width: 16),
                            Expanded(child: TextField(
                                controller: ageMaxController,
                                decoration: const InputDecoration(
                                    labelText: 'Âge Max',
                                    border: OutlineInputBorder()),
                                keyboardType: TextInputType.number)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(controller: quorumController,
                            decoration: const InputDecoration(
                                labelText: 'Quorum requis (%)',
                                border: OutlineInputBorder()),
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 10),

                        // --- CHAMP DATE MODIFIÉ ---
                        TextField(
                          controller: dateFinController,
                          readOnly: true, // Empêche la saisie clavier
                          onTap: () => _selectDate(context, setModalState),
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
                                if (nomController.text.isNotEmpty &&
                                    dateFinController.text.isNotEmpty) {
                                  await _db.collection('votes').add({
                                    'nom': nomController.text,
                                    'description': descController.text,
                                    'ageMin': int.tryParse(
                                        ageMinController.text) ?? 0,
                                    'ageMax': int.tryParse(
                                        ageMaxController.text) ?? 120,
                                    'quorum': int.tryParse(
                                        quorumController.text) ?? 0,
                                    'dateFin': dateFinController.text,
                                    'date_creation': FieldValue
                                        .serverTimestamp(),
                                    'createur_id': currentUserId,
                                    'pour': 0,
                                    'contre': 0,
                                    'abstention': 0,
                                  });
                                  if (context.mounted) Navigator.pop(context);
                                }
                              },
                              child: const Text('Créer le vote')
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

// --- PAGE DE DÉTAILS ET D'ACTION DE VOTE ---
class VoteDetailsPage extends StatefulWidget {
  final String voteId;
  final Map<String, dynamic> voteData;

  const VoteDetailsPage({super.key, required this.voteId, required this.voteData});

  @override
  State<VoteDetailsPage> createState() => _VoteDetailsPageState();
}

class _VoteDetailsPageState extends State<VoteDetailsPage> {
  String? _choixVote;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _soumettreVote() async {
    if (_choixVote != null) {
      // On utilise FieldValue.increment(1) pour ajouter +1 au choix de l'utilisateur
      // de manière sécurisée directement sur le serveur Firebase
      String champAIncrementer = _choixVote!.toLowerCase(); // 'pour', 'contre', ou 'abstention'

      await _db.collection('votes').doc(widget.voteId).update({
        champAIncrementer: FieldValue.increment(1),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Votre vote a bien été pris en compte !')));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String nom = widget.voteData['nom'] ?? 'Sans nom';
    String description = widget.voteData['description'] ?? 'Pas de description.';
    String dateFin = widget.voteData['dateFin'] ?? 'Inconnue';
    int quorum = widget.voteData['quorum'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Participer au vote')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nom, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Finit le $dateFin - Quorum requis : $quorum%'),
            const SizedBox(height: 16),
            Text(description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 32),
            const Text('Faites votre choix :', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),

            RadioListTile<String>(
              title: const Text('Pour'), value: 'Pour', groupValue: _choixVote,
              onChanged: (val) => setState(() => _choixVote = val),
            ),
            RadioListTile<String>(
              title: const Text('Contre'), value: 'Contre', groupValue: _choixVote,
              onChanged: (val) => setState(() => _choixVote = val),
            ),
            RadioListTile<String>(
              title: const Text('Abstention'), value: 'Abstention', groupValue: _choixVote,
              onChanged: (val) => setState(() => _choixVote = val),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _choixVote == null ? null : _soumettreVote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Valider mon vote', style: TextStyle(fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }
}