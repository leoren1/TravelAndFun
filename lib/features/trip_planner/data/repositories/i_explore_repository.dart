// Abstract repository interface for exploration data
import 'package:explore_index/features/trip_planner/data/models/explore_category.dart';
import 'package:explore_index/features/trip_planner/data/models/explore_city.dart';
import 'package:explore_index/features/trip_planner/data/models/explore_country.dart';
import 'package:explore_index/features/trip_planner/data/models/explore_place.dart';

abstract interface class IExploreRepository {
  List<ExploreCountry> getAllCountries();
  ExploreCountry? getCountryById(String id);
  List<ExploreCity> getCitiesForCountry(String countryId);
  List<ExploreCity> getTrendingCities({int limit = 6});
  ExploreCity? getCityById(String id);
  List<ExploreCategory> getCategoriesForCity(String cityId);
  List<ExplorePlace> getPlacesForCity(String cityId);
  List<ExplorePlace> getPlacesForCityAndCategory(
      String cityId, String categoryId);
  ExplorePlace? getPlaceById(String id);
  List<ExplorePlace> getNearbyPlaces(String placeId, {int limit = 5});
  List<ExplorePlace> getHighlightPlacesForCity(String cityId, {int limit = 4});
  List<ExploreCity> getFeaturedCities({int limit = 8});
}
