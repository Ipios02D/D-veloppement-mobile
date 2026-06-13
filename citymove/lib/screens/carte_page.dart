import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/role.dart';
import '../models/tag.dart';
import 'event_details_popup.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODÈLE INTERNE
// ─────────────────────────────────────────────────────────────────────────────
class _GeoEvent {
  final String id;
  final Map<String, dynamic> data;
  final LatLng location;
  final Tag? tag;

  const _GeoEvent({
    required this.id,
    required this.data,
    required this.location,
    required this.tag,
  });

  Color get markerColor => tag?.color ?? Colors.blueGrey;
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE PRINCIPALE
// ─────────────────────────────────────────────────────────────────────────────
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Cache géocodage : lieu → LatLng (évite les appels répétés)
  final Map<String, LatLng?> _geoCache = {};

  // Filtre actif (null = Tous)
  Tag? _selectedTag;

  // Centre par défaut : Valenciennes
  static const LatLng _defaultCenter = LatLng(50.3579, 3.5244);

  String get currentUserId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'id_utilisateur_test';

  // ── Géocodage Nominatim (OSM, gratuit, sans clé API) ──────────────────────
  Future<LatLng?> _geocode(String lieu) async {
    if (lieu.trim().isEmpty) return null;
    if (_geoCache.containsKey(lieu)) return _geoCache[lieu];

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
            '?q=${Uri.encodeComponent(lieu)}'
            '&format=json&limit=1',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'citymove-flutter-app/1.0',
      });
      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        if (results.isNotEmpty) {
          final lat = double.tryParse(results[0]['lat'] ?? '');
          final lon = double.tryParse(results[0]['lon'] ?? '');
          if (lat != null && lon != null) {
            final coords = LatLng(lat, lon);
            _geoCache[lieu] = coords;
            return coords;
          }
        }
      }
    } catch (e) {
      debugPrint('Geocoding error for "$lieu": $e');
    }

    _geoCache[lieu] = null;
    return null;
  }

  // ── Construction de la liste des marqueurs géocodés ───────────────────────
  Future<List<_GeoEvent>> _buildGeoEvents(List<QueryDocumentSnapshot> docs) async {
    final List<_GeoEvent> result = [];

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final lieu = (data['lieu'] ?? '').toString().trim();
      if (lieu.isEmpty) continue;

      final Tag? tag = getTagFromString(data['tag']);

      // Filtre tag
      if (_selectedTag != null && tag != _selectedTag) continue;

      final LatLng? coords = await _geocode(lieu);
      if (coords == null) continue;

      result.add(_GeoEvent(
        id: doc.id,
        data: data,
        location: coords,
        tag: tag,
      ));
    }

    return result;
  }

  // ── Popup détails (même que dans news_pages) ──────────────────────────────
  void _showDetails(BuildContext context, _GeoEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EventDetailsPopup(
        eventId: event.id,
        eventData: event.data,
        role: Role.habitant, // la popup gère elle-même les droits
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carte des Événements')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('evenements')
            .orderBy('date_creation', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erreur de chargement'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return Column(
            children: [
              // ── Barre de filtres par tag ──────────────────────────────
              _TagFilterBar(
                selectedTag: _selectedTag,
                onTagSelected: (tag) => setState(() => _selectedTag = tag),
              ),

              // ── Carte ─────────────────────────────────────────────────
              Expanded(
                child: FutureBuilder<List<_GeoEvent>>(
                  future: _buildGeoEvents(docs),
                  builder: (context, geoSnap) {
                    final geoEvents = geoSnap.data ?? [];
                    final isLoading =
                        geoSnap.connectionState == ConnectionState.waiting;

                    return Stack(
                      children: [
                        FlutterMap(
                          options: const MapOptions(
                            initialCenter: _defaultCenter,
                            initialZoom: 13,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.citymove',
                            ),
                            MarkerLayer(
                              markers: geoEvents
                                  .map((e) => Marker(
                                point: e.location,
                                width: 44,
                                height: 44,
                                alignment: Alignment.topCenter,
                                child: _EventMarker(
                                  event: e,
                                  onTap: () =>
                                      _showDetails(context, e),
                                ),
                              ))
                                  .toList(),
                            ),
                          ],
                        ),

                        // Indicateur de chargement du géocodage
                        if (isLoading)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black12, blurRadius: 4)
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Localisation…',
                                      style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),

                        // Compte des événements affichés
                        if (!isLoading)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black12, blurRadius: 4)
                                ],
                              ),
                              child: Text(
                                '${geoEvents.length} événement${geoEvents.length > 1 ? 's' : ''}',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BARRE DE FILTRES PAR TAG
// ─────────────────────────────────────────────────────────────────────────────
class _TagFilterBar extends StatelessWidget {
  final Tag? selectedTag;
  final ValueChanged<Tag?> onTagSelected;

  const _TagFilterBar({
    required this.selectedTag,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          // Puce "Tous"
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Tous'),
              selected: selectedTag == null,
              onSelected: (_) => onTagSelected(null),
              selectedColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
          // Une puce par tag
          ...Tag.values.map((tag) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                tag.displayName,
                style: TextStyle(
                  color: selectedTag == tag ? tag.color : null,
                ),
              ),
              selected: selectedTag == tag,
              selectedColor: tag.color.withOpacity(0.2),
              checkmarkColor: tag.color,
              side: selectedTag == tag
                  ? BorderSide(color: tag.color)
                  : null,
              onSelected: (_) =>
                  onTagSelected(selectedTag == tag ? null : tag),
            ),
          )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET MARQUEUR
// ─────────────────────────────────────────────────────────────────────────────
class _EventMarker extends StatefulWidget {
  final _GeoEvent event;
  final VoidCallback onTap;

  const _EventMarker({required this.event, required this.onTap});

  @override
  State<_EventMarker> createState() => _EventMarkerState();
}

class _EventMarkerState extends State<_EventMarker> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.25 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Icon(
            Icons.location_pin,
            size: 44,
            color: widget.event.markerColor,
            shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
          ),
        ),
      ),
    );
  }
}