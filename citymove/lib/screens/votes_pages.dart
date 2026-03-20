import 'package:flutter/material.dart';
import '../models/role.dart';

class VotesPage extends StatelessWidget {
  final Role role;
  const VotesPage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Votes Citoyens')),
      body: ListView.builder(
        itemCount: 4,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text('Proposition de vote #${index + 1}'),
              subtitle: const Text('État: 150 participants - Finit le 12/10'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoteDetailsPage())),
              trailing: role == Role.mairie
                  ? IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {})
                  : const Icon(Icons.how_to_vote),
            ),
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

  void _showCreateVotePopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Créer un Vote', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const TextField(decoration: InputDecoration(labelText: 'Nom du vote')),
            const TextField(decoration: InputDecoration(labelText: 'Description'), maxLines: 2),
            const Row(
              children: [
                Expanded(child: TextField(decoration: InputDecoration(labelText: 'Âge Min'))),
                SizedBox(width: 16),
                Expanded(child: TextField(decoration: InputDecoration(labelText: 'Âge Max'))),
              ],
            ),
            const TextField(decoration: InputDecoration(labelText: 'Quorum requis (%)')),
            const TextField(decoration: InputDecoration(labelText: 'Date de fin')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Créer le vote')),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class VoteDetailsPage extends StatefulWidget {
  const VoteDetailsPage({super.key});

  @override
  State<VoteDetailsPage> createState() => _VoteDetailsPageState();
}

class _VoteDetailsPageState extends State<VoteDetailsPage> {
  String? _choixVote;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Participer au vote')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Proposition de vote #1', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Finit le 12/10 - Quorum requis : 20%'),
            const SizedBox(height: 16),
            const Text(
              'Êtes-vous pour la création d\'un nouveau parc paysager dans le centre-ville ? Ce projet s\'étalera sur 2 ans.',
              style: TextStyle(fontSize: 16),
            ),
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
                onPressed: _choixVote == null ? null : () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Votre vote a bien été pris en compte !')));
                  Navigator.pop(context);
                },
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