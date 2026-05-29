// lib/domain/services/mode_filter_service.dart
//
// Filters cities and places by the current [TravelMode].
// The hierarchy is inclusive: Bronze ⊆ Silver ⊆ Gold.

import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/travel_mode.dart';

class ModeFilterService {
  const ModeFilterService();

  // ── Cities ────────────────────────────────────────────────────────────────

  /// Returns cities whose tier is included in [mode].
  List<City> filterCities(List<City> cities, TravelMode mode) =>
      cities.where((c) => mode.includesCity(c.tier)).toList();

  // ── Places ────────────────────────────────────────────────────────────────

  /// Returns places whose tier is included in [mode].
  List<Place> filterPlaces(List<Place> places, TravelMode mode) =>
      places.where((p) => mode.includesPlace(p.tier)).toList();

  /// Returns places belonging to [cityId] that are included in [mode].
  List<Place> filterPlacesForCity(
    List<Place> places,
    String cityId,
    TravelMode mode,
  ) =>
      places
          .where((p) => p.cityId == cityId && mode.includesPlace(p.tier))
          .toList();
}
