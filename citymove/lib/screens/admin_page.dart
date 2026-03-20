import 'package:flutter/material.dart';

class AdminConsolePage extends StatelessWidget {
  const AdminConsolePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Console Administrateur')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Liste des comptes et droits'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Notifications pour les associations'),
            subtitle: const Text('Activer les alertes de nouveaux comptes asso à valider'),
            value: true,
            onChanged: (bool value) {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.pending_actions, color: Colors.orange),
            title: const Text('Comptes associations en attente (2)'),
            onTap: () {},
          )
        ],
      ),
    );
  }
}