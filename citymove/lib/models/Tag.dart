import 'package:flutter/material.dart';

enum Tag { sportif, culturel, professionnel, medical, bienetre, ecologique }

extension TagExtension on Tag {
  // Gère l'affichage textuel propre (avec accents et tirets)
  String get displayName {
    switch (this) {
      case Tag.sportif:
        return 'Sportif';
      case Tag.culturel:
        return 'Culturel';
      case Tag.professionnel:
        return 'Professionnel';
      case Tag.medical: // Gère le "Medical" de votre exemple
        return 'Médical';
      case Tag.bienetre:
        return 'Bien-être';
      case Tag.ecologique:
        return 'Écologique';
    }
  }

  // Associe une couleur à chaque tag pour l'aspect visuel
  Color get color {
    switch (this) {
      case Tag.sportif:
        return Colors.orange;
      case Tag.culturel:
        return Colors.purple;
      case Tag.professionnel:
        return Colors.blueGrey;
      case Tag.medical:
        return Colors.redAccent;
      case Tag.bienetre:
        return Colors.teal;
      case Tag.ecologique:
        return Colors.green;
    }
  }
}

// Fonction utilitaire pour retrouver un Tag depuis une chaîne de texte de la base de données
Tag? getTagFromString(String? value) {
  if (value == null) return null;
  for (var tag in Tag.values) {
    if (tag.name.toLowerCase() == value.toLowerCase()) {
      return tag;
    }
  }
  return null;
}