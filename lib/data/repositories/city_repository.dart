// lib/data/repositories/city_repository.dart
// Abstract contract for city data access.

import 'package:explore_index/data/models/city.dart';

abstract class CityRepository {
  /// Returns all cities across all countries.
  Future<List<City>> getAllCities();

  /// Returns the city identified by [id], or null if not found.
  Future<City?> getCityById(String id);

  /// Returns all cities belonging to [countryId].
  Future<List<City>> getCitiesByCountry(String countryId);
}
