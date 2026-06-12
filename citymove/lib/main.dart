import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Import de vos pages et de votre thème
import 'screens/auth_pages.dart';
import 'screens/carte_page.dart';
import 'screens/home_pages.dart';
import 'screens/news_pages.dart';
import 'screens/votes_pages.dart';
import 'screens/admin_page.dart';
import 'models/role.dart';
import 'models/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CitymoveApp());
}

class CitymoveApp extends StatefulWidget {
  const CitymoveApp({super.key});

  @override
  State<CitymoveApp> createState() => _CitymoveAppState();
}

class _CitymoveAppState extends State<CitymoveApp> {
  // Gestion de l'état du thème (Clair par défaut)
  ThemeMode _themeMode = ThemeMode.light;

  // Fonction pour basculer le thème
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

  void changePage(int index, Role role) {
    setState(() {
      _currentPageIndex = index;
      _role = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Condition pour savoir si on est sur une page de connexion/inscription
    bool hideNavBar = _currentPageIndex == 0 || _currentPageIndex == 3 || (_currentPageIndex >= 6 && _currentPageIndex <= 8);

    return Scaffold(
      bottomNavigationBar: hideNavBar ? null : NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        indicatorColor: Theme.of(context).colorScheme.primaryContainer,
        selectedIndex: ( _currentPageIndex <= 3) ? _currentPageIndex : 0,
        destinations: <Widget>[
          // Index 0 : Le Switch intégré proprement
          NavigationDestination(
            icon: Switch(
                thumbIcon: WidgetStateProperty.resolveWith<Icon?>((Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) return const Icon(Icons.light_mode);
                  return const Icon(Icons.dark_mode);
                }),
                value: widget.isLight,
                onChanged: (bool value) {
                  widget.onThemeChanged(value);
                }
            ),
            label: 'Thème',
          ),
          // Index 1 : Home
          const NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Accueil',
          ),
          // Index 2 : Carte
          const NavigationDestination(
            selectedIcon: Icon(Icons.map),
            icon: Icon(Icons.map_outlined),
            label: 'Carte',
          ),
          // Index 3 : Déconnexion
          const NavigationDestination(
            icon: Icon(Icons.door_back_door),
            label: 'Déconnexion',
          ),
        ],
      ),

      body: <Widget>[
        LoginPage(onNavigate: changePage), // 0
        _role == Role.mairie ? HomeMairiePage(onNavigate: changePage) : HomeCitoyenPage(role: _role, onNavigate: changePage), // 1
        const MapScreen(), // 2
        LoginPage(onNavigate: changePage), // 3 (Sert pour la déconnexion)
        NewsPage(role: _role), // 4
        VotesPage(role: _role), // 5
        RegisterChoicePage(onNavigate: changePage), // 6
        RegisterHabitantPage(onNavigate: changePage), // 7
        RegisterAssoPage(onNavigate: changePage), // 8
        const AdminConsolePage() // 9
      ][_currentPageIndex],
    );
  }
}