// lib/domain/usecases/calculate_country_discovery.dart

import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/country.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/visit.dart';
import 'package:explore_index/domain/usecases/calculate_city_discovery.dart';

class CalculateCountryDiscovery {
  final Country country;
  final List<City> cities;
  final List<Visit> visits;
  final List<Place> places;

  const CalculateCountryDiscovery({
    required this.country,
    required this.cities,
    required this.visits,
    required this.places,
  });

  double execute() {
    final countryCities =
        cities.where((c) => country.cityIds.contains(c.id)).toList();
    if (countryCities.isEmpty) return 0;

    final cityDiscoveries = countryCities.map((city) {
      final cityVisits = visits.where((v) {
        final place = places.firstWhere(
          (p) => p.id == v.placeId,
          orElse: () => places.first,
        );
        return place.cityId == city.id;
      }).toList();
      return CalculateCityDiscovery(
        city: city,
        visits: cityVisits,
        places: places,
      ).execute();
    }).toList();

    return cityDiscoveries.reduce((a, b) => a + b) / cityDiscoveries.length;
  }
}
