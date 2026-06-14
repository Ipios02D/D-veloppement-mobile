import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/role.dart';
import 'news_pages.dart';
import 'votes_pages.dart';
import 'admin_page.dart';
import '../main.dart';
import 'package:http/http.dart' as http;

// =============================================================================
// HomeMairiePage — Page d'accueil réservée au rôle mairie
//
// Différences avec HomeCitoyenPage :
//   - Pas de widget météo (non pertinent pour un tableau de bord admin).
//   - Bouton central vers AdminConsolePage (index 9) en plus des boutons
//     News (index 4) et Votes (index 5).
//   - AppBar en blueGrey pour distinguer visuellement le mode admin.
// =============================================================================
class HomeMairiePage extends StatefulWidget {
  final Function(int, Role) onNavigate;
  const HomeMairiePage({super.key, required this.onNavigate});

  @override
  State<HomeMairiePage> createState() => _HomeMairiePageState();
}

class _HomeMairiePageState extends State<HomeMairiePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Défilement automatique du carousel toutes les 4 secondes.
    // Le timer tourne en boucle de 0 à 3 (4 images dans assets/ressources/).
    Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < 3) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil Mairie / Administration'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        children: [
          // Carousel d'images locales (ressources/0.jpg … ressources/3.jpg).
          SizedBox(
            height: 350,
            child: PageView.builder(
              controller: _pageController,
              itemCount: 4,
              itemBuilder: (context, index) {
                return Image.asset(
                  'ressources/$index.jpg',
                  fit: BoxFit.fitWidth,
                  alignment: const Alignment(0.0, 0.15),
                );
              },
            ),
          ),

          // Zone centrale : icône et label "Tableau de bord Mairie".
          // Pas de météo ici, contrairement à HomeCitoyenPage.
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_city, size: 80, color: Colors.blueGrey),
                  SizedBox(height: 10),
                  Text(
                    "Tableau de bord Mairie",
                    style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          // Barre de navigation rapide spécifique à la mairie :
          //   News (4) — Admin (9) — Votes (5).
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.newspaper,
                      color: Colors.blue, size: 40),
                  onPressed: () => widget.onNavigate(4, Role.mairie),
                ),
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings_outlined,
                      color: Color.fromARGB(255, 0, 0, 0), size: 45),
                  onPressed: () => widget.onNavigate(9, Role.mairie),
                ),
                IconButton(
                  icon: const Icon(Icons.how_to_vote_outlined,
                      color: Colors.grey, size: 40),
                  onPressed: () => widget.onNavigate(5, Role.mairie),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HomeCitoyenPage — Page d'accueil pour les habitants et les associations
//
// Fonctionnalités :
//   - Carousel d'images automatique (identique à HomeMairiePage).
//   - Widget météo en temps réel via l'API Open-Meteo (sans clé API).
//     Coordonnées fixées sur Valenciennes (50.3579 N, 3.5244 E).
//   - Boutons de navigation rapide vers News (4) et Votes (5).
//
// Le titre de l'AppBar change selon le rôle : "Habitant" ou "Association".
// =============================================================================
class HomeCitoyenPage extends StatefulWidget {
  final Role role;
  final Function(int, Role) onNavigate;
  const HomeCitoyenPage(
      {super.key, required this.role, required this.onNavigate});

  @override
  State<HomeCitoyenPage> createState() => _HomeCitoyenPageState();
}

class _HomeCitoyenPageState extends State<HomeCitoyenPage> {
  // Données météo, null tant que l'appel API n'est pas terminé.
  double? temp;
  int? humidity;
  bool isSunny = true;
  bool isLoading = true;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    fetchWeather();
    // Même logique de carousel que HomeMairiePage.
    Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < 3) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // fetchWeather — Récupère la météo actuelle via Open-Meteo
  //
  // Open-Meteo est une API gratuite sans clé. On demande trois variables :
  //   temperature_2m      → température en °C à 2 m du sol
  //   relative_humidity_2m → humidité relative en %
  //   is_day              → 1 si c'est le jour, 0 si c'est la nuit
  //
  // is_day est utilisé comme proxy simple pour afficher soleil ou nuage.
  // ---------------------------------------------------------------------------
  Future<void> fetchWeather() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.open-meteo.com/v1/forecast'
              '?latitude=50.3579&longitude=3.5244'
              '&current=temperature_2m,relative_humidity_2m,is_day'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          temp = data['current']['temperature_2m'];
          humidity = data['current']['relative_humidity_2m'];
          isSunny = data['current']['is_day'] == 1;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur météo: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.role == Role.habitant
              ? 'Accueil Habitant'
              : 'Accueil Association')),
      body: Column(
        children: [
          // Carousel d'images identique à HomeMairiePage.
          SizedBox(
            height: 350,
            child: PageView.builder(
              controller: _pageController,
              itemCount: 4,
              itemBuilder: (context, index) {
                return Image.asset(
                  'ressources/$index.jpg',
                  fit: BoxFit.fitWidth,
                  alignment: const Alignment(0.0, 0.15),
                );
              },
            ),
          ),

          // Zone météo : spinner pendant le chargement, données ensuite.
          Expanded(
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${temp ?? "--"}°C",
                      style: const TextStyle(
                          fontSize: 40, fontWeight: FontWeight.bold)),
                  Text("Humidité : ${humidity ?? "--"}%"),
                  Icon(
                    isSunny ? Icons.wb_sunny : Icons.cloud,
                    size: 50,
                    color: isSunny ? Colors.orange : Colors.grey,
                  ),
                  Text(isSunny ? "Il fait beau" : "Ciel couvert"),
                ],
              ),
            ),
          ),

          // Barre de navigation rapide : News (4) et Votes (5).
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.newspaper,
                      color: Colors.blue, size: 40),
                  onPressed: () => widget.onNavigate(4, widget.role),
                ),
                IconButton(
                    icon: const Icon(Icons.how_to_vote_outlined,
                        color: Colors.grey, size: 40),
                    onPressed: () => widget.onNavigate(5, widget.role)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}