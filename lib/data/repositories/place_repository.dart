// lib/data/repositories/place_repository.dart
// Abstract contract for place data access.

import 'package:explore_index/data/models/place.dart';

abstract class PlaceRepository {
  /// Returns all places across all cities.
  Future<List<Place>> getAllPlaces();

  /// Returns all places belonging to [cityId].
  Future<List<Place>> getPlacesByCity(String cityId);

  /// Returns places in [cityId] filtered by [categoryKey].
  Future<List<Place>> getPlacesByCityAndCategory(
    String cityId,
    String categoryKey,
  );

  /// Returns the place identified by [id], or null if not found.
  Future<Place?> getPlaceById(String id);
}
