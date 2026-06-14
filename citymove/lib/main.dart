import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/auth_pages.dart';
import 'screens/carte_page.dart';
import 'screens/home_pages.dart';
import 'screens/news_pages.dart';
import 'screens/votes_pages.dart';
import 'screens/admin_page.dart';
import 'models/role.dart';
import 'models/theme.dart';

// =============================================================================
// main — Point d'entrée de l'application
//
// Initialise Firebase avant de lancer le widget racine CitymoveApp.
// WidgetsFlutterBinding.ensureInitialized() est obligatoire pour pouvoir
// appeler du code asynchrone avant runApp().
// =============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CitymoveApp());
}

// =============================================================================
// CitymoveApp — Widget racine de l'application
//
// Gère uniquement le thème (clair / sombre). L'état du thème est remonté ici
// pour être accessible depuis NavBarre via le callback onThemeChanged.
// La page de départ est NavBarre, qui contient toute la logique de navigation.
// =============================================================================
class CitymoveApp extends StatefulWidget {
  const CitymoveApp({super.key});

  @override
  State<CitymoveApp> createState() => _CitymoveAppState();
}

class _CitymoveAppState extends State<CitymoveApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme(bool isLight) {
    setState(() {
      _themeMode = isLight ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Citymove',
      debugShowCheckedModeBanner: false,
      theme: CityTheme.light,
      darkTheme: CityTheme.dark,
      themeMode: _themeMode,
      home: NavBarre(
        title: 'Citymove',
        isLight: _themeMode == ThemeMode.light,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}

// =============================================================================
// NavBarre — Routeur principal de l'application
//
// Toute la navigation passe par un index entier (_currentPageIndex) et un
// rôle (_role). Le tableau de pages ci-dessous fait correspondre chaque
// index à son widget :
//
//   0  LoginPage              Page de connexion (aussi index 3 pour déconnexion)
//   1  HomeMairiePage /       Page d'accueil selon le rôle
//      HomeCitoyenPage
//   2  MapScreen              Carte interactive des événements
//   3  LoginPage              Déconnexion → retour à la connexion
//   4  NewsPage               Liste des événements
//   5  VotesPage              Liste des votes citoyens
//   6  RegisterChoicePage     Choix du type de compte à créer
//   7  RegisterHabitantPage   Formulaire d'inscription habitant
//   8  RegisterAssoPage       Formulaire d'inscription association
//   9  AdminConsolePage       Console d'administration (mairie uniquement)
//
// La NavigationBar du bas est masquée sur les pages de connexion /
// inscription (indices 0, 3, 6, 7, 8) pour ne pas parasiter ces écrans.
//
// changePage(index, role) est passé en callback à toutes les pages qui
// ont besoin de naviguer (via onNavigate).
// =============================================================================
class NavBarre extends StatefulWidget {
  const NavBarre({
    super.key,
    required this.title,
    required this.isLight,
    required this.onThemeChanged,
  });

  final String title;
  final bool isLight;
  final Function(bool) onThemeChanged;

  @override
  State<NavBarre> createState() => _NavBarreState();
}

class _NavBarreState extends State<NavBarre> {
  int _currentPageIndex = 0;
  Role _role = Role.habitant;

  // Callback passé à chaque page pour déclencher une navigation.
  void changePage(int index, Role role) {
    setState(() {
      _currentPageIndex = index;
      _role = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    // La NavigationBar est masquée sur les écrans de connexion / inscription.
    bool hideNavBar = _currentPageIndex == 0 ||
        _currentPageIndex == 3 ||
        (_currentPageIndex >= 6 && _currentPageIndex <= 8);

    return Scaffold(
      bottomNavigationBar: hideNavBar
          ? null
          : NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        indicatorColor: Theme.of(context).colorScheme.primaryContainer,
        // selectedIndex est ramené à 0 pour les pages au-delà de l'index 3
        // (News, Votes, Admin…) qui n'ont pas d'onglet dédié dans la barre.
        selectedIndex:
        (_currentPageIndex <= 3) ? _currentPageIndex : 0,
        destinations: <Widget>[
          // Index 0 : Switch thème intégré directement dans la barre.
          NavigationDestination(
            icon: Switch(
              thumbIcon: WidgetStateProperty.resolveWith<Icon?>(
                      (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Icon(Icons.light_mode);
                    }
                    return const Icon(Icons.dark_mode);
                  }),
              value: widget.isLight,
              onChanged: (bool value) {
                widget.onThemeChanged(value);
              },
            ),
            label: 'Thème',
          ),
          // Index 1 : Accueil.
          const NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Accueil',
          ),
          // Index 2 : Carte.
          const NavigationDestination(
            selectedIcon: Icon(Icons.map),
            icon: Icon(Icons.map_outlined),
            label: 'Carte',
          ),
          // Index 3 : Déconnexion → redirige vers LoginPage.
          const NavigationDestination(
            icon: Icon(Icons.door_back_door),
            label: 'Déconnexion',
          ),
        ],
      ),

      // Sélection de la page à afficher selon l'index courant.
      // ValueKey sur NewsPage et VotesPage force Flutter à reconstruire
      // le widget quand le rôle change (ex. : connexion d'un autre compte),
      // évitant de conserver un état périmé.
      body: [
        LoginPage(onNavigate: changePage),
        _role == Role.mairie
            ? HomeMairiePage(onNavigate: changePage)
            : HomeCitoyenPage(role: _role, onNavigate: changePage),
        const MapScreen(),
        LoginPage(onNavigate: changePage),
        NewsPage(key: ValueKey('news_$_role'), role: _role, onNavigate: changePage),
        VotesPage(key: ValueKey('votes_$_role'), role: _role),
        RegisterChoicePage(onNavigate: changePage),
        RegisterHabitantPage(onNavigate: changePage),
        RegisterAssoPage(onNavigate: changePage),
        const AdminConsolePage(),
      ][_currentPageIndex],
    );
  }
}