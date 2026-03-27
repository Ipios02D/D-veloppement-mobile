
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/role.dart';
import 'news_pages.dart';
import 'votes_pages.dart';
import 'admin_page.dart';
import '../main.dart';
import 'package:http/http.dart' as http;

class HomeMairiePage extends StatelessWidget {
  final Function(int) onNavigate;
  const HomeMairiePage({super.key,required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de Bord Mairie'), backgroundColor: Colors.deepPurple.shade200),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.event), label: const Text('Gérer les News / Événements'),
              onPressed: () => onNavigate(4),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.how_to_vote), label: const Text('Gérer les Votes'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VotesPage(role: Role.mairie))),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.admin_panel_settings), label: const Text('Console d\'Administration'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminConsolePage())),
            ),
          ],
        ),
      ),
    );
  }
}


class HomeCitoyenPage extends StatefulWidget {
  final Role role;
  final Function(int) onNavigate;
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
      // Note : j'ai ajouté 'relative_humidity_2m' et 'is_day' à l'URL pour répondre à ta demande
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
                  onPressed: () => widget.onNavigate(4),
                ),
                IconButton(
                  icon: const Icon(Icons.how_to_vote_outlined, color: Colors.grey, size: 40),
                  onPressed: () =>  widget.onNavigate(5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}