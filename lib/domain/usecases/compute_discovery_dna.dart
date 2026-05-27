// lib/domain/usecases/compute_discovery_dna.dart

import 'package:explore_index/data/models/category.dart';
import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/discovery_dna.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/visit.dart';
import 'package:explore_index/domain/usecases/calculate_category_discovery.dart';

class ComputeDiscoveryDna {
  final List<City> cities;
  final List<Visit> visits;
  final List<Place> places;

  const ComputeDiscoveryDna({
    required this.cities,
    required this.visits,
    required this.places,
  });

  DiscoveryDna execute() {
    if (cities.isEmpty || visits.isEmpty) {
      return const DiscoveryDna(
        history: 0,
        food: 0,
        nature: 0,
        events: 0,
        nightlife: 0,
        localExp: 0,
        shopping: 0,
        museums: 0,
        summary: 'Start exploring to discover your travel DNA!',
      );
    }

    double totalHistory = 0,
        totalFood = 0,
        totalNature = 0,
        totalEvents = 0;
    double totalNightlife = 0,
        totalLocalExp = 0,
        totalShopping = 0,
        totalMuseums = 0;
    int count = 0;

    for (final city in cities) {
      final cityVisits = visits.where((v) {
        final placeMatch =
            places.where((p) => p.id == v.placeId && p.cityId == city.id);
        return placeMatch.isNotEmpty;
      }).toList();
      if (cityVisits.isEmpty) continue;

      final calc = CalculateCategoryDiscovery(
        city: city,
        visits: cityVisits,
        places: places,
      );
      totalHistory += calc.execute(CategoryType.historicalPlaces);
      totalFood += calc.execute(CategoryType.foodRestaurants) * 0.7 +
          calc.execute(CategoryType.cafes) * 0.3;
      totalNature += calc.execute(CategoryType.nature);
      totalEvents += calc.execute(CategoryType.events);
      totalNightlife += calc.execute(CategoryType.nightlife);
      totalLocalExp += calc.execute(CategoryType.routes) * 0.5 +
          calc.execute(CategoryType.hiddenGems) * 0.5;
      totalShopping += calc.execute(CategoryType.localMarkets);
      totalMuseums += calc.execute(CategoryType.museumsArt);
      count++;
    }

    if (count == 0) {
      return const DiscoveryDna(
        history: 0,
        food: 0,
        nature: 0,
        events: 0,
        nightlife: 0,
        localExp: 0,
        shopping: 0,
        museums: 0,
        summary: 'Start exploring to discover your travel DNA!',
      );
    }

    final history = totalHistory / count;
    final food = totalFood / count;
    final nature = totalNature / count;
    final events = totalEvents / count;
    final nightlife = totalNightlife / count;
    final localExp = totalLocalExp / count;
    final shopping = totalShopping / count;
    final museums = totalMuseums / count;

    final axes = {
      'cultural': history,
      'food': food,
      'nature': nature,
      'events': events,
      'nightlife': nightlife,
      'local': localExp,
      'shopping': shopping,
      'museums': museums,
    };
    final sorted = axes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top1 = sorted[0].key;
    final top2 = sorted[1].key;
    final low1 = sorted[sorted.length - 1].key;
    final low2 = sorted[sorted.length - 2].key;

    final summary =
        'You are a $top1-$top2 traveler. You usually miss $low1 and $low2 experiences.';

    return DiscoveryDna(
      history: history,
      food: food,
      nature: nature,
      events: events,
      nightlife: nightlife,
      localExp: localExp,
      shopping: shopping,
      museums: museums,
      summary: summary,
    );
  }
}
