import 'package:explore_index/features/trip_planner/data/models/explore_category.dart';
import 'package:explore_index/features/trip_planner/data/models/explore_city.dart';
import 'package:explore_index/features/trip_planner/data/models/explore_country.dart';
import 'package:explore_index/features/trip_planner/data/models/explore_place.dart';
import 'package:explore_index/features/trip_planner/data/repositories/i_explore_repository.dart';
import 'package:explore_index/features/trip_planner/data/static/explore_static_data.dart';

class ExploreRepositoryImpl implements IExploreRepository {
  const ExploreRepositoryImpl();

  @override
  List<ExploreCountry> getAllCountries() =>
      ExploreStaticData.featuredCountries();

  @override
  ExploreCountry? getCountryById(String id) =>
      ExploreStaticData.countryById(id);

  @override
  List<ExploreCity> getCitiesForCountry(String countryId) =>
      ExploreStaticData.citiesForCountry(countryId);

  @override
  List<ExploreCity> getTrendingCities({int limit = 6}) {
    final trending = ExploreStaticData.trendingCities();
    trending.sort((a, b) => b.travelScore.compareTo(a.travelScore));
    return trending.take(limit).toList();
  }

  @override
  ExploreCity? getCityById(String id) => ExploreStaticData.cityById(id);

  @override
  List<ExploreCategory> getCategoriesForCity(String cityId) =>
      ExploreStaticData.categoriesForCity(cityId);

  @override
  List<ExplorePlace> getPlacesForCity(String cityId) {
    final result = ExploreStaticData.placesForCity(cityId);
    result.sort((a, b) {
      // Highlights first, then by rating descending
      if (a.isHighlight && !b.isHighlight) return -1;
      if (!a.isHighlight && b.isHighlight) return 1;
      return b.rating.compareTo(a.rating);
    });
    return result;
  }

  @override
  List<ExplorePlace> getPlacesForCityAndCategory(
      String cityId, String categoryId) {
    final result =
        ExploreStaticData.placesForCityAndCategory(cityId, categoryId);
    result.sort((a, b) => b.rating.compareTo(a.rating));
    return result;
  }

  @override
  ExplorePlace? getPlaceById(String id) => ExploreStaticData.placeById(id);

  @override
  List<ExplorePlace> getNearbyPlaces(String placeId, {int limit = 5}) =>
      ExploreStaticData.nearbyPlaces(placeId, limit: limit);

  @override
  List<ExplorePlace> getHighlightPlacesForCity(String cityId,
      {int limit = 4}) {
    final highlights = ExploreStaticData.placesForCity(cityId)
        .where((p) => p.isHighlight)
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return highlights.take(limit).toList();
  }

  @override
  List<ExploreCity> getFeaturedCities({int limit = 8}) {
    final featured =
        ExploreStaticData.cities.where((c) => c.isFeatured).toList()
          ..sort((a, b) => b.travelScore.compareTo(a.travelScore));
    return featured.take(limit).toList();
  }
}
