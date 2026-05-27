// lib/data/repositories/country_repository.dart
// Abstract contract for country data access.

import 'package:explore_index/data/models/country.dart';

abstract class CountryRepository {
  /// Returns all available countries.
  Future<List<Country>> getAllCountries();

  /// Returns the country identified by [id], or null if not found.
  Future<Country?> getCountryById(String id);
}
