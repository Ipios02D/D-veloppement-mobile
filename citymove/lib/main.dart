import 'package:flutter/material.dart';
// On importe le fichier qui contient la page de connexion
import 'screens/auth_pages.dart';
import 'screens/home_pages.dart';
import 'models/role.dart';

void main() {
  runApp(const CitymoveApp());
}

class CitymoveApp extends StatelessWidget {
  const CitymoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Citymove',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Citymove'), // On lance l'application sur la page de Login
    );
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
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: const Color.fromARGB(255, 255, 61, 7),
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[/*
          Padding(padding: EdgeInsets.all(20.0),child :Row(spacing:10,children: [
            Icon(Icons.dark_mode),
            Icon(Icons.light_mode)
            ])),*/
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
        const LoginPage()///Page Login pour redirection
        ,
        const LoginPage()/*CartePage()*////Page Carte
      ][currentPageIndex],
    );
  }
}
