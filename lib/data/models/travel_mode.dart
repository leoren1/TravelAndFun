// lib/data/models/travel_mode.dart
//
// Travel Mode system — controls which cities and places count toward discovery.
//
//  Bronze  → globally iconic cities only; must-see landmark places
//  Silver  → secondary touristic cities; standard tourist places
//  Gold    → every city in the dataset; hidden gems + local favourites
//
// Hierarchy is INCLUSIVE: Silver includes Bronze; Gold includes everything.

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum TravelMode { bronze, silver, gold }

enum CityTier { bronze, silver, gold }

enum PlaceTier { bronze, silver, gold }

// ---------------------------------------------------------------------------
// TravelMode extensions
// ---------------------------------------------------------------------------

extension TravelModeX on TravelMode {
  String get jsonKey => name; // 'bronze' | 'silver' | 'gold'

  String get displayName => switch (this) {
        TravelMode.bronze => 'Bronze Explorer',
        TravelMode.silver => 'Silver Traveller',
        TravelMode.gold   => 'Gold Adventurer',
      };

  String get shortName => switch (this) {
        TravelMode.bronze => 'Bronze',
        TravelMode.silver => 'Silver',
        TravelMode.gold   => 'Gold',
      };

  String get emoji => switch (this) {
        TravelMode.bronze => '🥉',
        TravelMode.silver => '🥈',
        TravelMode.gold   => '🥇',
      };

  String get description => switch (this) {
        TravelMode.bronze =>
          'Famous landmarks & iconic cities only.\nPerfect for casual tourists.',
        TravelMode.silver =>
          'Adds regional hotspots & secondary cities.\nFor dedicated travellers.',
        TravelMode.gold =>
          'Every city, every hidden gem.\nFor hardcore world explorers.',
      };

  /// The lowest tier included by this mode (always bronze — included in all modes).
  CityTier get minCityTier => CityTier.bronze;

  /// The highest city tier included (matches the mode tier).
  CityTier get maxCityTier => CityTier.values[index];

  /// Whether a [CityTier] is visible in this mode.
  bool includesCity(CityTier tier) => tier.index <= index;

  /// Whether a [PlaceTier] is visible in this mode.
  bool includesPlace(PlaceTier tier) => tier.index <= index;

  Color get color => switch (this) {
        TravelMode.bronze => const Color(0xFFCD7F32),
        TravelMode.silver => const Color(0xFFC0C0C0),
        TravelMode.gold   => const Color(0xFFFFD700),
      };

  static TravelMode fromJsonKey(String key) =>
      TravelMode.values.firstWhere(
        (m) => m.jsonKey == key,
        orElse: () => TravelMode.gold,
      );
}

// ---------------------------------------------------------------------------
// CityTier extensions
// ---------------------------------------------------------------------------

extension CityTierX on CityTier {
  String get jsonKey => name;

  static CityTier fromJsonKey(String key) =>
      CityTier.values.firstWhere(
        (t) => t.jsonKey == key,
        orElse: () => CityTier.gold,
      );
}

// ---------------------------------------------------------------------------
// PlaceTier extensions
// ---------------------------------------------------------------------------

extension PlaceTierX on PlaceTier {
  String get jsonKey => name;

  static PlaceTier fromJsonKey(String key) =>
      PlaceTier.values.firstWhere(
        (t) => t.jsonKey == key,
        orElse: () => PlaceTier.gold,
      );
}
