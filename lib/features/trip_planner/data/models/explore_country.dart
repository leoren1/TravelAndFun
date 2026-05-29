// Full immutable model for an explorable country
import 'package:flutter/material.dart';

class ExploreCountry {
  final String id;
  final String name;
  final String flagEmoji;
  final String gradientStartHex; // e.g. "#1A237E"
  final String gradientEndHex;
  final String tagline;         // "The City of Light"
  final String shortDescription;
  final double lat;
  final double lng;
  final List<String> moodTags;  // ["Romantic", "Historical", "Gastronomic"]
  final int totalPlaces;
  final List<String> cityIds;
  final List<String> highlights; // ["Eiffel Tower", "Louvre", "Versailles"]
  final double popularityScore; // 0-100, used for sorting

  const ExploreCountry({
    required this.id,
    required this.name,
    required this.flagEmoji,
    required this.gradientStartHex,
    required this.gradientEndHex,
    required this.tagline,
    required this.shortDescription,
    required this.lat,
    required this.lng,
    required this.moodTags,
    required this.totalPlaces,
    required this.cityIds,
    required this.highlights,
    required this.popularityScore,
  });

  Color get gradientStart =>
      Color(int.parse('0xFF${gradientStartHex.replaceAll('#', '')}'));
  Color get gradientEnd =>
      Color(int.parse('0xFF${gradientEndHex.replaceAll('#', '')}'));

  int get cityCount => cityIds.length;
}
