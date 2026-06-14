import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/role.dart';

// =============================================================================
// AdminConsolePage — Console d'administration réservée à la mairie
//
// Accessible depuis HomeMairiePage via onNavigate(9, Role.mairie).
// Organisée en trois onglets gérés par un TabController :
//
//   Onglet 0 — _StatsTab         : compteurs globaux de la base de données.
//   Onglet 1 — _UsersTab         : liste et gestion de tous les utilisateurs.
//   Onglet 2 — _PendingAssosTab  : demandes d'inscription d'associations
//                                   en attente de validation.
//
// SingleTickerProviderStateMixin est requis par TabController pour
// piloter les animations de transition entre onglets.
// =============================================================================
class AdminConsolePage extends StatefulWidget {
  const AdminConsolePage({super.key});

  @override
  State<AdminConsolePage> createState() => _AdminConsolePageState();
}

class _AdminConsolePageState extends State<AdminConsolePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // length: 3 correspond aux trois onglets Stats / Utilisateurs / En attente.
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Console Administrateur'),
        // TabBar intégrée à l'AppBar pour un rendu Material 3 cohérent.
        // Les couleurs sont forcées en blanc pour contraster avec l'AppBar bleue.
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
            Tab(icon: Icon(Icons.people), text: 'Utilisateurs'),
            Tab(icon: Icon(Icons.pending_actions), text: 'En attente'),
          ],
        ),
      ),
      // Chaque enfant de TabBarView reçoit l'instance Firestore partagée
      // pour éviter d'en créer plusieurs et de multiplier les connexions.
      body: TabBarView(
        controller: _tabController,
        children: [
          _StatsTab(db: _db),
          _UsersTab(db: _db),
          _PendingAssosTab(db: _db),
        ],
      ),
    );
  }
}

// =============================================================================
// _StatsTab — Onglet Statistiques
//
// Affiche des compteurs en temps quasi-réel via FutureBuilder.
// Les cinq requêtes Firestore sont lancées en parallèle avec Future.wait
// pour minimiser le temps d'attente total.
//
// Compteurs affichés :
//   [0] Total utilisateurs (toute la collection)
//   [1] Habitants           (statut == 'Citoyen')
//   [2] Associations        (statut == 'Association')
//   [3] Événements          (toute la collection evenements)
//   [4] Votes               (toute la collection votes)
//
// Utilise l'API count() de Firestore (agrégation côté serveur) pour éviter
// de rapatrier tous les documents et réduire les coûts de lecture.
// =============================================================================
class _StatsTab extends StatelessWidget {
  final FirebaseFirestore db;
  const _StatsTab({required this.db});

  // Compte tous les documents d'une collection.
  Future<int> _count(String collection) async {
    final snap = await db.collection(collection).count().get();
    return snap.count ?? 0;
  }

  // Compte les documents d'une collection filtrés sur un champ/valeur.
  Future<int> _countWhere(
      String collection, String field, dynamic value) async {
    final snap = await db
        .collection(collection)
        .where(field, isEqualTo: value)
        .count()
        .get();
    return snap.count ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      // Les 5 requêtes sont parallélisées : le FutureBuilder attend
      // que toutes soient terminées avant d'afficher les données.
      future: Future.wait([
        _count('utilisateurs'),
        _countWhere('utilisateurs', 'statut', 'Citoyen'),
        _countWhere('utilisateurs', 'statut', 'Association'),
        _count('evenements'),
        _count('votes'),
      ]),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erreur : ${snap.error}'));
        }

        final d = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionHeader(title: 'Aperçu général'),
            const SizedBox(height: 12),
            // Grille 2 colonnes de cartes de statistiques.
            // shrinkWrap + NeverScrollableScrollPhysics permettent d'intégrer
            // le GridView dans un ListView sans conflit de scroll.
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _StatCard(
                    label: 'Utilisateurs total',
                    value: d[0],
                    icon: Icons.group,
                    color: Colors.blueGrey),
                _StatCard(
                    label: 'Habitants',
                    value: d[1],
                    icon: Icons.person,
                    color: Colors.teal),
                _StatCard(
                    label: 'Associations',
                    value: d[2],
                    icon: Icons.groups,
                    color: Colors.purple),
                _StatCard(
                    label: 'Événements',
                    value: d[3],
                    icon: Icons.event,
                    color: Colors.orange),
                _StatCard(
                    label: 'Votes',
                    value: d[4],
                    icon: Icons.how_to_vote,
                    color: Colors.indigo),
              ],
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// _StatCard — Carte de compteur pour l'onglet Stats
//
// Affiche une icône colorée en haut à gauche, le chiffre en grand
// et le libellé en petit en bas. childAspectRatio: 1.6 dans le GridView
// dimensionne la carte pour que ces trois éléments tiennent sans débordement.
// =============================================================================
class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.label,
        required this.value,
        required this.icon,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _UsersTab — Onglet Gestion des utilisateurs
