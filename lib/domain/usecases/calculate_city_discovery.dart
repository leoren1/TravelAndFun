// lib/domain/usecases/calculate_city_discovery.dart

import 'package:explore_index/data/models/category.dart';
import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/visit.dart';
import 'package:explore_index/domain/usecases/calculate_category_discovery.dart';

class CalculateCityDiscovery {
  final City city;
  final List<Visit> visits;
  final List<Place> places;

  const CalculateCityDiscovery({
    required this.city,
    required this.visits,
    required this.places,
  });

  /// Returns a value 0.0–100.0
  double execute() {
    final calc = CalculateCategoryDiscovery(
      city: city,
      visits: visits,
      places: places,
    );
    final values =
        CategoryType.values.map((cat) => calc.execute(cat)).toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }
}
