// lib/data/repositories/place_repository_impl.dart
// StaticDataService-backed implementation of PlaceRepository.

import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/repositories/place_repository.dart';
import 'package:explore_index/data/services/static_data_service.dart';

class PlaceRepositoryImpl implements PlaceRepository {
  const PlaceRepositoryImpl(this._dataService);

  final StaticDataService _dataService;

  @override
  Future<List<Place>> getAllPlaces() => _dataService.getPlaces();

  @override
  Future<List<Place>> getPlacesByCity(String cityId) =>
      _dataService.getPlacesByCity(cityId);

  @override
  Future<List<Place>> getPlacesByCityAndCategory(
    String cityId,
    String categoryKey,
  ) =>
      _dataService.getPlacesByCityAndCategory(cityId, categoryKey);

  @override
  Future<Place?> getPlaceById(String id) => _dataService.getPlaceById(id);
}
