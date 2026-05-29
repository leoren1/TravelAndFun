// lib/domain/usecases/calculate_city_discovery.dart

import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/travel_mode.dart';
import 'package:explore_index/data/models/visit.dart';

class CalculateCityDiscovery {
  final City city;
  final List<Visit> visits;
  final List<Place> places;

  /// Only places whose tier is included in [mode] count toward discovery.
  /// Defaults to [TravelMode.gold] (all places) for backward compatibility.
  final TravelMode mode;

  const CalculateCityDiscovery({
    required this.city,
    required this.visits,
    required this.places,
    this.mode = TravelMode.gold,
  });

  /// Returns a value 0.0–100.0.
  ///
  /// Formula: mode_filtered_verified_places / mode_filtered_total_places × 100
  ///
  /// The denominator is the count of curated places visible in the current mode,
  /// NOT the static [City.categoryTargets] sum. This way Bronze/Silver/Gold modes
  /// each show a meaningful, self-consistent percentage.
  double execute() {
    // Collect places for this city that are visible in the current mode.
    final modePlaces = places
        .where((p) => p.cityId == city.id && mode.includesPlace(p.tier))
        .toList();

    if (modePlaces.isEmpty) return 0.0;

    final modePlaceIds = modePlaces.map((p) => p.id).toSet();

    // Count distinct verified places (a place visited multiple times counts once).
    final verifiedCount = visits
        .where((v) => v.verified && modePlaceIds.contains(v.placeId))
        .map((v) => v.placeId)
        .toSet()
        .length;

    return (verifiedCount / modePlaces.length * 100).clamp(0.0, 100.0);
  }
}
