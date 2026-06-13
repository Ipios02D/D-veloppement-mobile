
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/role.dart';
import 'news_pages.dart';
import 'votes_pages.dart';
import 'admin_page.dart';
import '../main.dart';
import 'package:http/http.dart' as http;

class HomeMairiePage extends StatefulWidget {
  final Function(int,Role) onNavigate;
  const HomeMairiePage({super.key,required this.onNavigate});

  @override
  State<HomeMairiePage> createState() => _HomeMairiePageState();
}

class _HomeMairiePageState extends State<HomeMairiePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // On garde l'animation du carousel d'images
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
        backgroundColor: Colors.blueGrey, // Optionnel : pour différencier visuellement
      ),
      body: Column(
        children: [
          // --- PARTIE HAUT : Carousel d'images (Identique à Citoyen) ---
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

          // --- PARTIE MILIEU : Espace vide ou message d'accueil (Pas de météo ici) ---
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_city, size: 80, color: Colors.blueGrey),
                  SizedBox(height: 10),
                  Text(
                    "Tableau de bord Mairie",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          // --- PARTIE BAS : Navigation avec l'icône Admin au milieu ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icone News
                IconButton(
                  icon: const Icon(Icons.newspaper, color: Colors.blue, size: 40),
                  onPressed: () => widget.onNavigate(4,Role.mairie),
                  ),
                

                // NOUVELLE Icone Paramètres (Admin) au centre
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings_outlined, color: Color.fromARGB(255, 0, 0, 0), size: 45),
                  onPressed: () => widget.onNavigate(9,Role.mairie),
                ),

                // Icone Votes
                IconButton(
                  icon: const Icon(Icons.how_to_vote_outlined, color: Colors.grey, size: 40),
                  onPressed: () => widget.onNavigate(5,Role.mairie),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



class HomeCitoyenPage extends StatefulWidget {
  final Role role;
  final Function(int,Role) onNavigate;
  const HomeCitoyenPage({super.key, required this.role,required this.onNavigate});

  @override
  State<HomeCitoyenPage> createState() => _HomeCitoyenPageState();
}

class _HomeCitoyenPageState extends State<HomeCitoyenPage> {
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

  Future<void> fetchWeather() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=50.3579&longitude=3.5244&current=temperature_2m,relative_humidity_2m,is_day'));

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
      appBar: AppBar(title: Text(widget.role == Role.habitant ? 'Accueil Habitant' : 'Accueil Association')),
      body: Column(
        children: [
          // --- PARTIE HAUT : Carousel d'images ---
          SizedBox(
            height: 350,
            child: PageView.builder(
              controller: _pageController,
              itemCount: 4,
              itemBuilder: (context, index) {
                return Image.asset(
                  'ressources/$index.jpg',
                  fit: BoxFit.fitWidth,
                  alignment: Alignment(0.0, 0.15),
                );
              },
            ),
          ),

          Expanded(
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("${temp ?? "--"}°C", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.newspaper, color: Colors.blue, size: 40),
                  onPressed: () => widget.onNavigate(4,Role.habitant),
                ),
                IconButton(
                  icon: const Icon(Icons.how_to_vote_outlined, color: Colors.grey, size: 40),
                  onPressed: () =>  widget.onNavigate(5,Role.habitant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}