//
// Liste tous les utilisateurs de la collection Firestore 'utilisateurs',
// avec un filtre par statut (Tous / Citoyen / Association / Mairie).
//
// Chaque utilisateur dispose d'un menu contextuel (PopupMenuButton) avec :
//   - Changer de rôle : met à jour le champ 'statut' dans Firestore.
//   - Supprimer       : supprime le document Firestore (pas le compte Auth).
//
// Le flux est temps réel (StreamBuilder) : toute modification externe
// (ex. : validation d'une association depuis _PendingAssosTab) est
// immédiatement reflétée dans la liste sans recharger.
//
// Limitation : la suppression retire uniquement le document Firestore,
// pas le compte Firebase Auth. Pour une suppression complète, il faudrait
// appeler l'Admin SDK via une Cloud Function.
// =============================================================================
class _UsersTab extends StatefulWidget {
  final FirebaseFirestore db;
  const _UsersTab({required this.db});

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  String _filter = 'Tous';
  final List<String> _filters = ['Tous', 'Citoyen', 'Association', 'Mairie'];

  // Retourne le flux Firestore filtré selon le statut sélectionné.
  // Si 'Tous', aucun filtre where n'est appliqué.
  Stream<QuerySnapshot> get _stream {
    Query q = widget.db.collection('utilisateurs');
    if (_filter != 'Tous') {
      q = q.where('statut', isEqualTo: _filter);
    }
    return q.snapshots();
  }

  // Met à jour le champ 'statut' d'un utilisateur dans Firestore.
  // La modification est immédiate et reflétée dans le StreamBuilder.
  Future<void> _updateRole(String uid, String nouveauStatut) async {
    await widget.db
        .collection('utilisateurs')
        .doc(uid)
        .update({'statut': nouveauStatut});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rôle mis à jour : $nouveauStatut')));
    }
  }

  // ---------------------------------------------------------------------------
  // _deleteUser — Suppression d'un utilisateur
  //
  // Affiche un dialog de confirmation avant de supprimer le document Firestore.
  // Note : ne supprime pas le compte Firebase Auth (nécessiterait Admin SDK).
  // ---------------------------------------------------------------------------
  Future<void> _deleteUser(String uid, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: Text('Supprimer définitivement le compte de $email ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.db.collection('utilisateurs').doc(uid).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre de filtres par statut, scrollable horizontalement.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((f) {
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Erreur : ${snap.error}'));
              }

              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Center(
                    child: Text('Aucun utilisateur trouvé.'));
              }

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final uid = docs[i].id;
                  final email = data['email'] ?? 'Email inconnu';
                  final nom = data['nom'] ?? '';
                  final statut = data['statut'] ?? 'Citoyen';

                  return ListTile(
                    // _RoleAvatar affiche une icône colorée selon le statut.
                    leading: _RoleAvatar(statut: statut),
                    // Si le nom est renseigné, il est le titre principal
                    // et l'email passe en sous-titre. Sinon, l'email est titre.
                    title: Text(nom.isNotEmpty ? nom : email,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (nom.isNotEmpty)
                          Text(email,
                              style: const TextStyle(fontSize: 12)),
                        // Badge coloré affichant le statut sous le nom.
                        _RoleBadge(statut: statut),
                      ],
                    ),
                    isThreeLine: nom.isNotEmpty,
                    // Menu contextuel : changement de rôle ou suppression.
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Actions',
                      onSelected: (action) {
                        if (action == 'delete') {
                          _deleteUser(uid, email);
                        } else {
                          _updateRole(uid, action);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'Citoyen',
                            child: ListTile(
                                dense: true,
                                leading: Icon(Icons.person),
                                title: Text('Passer en Citoyen'))),
                        const PopupMenuItem(
                            value: 'Association',
                            child: ListTile(
                                dense: true,
                                leading: Icon(Icons.groups),
                                title: Text('Passer en Association'))),
                        const PopupMenuItem(
                            value: 'Mairie',
                            child: ListTile(
                                dense: true,
                                leading: Icon(Icons.account_balance),
                                title: Text('Passer en Mairie'))),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                                dense: true,
                                leading: Icon(Icons.delete,
                                    color: Colors.red),
                                title: Text('Supprimer',
                                    style: TextStyle(
                                        color: Colors.red)))),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _PendingAssosTab — Onglet Associations en attente de validation
//
// Affiche les documents Firestore dont :
//   statut  == 'Association'
//   validee == false
//
// Ce sont les comptes créés via RegisterAssoPage qui n'ont pas encore
// été examinés par la mairie.
//
// Deux actions par demande :
//   Valider → passe 'statut' à 'Association' et 'validee' à true.
//              L'association peut alors se connecter (LoginPage le vérifie).
//   Refuser → supprime le document Firestore (et le compte reste bloqué
//              dans Firebase Auth, sans accès à l'application).
// =============================================================================
class _PendingAssosTab extends StatelessWidget {
  final FirebaseFirestore db;
  const _PendingAssosTab({required this.db});

