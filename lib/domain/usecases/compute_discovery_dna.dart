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
    if (cities.isEmpty || visits.isEmpty) return _empty;

    // Fast lookup: placeId → Place.
    final placeById = {for (final p in places) p.id: p};

    // Fast lookup: cityId → set of CategoryTypes that have at least one place.
    // This lets us decide, per city, which DNA dimensions are "active".
    final cityCategories = <String, Set<CategoryType>>{};
    for (final p in places) {
      cityCategories.putIfAbsent(p.cityId, () => {}).add(p.category);
    }

    // ── Per-dimension accumulators ──────────────────────────────────────
    // Each dimension has its own city counter so that a city visited only for
    // food does not drag down History / Nature / … with a 0% contribution.
    double totalHistory = 0, totalFood = 0, totalNature = 0, totalEvents = 0;
    double totalNightlife = 0, totalLocalExp = 0, totalShopping = 0,
        totalMuseums = 0;
    int histCount = 0, foodCount = 0, natureCount = 0, eventsCount = 0;
    int nightlifeCount = 0, localExpCount = 0, shoppingCount = 0,
        museumsCount = 0;

    for (final city in cities) {
      // Visits for this city only.
      final cityVisits = visits
          .where((v) => placeById[v.placeId]?.cityId == city.id)
          .toList();
      if (cityVisits.isEmpty) continue;

      final cats = cityCategories[city.id] ?? {};
      final calc = CalculateCategoryDiscovery(
        city: city,
        visits: cityVisits,
        places: places,
      );

      // History
      if (cats.contains(CategoryType.historicalPlaces)) {
        totalHistory += calc.execute(CategoryType.historicalPlaces);
        histCount++;
      }

      // Food — 70 % restaurants + 30 % cafés (blended dimension).
      // Include the city if it has either restaurant or café places.
      final hasFood = cats.contains(CategoryType.foodRestaurants) ||
          cats.contains(CategoryType.cafes);
      if (hasFood) {
        totalFood += calc.execute(CategoryType.foodRestaurants) * 0.7 +
            calc.execute(CategoryType.cafes) * 0.3;
        foodCount++;
      }

      // Nature
      if (cats.contains(CategoryType.nature)) {
        totalNature += calc.execute(CategoryType.nature);
        natureCount++;
      }

      // Events
      if (cats.contains(CategoryType.events)) {
        totalEvents += calc.execute(CategoryType.events);
        eventsCount++;
      }

      // Nightlife
      if (cats.contains(CategoryType.nightlife)) {
        totalNightlife += calc.execute(CategoryType.nightlife);
        nightlifeCount++;
      }

      // Local Exp — 50 % routes + 50 % hidden gems (blended dimension).
      final hasLocalExp = cats.contains(CategoryType.routes) ||
          cats.contains(CategoryType.hiddenGems);
      if (hasLocalExp) {
        totalLocalExp += calc.execute(CategoryType.routes) * 0.5 +
            calc.execute(CategoryType.hiddenGems) * 0.5;
        localExpCount++;
      }

      // Shopping
      if (cats.contains(CategoryType.localMarkets)) {
        totalShopping += calc.execute(CategoryType.localMarkets);
        shoppingCount++;
      }

      // Museums
      if (cats.contains(CategoryType.museumsArt)) {
        totalMuseums += calc.execute(CategoryType.museumsArt);
        museumsCount++;
      }
    }

    // Safe per-dimension averages — returns 0 when no city had that category.
    double avg(double total, int count) => count > 0 ? total / count : 0.0;

    final history   = avg(totalHistory,   histCount);
    final food      = avg(totalFood,      foodCount);
    final nature    = avg(totalNature,    natureCount);
    final events    = avg(totalEvents,    eventsCount);
    final nightlife = avg(totalNightlife, nightlifeCount);
    final localExp  = avg(totalLocalExp,  localExpCount);
    final shopping  = avg(totalShopping,  shoppingCount);
    final museums   = avg(totalMuseums,   museumsCount);

    // ── Summary sentence ───────────────────────────────────────────────
    final axes = {
      'cultural': history,
      'food':     food,
      'nature':   nature,
      'events':   events,
      'nightlife': nightlife,
      'local':    localExp,
      'shopping': shopping,
      'museums':  museums,
    };
    final sorted = axes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top1 = sorted[0].key;
    final top2 = sorted[1].key;
    final low1 = sorted[sorted.length - 1].key;
    final low2 = sorted[sorted.length - 2].key;

    final summary =
        'You are a $top1-$top2 traveler. '
        'You usually miss $low1 and $low2 experiences.';

    return DiscoveryDna(
      history:   history,
      food:      food,
      nature:    nature,
      events:    events,
      nightlife: nightlife,
      localExp:  localExp,
      shopping:  shopping,
      museums:   museums,
      summary:   summary,
    );
  }

  static const DiscoveryDna _empty = DiscoveryDna(
    history: 0, food: 0, nature: 0, events: 0,
    nightlife: 0, localExp: 0, shopping: 0, museums: 0,
    summary: 'Start exploring to discover your travel DNA!',
  );
}
