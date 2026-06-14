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

// =============================================================================
// _GeoEvent — Modèle de données interne à ce fichier (préfixe _ = privé)
//
// Représente un événement Firestore enrichi de ses coordonnées GPS.
// On y stocke aussi le Tag pour déterminer la couleur du marqueur via
// l'extension TagExtension définie dans tag.dart.
// =============================================================================
class _GeoEvent {
  final String id;             // Identifiant du document Firestore
  final Map<String, dynamic> data; // Données brutes du document (passées à la popup)
  final LatLng location;       // Coordonnées GPS obtenues par géocodage
  final Tag? tag;              // Tag de l'événement, null si absent ou inconnu

  const _GeoEvent({
    required this.id,
    required this.data,
    required this.location,
    required this.tag,
  });

  // Retourne la couleur associée au tag, ou gris par défaut si aucun tag.
  Color get markerColor => tag?.color ?? Colors.blueGrey;
}

// =============================================================================
// MapScreen — Page principale de la carte
//
// Flux de données :
//   Firestore (StreamBuilder) → liste de documents
//     → _buildGeoEvents (FutureBuilder) → géocodage + filtrage par tag
//       → MarkerLayer → marqueurs cliquables sur la carte
//
// La carte reste affichée pendant le géocodage grâce au double builder
// (StreamBuilder pour le flux Firestore, FutureBuilder pour le géocodage).
// =============================================================================
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Mémoïsation des résultats de géocodage pour éviter de rappeler l'API
  // à chaque rebuild. Clé = chaîne du lieu, valeur = coordonnées ou null.
  final Map<String, LatLng?> _geoCache = {};

  // Tag sélectionné dans la barre de filtres. null signifie "Tous".
  Tag? _selectedTag;

  // Point de centrage initial de la carte : centre de Valenciennes.
  static const LatLng _defaultCenter = LatLng(50.3579, 3.5244);

  String get currentUserId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'id_utilisateur_test';

  // ---------------------------------------------------------------------------
  // _geocode — Point d'entrée du géocodage
  //
  // Vérifie d'abord le cache. Si le lieu est inconnu, délègue à
  // _buildCandidates pour obtenir plusieurs variantes de la requête,
  // puis les essaie dans l'ordre jusqu'au premier succès.
  // Le résultat (coordonnées ou null) est mis en cache avant d'être retourné.
  // ---------------------------------------------------------------------------
  Future<LatLng?> _geocode(String lieu) async {
    final key = lieu.trim();
    if (key.isEmpty) return null;
    if (_geoCache.containsKey(key)) return _geoCache[key];

    final candidates = _buildCandidates(key);

    for (final query in candidates) {
      final result = await _nominatimQuery(query);
      if (result != null) {
        _geoCache[key] = result;
        return result;
      }
    }

    _geoCache[key] = null;
    return null;
  }

  // ---------------------------------------------------------------------------
  // _buildCandidates — Génère jusqu'à 4 variantes du lieu à tester
  //
  // Variante 1 : texte brut saisi par l'utilisateur.
  // Variante 2 : texte nettoyé (suppression des numéros de BP et codes postaux
  //              parasites qui perturbent Nominatim, ex. "90339" ou "59304").
  // Variante 3 : texte nettoyé + ", Valenciennes, France" si la ville est absente.
  // Variante 4 : premier segment avant la virgule + ", Valenciennes, France"
  //              (dernier recours avec le nom de lieu le plus simple possible).
  // ---------------------------------------------------------------------------
  List<String> _buildCandidates(String lieu) {
    final candidates = <String>[lieu];

    // Supprime les nombres de 4 à 6 chiffres (codes postaux, numéros de BP),
    // puis nettoie les virgules et espaces en double laissés par la suppression.
    final cleaned = lieu
        .replaceAll(RegExp(r'\b\d{4,6}\b'), '')
        .replaceAll(RegExp(r',\s*,'), ',')
        .replaceAll(RegExp(r',\s*$'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();

    if (cleaned != lieu && cleaned.isNotEmpty) {
      candidates.add(cleaned);
      if (!cleaned.toLowerCase().contains('valenciennes')) {
        candidates.add('$cleaned, Valenciennes, France');
      }
    } else {
      if (!lieu.toLowerCase().contains('valenciennes')) {
        candidates.add('$lieu, Valenciennes, France');
      }
    }

    // Dernier recours : uniquement la partie avant la première virgule.
    final firstPart = lieu.split(',').first.trim();
    if (firstPart.isNotEmpty && firstPart != lieu) {
      candidates.add('$firstPart, Valenciennes, France');
    }

    return candidates;
  }

  // ---------------------------------------------------------------------------
  // _nominatimQuery — Appel HTTP vers l'API Nominatim (OpenStreetMap)
  //
  // Nominatim est gratuit et ne nécessite pas de clé API.
  // Le paramètre countrycodes=fr restreint les résultats à la France pour
  // éviter de trouver une "Place d'Armes" à l'étranger.
  // Retourne null si aucun résultat ou en cas d'erreur réseau.
  // ---------------------------------------------------------------------------
  Future<LatLng?> _nominatimQuery(String query) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
            '?q=${Uri.encodeComponent(query)}'
            '&format=json&limit=1'
            '&countrycodes=fr',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'citymove-flutter-app/1.0',
        'Accept-Language': 'fr',
      });
      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        if (results.isNotEmpty) {
          final lat = double.tryParse(results[0]['lat'] ?? '');
          final lon = double.tryParse(results[0]['lon'] ?? '');
          if (lat != null && lon != null) {
            debugPrint('Geocoded "$query" → $lat, $lon');
            return LatLng(lat, lon);
          }
        }
      }
    } catch (e) {
      debugPrint('Geocoding error for "$query": $e');
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // _buildGeoEvents — Transforme les documents Firestore en _GeoEvent
  //
  // Pour chaque document :
  //   1. Ignore ceux sans champ "lieu".
  //   2. Applique le filtre de tag sélectionné dans la barre de filtres.
  //   3. Géocode le lieu (avec cache).
  //   4. Ignore ceux dont le lieu n'a pas pu être géocodé.
  // Les événements restants sont retournés sous forme de _GeoEvent prêts
  // à être affichés comme marqueurs sur la carte.
  // ---------------------------------------------------------------------------
  Future<List<_GeoEvent>> _buildGeoEvents(List<QueryDocumentSnapshot> docs) async {
    final List<_GeoEvent> result = [];

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final lieu = (data['lieu'] ?? '').toString().trim();
      if (lieu.isEmpty) continue;

      final Tag? tag = getTagFromString(data['tag']);

      // Si un filtre est actif, on saute les événements qui ne correspondent pas.
      if (_selectedTag != null && tag != _selectedTag) continue;

      final LatLng? coords = await _geocode(lieu);
      if (coords == null) continue;

      result.add(_GeoEvent(id: doc.id, data: data, location: coords, tag: tag));
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // _showDetails — Ouvre la popup de détail d'un événement
  //
  // Réutilise exactement le même EventDetailsPopup que dans news_pages.dart,
  // ce qui garantit un comportement identique (participation, lien, compteur).
  // Le role est fixé à habitant car la carte est en lecture seule ; la popup
  // gère elle-même l'affichage conditionnel selon le rôle reçu.
  // ---------------------------------------------------------------------------
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
        role: Role.habitant,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // build — Structure visuelle de la page
  //
  // Couche 1 (StreamBuilder) : écoute Firestore en temps réel.
  //   └─ Couche 2 (Column) :
  //       ├─ _TagFilterBar : barre de filtres horizontale scrollable.
  //       └─ Couche 3 (FutureBuilder) : attend la fin du géocodage.
  //           └─ Stack :
  //               ├─ FlutterMap avec TileLayer OSM + MarkerLayer.
  //               └─ Badge flottant : spinner pendant le géocodage,
  //                  puis compteur d'événements affichés.
  // ---------------------------------------------------------------------------
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
              _TagFilterBar(
                selectedTag: _selectedTag,
                onTagSelected: (tag) => setState(() => _selectedTag = tag),
              ),
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
                                  onTap: () => _showDetails(context, e),
                                ),
                              ))
                                  .toList(),
                            ),
                          ],
                        ),

                        // Badge en haut à droite : spinner tant que le géocodage
                        // n'est pas terminé, compteur d'événements ensuite.
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
                                BoxShadow(color: Colors.black12, blurRadius: 4)
                              ],
                            ),
                            child: isLoading
                                ? const Row(
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
                            )
                                : Text(
                              '${geoEvents.length} événement${geoEvents.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
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

// =============================================================================
// _TagFilterBar — Barre de filtres horizontale scrollable
//
// Affiche une FilterChip "Tous" puis une par valeur de l'enum Tag.
// La chip active est colorée avec la couleur du tag correspondant.
// Appuyer sur la chip déjà active la désélectionne (retour à "Tous").
// Ce widget est stateless : l'état du filtre est géré par _MapScreenState.
// =============================================================================
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
          // Chip "Tous" : sélectionnée quand aucun tag n'est actif.
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
          // Une chip par tag de l'enum. La couleur du texte et de la bordure
          // reprend tag.color défini dans tag.dart pour rester cohérent
          // avec les marqueurs de la carte et les chips de news_pages.dart.
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
              // Désélectionne si on retape sur le même tag, sinon sélectionne.
              onSelected: (_) =>
                  onTagSelected(selectedTag == tag ? null : tag),
            ),
          )),
        ],
      ),
    );
  }
}

// =============================================================================
// _EventMarker — Icône de marqueur interactive placée sur la carte
//
// StatefulWidget pour gérer l'effet de survol (desktop/web) :
// l'icône grossit de 25 % via AnimatedScale quand la souris la survole.
// Sur mobile, le GestureDetector capte le tap et ouvre la popup via onTap.
// La couleur de l'icône est fournie par _GeoEvent.markerColor, qui reflète
// la couleur du tag de l'événement.
// =============================================================================
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