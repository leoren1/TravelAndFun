// Full immutable model for an explorable city
import 'package:flutter/material.dart';

class ExploreCity {
  final String id;
  final String countryId;
  final String name;
  final String countryName;
  final String flagEmoji;
  final String gradientStartHex;
  final String gradientEndHex;
  final String tagline;
  final String description;
  final double lat;
  final double lng;
  final String currentWeather;  // "☀️ 22°C"
  final String bestSeason;      // "Spring & Autumn"
  final int totalPlaces;
  final int discoveredPlaces;   // mock: for demo discovery progress
  final List<String> moodTags;
  final double travelScore;     // 0-100
  final List<String> categoryIds;
  final bool isTrending;
  final bool isFeatured;
  final String region;          // "Île-de-France"

  const ExploreCity({
    required this.id,
    required this.countryId,
    required this.name,
    required this.countryName,
    required this.flagEmoji,
    required this.gradientStartHex,
    required this.gradientEndHex,
    required this.tagline,
    required this.description,
    required this.lat,
    required this.lng,
    required this.currentWeather,
    required this.bestSeason,
    required this.totalPlaces,
    required this.discoveredPlaces,
    required this.moodTags,
    required this.travelScore,
    required this.categoryIds,
    required this.isTrending,
    required this.isFeatured,
    required this.region,
  });

  Color get gradientStart =>
      Color(int.parse('0xFF${gradientStartHex.replaceAll('#', '')}'));
  Color get gradientEnd =>
      Color(int.parse('0xFF${gradientEndHex.replaceAll('#', '')}'));

  double get discoveryPercent =>
      totalPlaces > 0
          ? (discoveredPlaces / totalPlaces * 100).clamp(0, 100)
          : 0;
}
