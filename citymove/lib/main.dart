import 'package:flutter/material.dart';
// On importe le fichier qui contient la page de connexion
import 'screens/auth_pages.dart';
import 'screens/carte_page.dart';
import 'screens/home_pages.dart';
import 'screens/news_pages.dart';
import 'screens/votes_pages.dart';
import 'models/role.dart';

void main() {
  runApp(const CitymoveApp());
}

class CitymoveApp extends StatefulWidget {
  const CitymoveApp({super.key});
  @override
  _CitymoveApp createState() => _CitymoveApp();
}

class _CitymoveApp extends State<CitymoveApp> {
  int themeIndex = 1;
  int currentIndex=1;
  final List<ThemeData> theme = [ThemeData.dark(),ThemeData.light()];

  void toggleTheme(bool isLight,int index) {
    setState(() {
      themeIndex = isLight ? 1 : 0;
      currentIndex=index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Citymove',
      debugShowCheckedModeBanner: false,
      theme: theme[themeIndex],
      home: MyHomePage(
        title: 'Citymove',
        onThemeChanged: toggleTheme,
        currentPageIndex: currentIndex,), // On lance l'application sur la page de Login
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title, required this.onThemeChanged, required this.currentPageIndex});

  final String title;
  final Function(bool,int) onThemeChanged;
  int currentPageIndex;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool light=true;

  void changePage(int index) {
  setState(() {
    widget.currentPageIndex = index;
  });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            widget.currentPageIndex = index;
          });
        },
        indicatorColor: const Color.fromARGB(255, 255, 61, 7),
        selectedIndex: widget.currentPageIndex <= 3 ? widget.currentPageIndex : 0,
        destinations:  <Widget>[
          Switch(
            thumbIcon: WidgetStateProperty<Icon>.fromMap(<WidgetStatesConstraint, Icon>{
            WidgetState.selected: Icon(Icons.light_mode),
            WidgetState.any: Icon(Icons.dark_mode),
            }),
            value:light,
            onChanged: (bool value) {
            setState(() {
              light = value;
            });
            widget.onThemeChanged(value,widget.currentPageIndex);}
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Badge(child: Icon(Icons.home)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(child: Icon(Icons.map)),
            label: 'Carte',
          ),
          NavigationDestination(
            icon: Badge( child: Icon(Icons.door_back_door)),
            label: 'Se déconnecter',
          ),
        ],
      ),
      body: <Widget>[
        LoginPage(onNavigate: changePage),
        HomeCitoyenPage(role : Role.habitant,onNavigate: changePage),///Page Login pour redirection
        const MapScreen(),///Page Carte
        LoginPage(onNavigate: changePage),///pop up compte
        const NewsPage(role : Role.habitant),
        const VotesPage(role : Role.habitant),
      ][widget.currentPageIndex],
    );
  }
}
