// lib/domain/usecases/calculate_category_discovery.dart

import 'package:explore_index/data/models/category.dart';
import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/visit.dart';
import 'package:explore_index/data/models/place.dart';

class CalculateCategoryDiscovery {
  final City city;
  final List<Visit> visits;
  final List<Place> places;

  const CalculateCategoryDiscovery({
    required this.city,
    required this.visits,
    required this.places,
  });

  /// Returns a value 0.0–100.0
  double execute(CategoryType category) {
    final target = city.categoryTargets[category.jsonKey] ?? 10;
    if (target == 0) return 0;

    final categoryPlaceIds = places
        .where((p) => p.cityId == city.id && p.category == category)
        .map((p) => p.id)
        .toSet();

    final verifiedCount = visits
        .where((v) => v.verified && categoryPlaceIds.contains(v.placeId))
        .map((v) => v.placeId)
        .toSet()
        .length;

    return (verifiedCount / target * 100).clamp(0.0, 100.0);
  }

  Map<CategoryType, double> executeAll() {
    return {
      for (final cat in CategoryType.values) cat: execute(cat),
    };
  }
}
