// lib/data/repositories/city_repository_impl.dart
// StaticDataService-backed implementation of CityRepository.

import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/repositories/city_repository.dart';
import 'package:explore_index/data/services/static_data_service.dart';

class CityRepositoryImpl implements CityRepository {
  const CityRepositoryImpl(this._dataService);

  final StaticDataService _dataService;

  @override
  Future<List<City>> getAllCities() => _dataService.getCities();

  @override
  Future<City?> getCityById(String id) => _dataService.getCityById(id);

  @override
  Future<List<City>> getCitiesByCountry(String countryId) =>
      _dataService.getCitiesByCountry(countryId);
}
