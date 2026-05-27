// lib/domain/usecases/award_badges.dart

import 'package:explore_index/data/models/category.dart';
import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/visit.dart';
import 'package:explore_index/domain/usecases/calculate_category_discovery.dart';
import 'package:explore_index/domain/usecases/calculate_city_discovery.dart';

class _BadgeDef {
  final String id;
  final CategoryType category;
  final double threshold;

  const _BadgeDef(this.id, this.category, this.threshold);
}

class AwardBadges {
  static final List<_BadgeDef> _definitions = [
    _BadgeDef('food_explorer', CategoryType.foodRestaurants, 60),
    _BadgeDef('museum_collector', CategoryType.museumsArt, 60),
    _BadgeDef('nightlife_seeker', CategoryType.nightlife, 60),
    _BadgeDef('hidden_gem_finder', CategoryType.hiddenGems, 50),
    _BadgeDef('history_buff', CategoryType.historicalPlaces, 70),
    _BadgeDef('coffee_connoisseur', CategoryType.cafes, 70),
    _BadgeDef('nature_wanderer', CategoryType.nature, 60),
    _BadgeDef('market_hunter', CategoryType.localMarkets, 50),
  ];

  final List<City> cities;
  final List<Visit> visits;
  final List<Place> places;
  final List<String> alreadyAwarded;

  const AwardBadges({
    required this.cities,
    required this.visits,
    required this.places,
    required this.alreadyAwarded,
  });

  List<String> execute() {
    final newBadges = <String>[];

    for (final city in cities) {
      final cityVisits = visits.where((v) {
        final match =
            places.where((p) => p.id == v.placeId && p.cityId == city.id);
        return match.isNotEmpty;
      }).toList();

      final calc = CalculateCategoryDiscovery(
        city: city,
        visits: cityVisits,
        places: places,
      );

      for (final def in _definitions) {
        if (!alreadyAwarded.contains(def.id)) {
          final pct = calc.execute(def.category);
          if (pct >= def.threshold) {
            newBadges.add(def.id);
          }
        }
      }

      // City completer badge — awarded when a city is 90%+ discovered.
      if (!alreadyAwarded.contains('city_completer')) {
        final cityDisc = CalculateCityDiscovery(
          city: city,
          visits: cityVisits,
          places: places,
        ).execute();
        if (cityDisc >= 90) newBadges.add('city_completer');
      }
    }

    // Globetrotter — visited places in 3 or more distinct countries.
    if (!alreadyAwarded.contains('globetrotter')) {
      final visitedCityIds = visits.map((v) {
        final place = places.firstWhere(
          (p) => p.id == v.placeId,
          orElse: () => places.first,
        );
        return place.cityId;
      }).toSet();

      final visitedCountryIds = cities
          .where((c) => visitedCityIds.contains(c.id))
          .map((c) => c.countryId)
          .toSet();

      if (visitedCountryIds.length >= 3) newBadges.add('globetrotter');
    }

    return newBadges.toSet().difference(alreadyAwarded.toSet()).toList();
  }
}
