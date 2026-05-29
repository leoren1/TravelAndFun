// lib/domain/usecases/calculate_category_discovery.dart

import 'package:explore_index/data/models/category.dart';
import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/travel_mode.dart';
import 'package:explore_index/data/models/visit.dart';

class CalculateCategoryDiscovery {
  final City city;
  final List<Visit> visits;
  final List<Place> places;

  /// Only places whose tier is included in [mode] count toward discovery.
  final TravelMode mode;

  const CalculateCategoryDiscovery({
    required this.city,
    required this.visits,
    required this.places,
    this.mode = TravelMode.gold,
  });

  /// Returns a value 0.0–100.0 for [category] within the current mode filter.
  ///
  /// Denominator = number of mode-filtered places in this city+category.
  /// Returns 0 if there are no mode-filtered places in this category.
  double execute(CategoryType category) {
    final catPlaces = places
        .where((p) =>
            p.cityId == city.id &&
            p.category == category &&
            mode.includesPlace(p.tier))
        .toList();

    if (catPlaces.isEmpty) return 0.0;

    final catPlaceIds = catPlaces.map((p) => p.id).toSet();
    final verifiedCount = visits
        .where((v) => v.verified && catPlaceIds.contains(v.placeId))
        .map((v) => v.placeId)
        .toSet()
        .length;

    return (verifiedCount / catPlaces.length * 100).clamp(0.0, 100.0);
  }

  Map<CategoryType, double> executeAll() {
    return {
      for (final cat in CategoryType.values) cat: execute(cat),
    };
  }
}
