// lib/domain/usecases/calculate_world_discovery.dart

import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/country.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/visit.dart';
import 'package:explore_index/domain/usecases/calculate_country_discovery.dart';

class CalculateWorldDiscovery {
  final List<Country> countries;
  final List<City> cities;
  final List<Visit> visits;
  final List<Place> places;

  const CalculateWorldDiscovery({
    required this.countries,
    required this.cities,
    required this.visits,
    required this.places,
  });

  double execute() {
    if (countries.isEmpty) return 0;

    final discoveries = countries
        .map(
          (country) => CalculateCountryDiscovery(
            country: country,
            cities: cities,
            visits: visits,
            places: places,
          ).execute(),
        )
        .toList();

    return discoveries.reduce((a, b) => a + b) / discoveries.length;
  }
}
