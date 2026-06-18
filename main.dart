import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapScreen(),
    );
  }
}

// MapScreen est devenu un StatefulWidget pour gérer l'état
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Variable d'état pour savoir si la souris est sur le marqueur
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Flutter Map Example',
          style: TextStyle(fontSize: 20),
        ),
      ),
      body: content(context),
    );
  }

  Widget content(BuildContext context) {
    // Définition des tailles normales et agrandies
    const double normalSize = 40.0;
    const double hoverSize = 60.0; // 50% plus gros

    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(50.35732, 3.52357),
        initialZoom: 15,
        interactionOptions: InteractionOptions(
          flags: ~InteractiveFlag.doubleTapZoom,
        ),
      ),
      children: [
        openStreetMapTileLayer,
        MarkerLayer(
          markers: [
            Marker(
              point: const LatLng(50.33257401019579, 3.511126919232961),
              // La taille du Marker doit être celle de l'icône la plus grande
              width: hoverSize,
              height: hoverSize,
              // Aligner le bas de l'icône sur le point GPS
              alignment: Alignment.topCenter,
              child: MouseRegion(
                // 1. Gérer les événements de la souris
                onEnter: (_) => setState(() => _isHovering = true),
                onExit: (_) => setState(() => _isHovering = false),
                cursor: SystemMouseCursors.click, // Change le curseur en main
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Marker Tapped'),
                        content: const Text('You tapped the marker!'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  // 2. Animer le changement de taille de l'icône
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: _isHovering ? hoverSize : normalSize,
                    height: _isHovering ? hoverSize : normalSize,
                    child: Icon(
                      Icons.location_pin,
                      // La taille de l'icône doit suivre celle de son conteneur
                      size: _isHovering ? hoverSize : normalSize,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

TileLayer get openStreetMapTileLayer => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
    );