// lib/data/repositories/country_repository_impl.dart
// StaticDataService-backed implementation of CountryRepository.

import 'package:explore_index/data/models/country.dart';
import 'package:explore_index/data/repositories/country_repository.dart';
import 'package:explore_index/data/services/static_data_service.dart';

class CountryRepositoryImpl implements CountryRepository {
  const CountryRepositoryImpl(this._dataService);

  final StaticDataService _dataService;

  @override
  Future<List<Country>> getAllCountries() => _dataService.getCountries();

  @override
  Future<Country?> getCountryById(String id) =>
      _dataService.getCountryById(id);
}
