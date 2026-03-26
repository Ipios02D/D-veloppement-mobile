import 'package:flutter/material.dart';
// On importe le fichier qui contient la page de connexion
import 'screens/auth_pages.dart';
import 'screens/carte_page.dart';
import 'screens/home_pages.dart';
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
  final List<ThemeData> theme = [ThemeData.dark(),ThemeData.light()];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Citymove',
      debugShowCheckedModeBanner: false,
      theme: theme[themeIndex],
      home: const MyHomePage(title: 'Citymove'), // On lance l'application sur la page de Login
    );
  }

  void _handleThemeChange(int? value) {
    setState(() {
          themeIndex = value!;
    });
}
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int currentPageIndex = 0;
  bool light=true;

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: const Color.fromARGB(255, 255, 61, 7),
        selectedIndex: currentPageIndex,
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
              /*if (value){
                _handleThemeChange(1);
              }else {
                _handleThemeChange(0);
              }*/
            });}
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
            icon: Badge( child: Icon(Icons.menu)),
            label: 'Mon compte',
          ),
        ],
      ),
      body: <Widget>[
        const LoginPage(),
        const HomeCitoyenPage(role : Role.habitant),///Page Login pour redirection
        const MapScreen(),///Page Carte
        const LoginPage()///pop up compte
      ][currentPageIndex],
    );
  }
}
