// lib/domain/usecases/calculate_country_discovery.dart

import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/country.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/travel_mode.dart';
import 'package:explore_index/data/models/visit.dart';

class CalculateCountryDiscovery {
  final Country country;
  final List<City> cities;
  final List<Visit> visits;
  final List<Place> places;

  /// Only cities/places whose tier is included in [mode] count toward discovery.
  final TravelMode mode;

  const CalculateCountryDiscovery({
    required this.country,
    required this.cities,
    required this.visits,
    required this.places,
    this.mode = TravelMode.gold,
  });

  /// Returns a value 0.0–100.0.
  ///
  /// Formula: mode_verified_in_country / mode_total_in_country × 100
  ///
  /// Only cities AND places visible in the current mode contribute to both
  /// numerator and denominator. Unvisited mode-filtered cities and places
  /// correctly reduce the score toward 0.
  double execute() {
    // Mode-filtered cities in this country.
    final countryCities = cities
        .where((c) => country.cityIds.contains(c.id) && mode.includesCity(c.tier))
        .toList();

    if (countryCities.isEmpty) return 0.0;

    final countryCityIds = countryCities.map((c) => c.id).toSet();

    // Mode-filtered places inside those cities.
    final countryPlaces = places
        .where((p) =>
            countryCityIds.contains(p.cityId) && mode.includesPlace(p.tier))
        .toList();

    if (countryPlaces.isEmpty) return 0.0;

    final placeIds = countryPlaces.map((p) => p.id).toSet();

    final verifiedCount = visits
        .where((v) => v.verified && placeIds.contains(v.placeId))
        .map((v) => v.placeId)
        .toSet()
        .length;

    return (verifiedCount / countryPlaces.length * 100).clamp(0.0, 100.0);
  }
}