  // ---------------------------------------------------------------------------
  // _valider — Approuve la demande d'une association
  //
  // Met à jour le document Firestore :
  //   statut  → 'Association' (déjà le cas, mais explicite pour clarté)
  //   validee → true
  //
  // Après cette mise à jour, LoginPage laissera passer l'association
  // car la vérification `if (!validee)` sera fausse.
  // ---------------------------------------------------------------------------
  Future<void> _valider(BuildContext context, FirebaseFirestore db,
      String uid, String nom) async {
    await db
        .collection('utilisateurs')
        .doc(uid)
        .update({'statut': 'Association', 'validee': true});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Association "$nom" validée ✓')));
    }
  }

  // ---------------------------------------------------------------------------
  // _refuser — Rejette la demande d'une association
  //
  // Affiche un dialog de confirmation, puis supprime le document Firestore.
  // Le compte Firebase Auth reste actif mais sans document associé,
  // ce qui empêche toute connexion (LoginPage lit le document pour le rôle).
  // ---------------------------------------------------------------------------
  Future<void> _refuser(BuildContext context, FirebaseFirestore db,
      String uid, String nom) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Refuser l\'association'),
        content: Text('Supprimer la demande de "$nom" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Refuser',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await db.collection('utilisateurs').doc(uid).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Requête filtrée sur les associations non validées.
    // Le StreamBuilder met à jour la liste en temps réel :
    // une association validée disparaît instantanément de cet onglet.
    final stream = db
        .collection('utilisateurs')
        .where('statut', isEqualTo: 'Association')
        .where('validee', isEqualTo: false)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erreur : ${snap.error}'));
        }

        final docs = snap.data!.docs;

        // État vide : icône de validation pour indiquer qu'il n'y a rien à faire.
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 64, color: Colors.green),
                SizedBox(height: 12),
                Text('Aucune demande en attente',
                    style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final uid = docs[i].id;
            final nom = data['nom'] ?? 'Association inconnue';
            final email = data['email'] ?? '';
            final sujet = data['sujet'] ?? '';
            final siret = data['siret'] ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête : nom de l'association + badge "En attente".
                    Row(
                      children: [
                        const Icon(Icons.groups, color: Colors.purple),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(nom,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.4)),
                          ),
                          child: const Text('En attente',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.orange)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Détails de la demande : email, sujet, SIRET.
                    // _InfoRow est masqué si le champ est vide.
                    if (email.isNotEmpty)
                      _InfoRow(icon: Icons.email, text: email),
                    if (sujet.isNotEmpty)
                      _InfoRow(icon: Icons.category, text: sujet),
                    if (siret.isNotEmpty)
                      _InfoRow(
                          icon: Icons.numbers, text: 'SIRET : $siret'),
                    const SizedBox(height: 14),
                    // Boutons Refuser / Valider côte à côte.
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.close,
                                color: Colors.red),
                            label: const Text('Refuser',
                                style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Colors.red)),
                            onPressed: () =>
                                _refuser(context, db, uid, nom),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Valider'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white),
                            onPressed: () =>
                                _valider(context, db, uid, nom),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// =============================================================================
// WIDGETS UTILITAIRES PARTAGÉS ENTRE LES ONGLETS
// =============================================================================

// Titre de section en couleur primaire du thème, utilisé dans _StatsTab.
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 0.8));
  }
}

// Avatar circulaire avec icône colorée selon le statut de l'utilisateur.
// Utilisé comme leading dans les ListTile de _UsersTab.
class _RoleAvatar extends StatelessWidget {
  final String statut;
  const _RoleAvatar({required this.statut});

  @override
  Widget build(BuildContext context) {
    // Pattern matching Dart 3 : retourne (color, icon) selon le statut.
    final (color, icon) = switch (statut) {
      'Mairie'      => (Colors.blueGrey, Icons.account_balance),
      'Association' => (Colors.purple, Icons.groups),
      _             => (Colors.teal, Icons.person),
    };
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.15),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// Badge textuel coloré affichant le statut sous le nom dans _UsersTab.
// Même logique de couleur que _RoleAvatar pour la cohérence visuelle.
class _RoleBadge extends StatelessWidget {
  final String statut;
  const _RoleBadge({required this.statut});

  @override
  Widget build(BuildContext context) {
    final color = switch (statut) {
      'Mairie'      => Colors.blueGrey,
      'Association' => Colors.purple,
      _             => Colors.teal,
    };
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(statut,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}

// Ligne d'information icône + texte utilisée dans les cartes de _PendingAssosTab.
// Le texte est Expanded pour gérer les longues valeurs (emails, SIRET) sans débordement.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}