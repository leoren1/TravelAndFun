// lib/domain/usecases/calculate_world_discovery.dart

import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/country.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/travel_mode.dart';
import 'package:explore_index/data/models/visit.dart';

class CalculateWorldDiscovery {
  final List<Country> countries;
  final List<City> cities;
  final List<Visit> visits;
  final List<Place> places;

  /// Only cities/places whose tier is included in [mode] count toward discovery.
  final TravelMode mode;

  const CalculateWorldDiscovery({
    required this.countries,
    required this.cities,
    required this.visits,
    required this.places,
    this.mode = TravelMode.gold,
  });

  /// Returns a value 0.0–100.0.
  ///
  /// Formula: mode_verified_globally / mode_total_globally × 100
  ///
  /// Only mode-filtered cities and places are included. This means:
  ///  - Bronze mode denominator = count of bronze places in bronze cities
  ///  - Silver mode denominator = bronze+silver places in bronze+silver cities
  ///  - Gold mode denominator   = all places in all cities
  double execute() {
    if (cities.isEmpty) return 0.0;

    // Mode-filtered cities.
    final modeCityIds =
        cities.where((c) => mode.includesCity(c.tier)).map((c) => c.id).toSet();

    // Mode-filtered places inside those cities.
    final modePlaces = places
        .where((p) => modeCityIds.contains(p.cityId) && mode.includesPlace(p.tier))
        .toList();

    if (modePlaces.isEmpty) return 0.0;

    final placeIds = modePlaces.map((p) => p.id).toSet();

    final verifiedCount = visits
        .where((v) => v.verified && placeIds.contains(v.placeId))
        .map((v) => v.placeId)
        .toSet()
        .length;

    return (verifiedCount / modePlaces.length * 100).clamp(0.0, 100.0);
  }
}
