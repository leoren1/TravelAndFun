// test/domain/calculate_city_discovery_test.dart
//
// Tests for CalculateCategoryDiscovery and CalculateCityDiscovery.
// Run with: flutter test test/domain/calculate_city_discovery_test.dart

import 'package:explore_index/data/models/category.dart';
import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/visit.dart';
import 'package:explore_index/domain/usecases/calculate_category_discovery.dart';
import 'package:explore_index/domain/usecases/calculate_city_discovery.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Default categoryTargets matching the static data fixture (10 categories,
/// 86 total target places).
const Map<String, int> _defaultTargets = {
  'historicalPlaces': 10,
  'foodRestaurants': 10,
  'cafes': 10,
  'museumsArt': 10,
  'routes': 8,
  'nature': 6,
  'nightlife': 8,
  'localMarkets': 6,
  'hiddenGems': 10,
  'events': 8,
};

City _makeCity({Map<String, int>? targets}) => City(
      id: 'test_city',
      name: 'Test City',
      countryId: 'tc',
      heroImage: '',
      latitude: 0,
      longitude: 0,
      categoryTargets: targets ?? _defaultTargets,
    );

Place _makePlace(String id, CategoryType cat, {String cityId = 'test_city'}) =>
    Place(
      id: id,
      name: id,
      description: '',
      image: '',
      cityId: cityId,
      category: cat,
      tags: [],
      latitude: 0,
      longitude: 0,
      discoveryBoost: 5.0,
    );

Visit _makeVerifiedVisit(String placeId) => Visit(
      id: 'v_$placeId',
      placeId: placeId,
      userId: 'user_1',
      visitedAt: DateTime(2024, 6, 1),
      photoPath: '/photos/$placeId.jpg',
      photoLatitude: 0,
      photoLongitude: 0,
      photoTakenAt: DateTime(2024, 6, 1),
      rating: 4,
      verified: true,
    );

Visit _makeUnverifiedVisit(String placeId) => Visit(
      id: 'uv_$placeId',
      placeId: placeId,
      userId: 'user_1',
      visitedAt: DateTime(2024, 6, 1),
      photoPath: '/photos/$placeId.jpg',
      photoLatitude: 0,
      photoLongitude: 0,
      photoTakenAt: DateTime(2024, 6, 1),
      rating: 3,
      verified: false,
    );

// ---------------------------------------------------------------------------
// CalculateCategoryDiscovery tests
// ---------------------------------------------------------------------------

void main() {
  group('CalculateCategoryDiscovery', () {
    // ── 1. No visits ──────────────────────────────────────────────────────

    test('returns 0.0 when visits list is empty', () {
      final city = _makeCity();
      final places = [_makePlace('p1', CategoryType.historicalPlaces)];
      final calc = CalculateCategoryDiscovery(
        city: city,
        visits: [],
        places: places,
      );
      expect(calc.execute(CategoryType.historicalPlaces), 0.0);
    });

    test('returns 0.0 when places list is empty', () {
      final city = _makeCity();
      final calc = CalculateCategoryDiscovery(
        city: city,
        visits: [_makeVerifiedVisit('p1')],
        places: [],
      );
      expect(calc.execute(CategoryType.historicalPlaces), 0.0);
    });

    // ── 2. Full category completion ───────────────────────────────────────

    test('returns 100.0 when verified visits equal the category target', () {
      // target = 2, places = 2, both visited
      final city = _makeCity(targets: {
        'historicalPlaces': 2,
        'foodRestaurants': 10,
        'cafes': 10,
        'museumsArt': 10,
        'routes': 8,
        'nature': 6,
        'nightlife': 8,
        'localMarkets': 6,
        'hiddenGems': 10,
        'events': 8,
      });
      final places = [
        _makePlace('p1', CategoryType.historicalPlaces),
        _makePlace('p2', CategoryType.historicalPlaces),
      ];
      final visits = [_makeVerifiedVisit('p1'), _makeVerifiedVisit('p2')];
      final calc = CalculateCategoryDiscovery(
        city: city,
        visits: visits,
        places: places,
      );
      expect(calc.execute(CategoryType.historicalPlaces), 100.0);
    });

    // ── 3. Partial completion (50 %) ─────────────────────────────────────

    test('returns 50.0 when half of the target places are verified', () {
      // target = 4, 2 verified visits → 50 %
      final city = _makeCity(targets: {
        'historicalPlaces': 4,
        'foodRestaurants': 10,
        'cafes': 10,
        'museumsArt': 10,
        'routes': 8,
        'nature': 6,
        'nightlife': 8,
        'localMarkets': 6,
        'hiddenGems': 10,
        'events': 8,
      });
      final places = [
        _makePlace('p1', CategoryType.historicalPlaces),
        _makePlace('p2', CategoryType.historicalPlaces),
      ];
      final visits = [_makeVerifiedVisit('p1'), _makeVerifiedVisit('p2')];
      final calc = CalculateCategoryDiscovery(
        city: city,
        visits: visits,
        places: places,
      );
      expect(calc.execute(CategoryType.historicalPlaces), 50.0);
    });

    // ── 4. Target = 10, 1 verified visit → 10 % ──────────────────────────

    test('returns 10.0 when 1 of 10 target places is verified', () {
      final city = _makeCity(); // historicalPlaces target = 10
      final places = List.generate(
        5,
        (i) => _makePlace('p$i', CategoryType.historicalPlaces),
      );
      final visits = [_makeVerifiedVisit('p0')];
      final calc = CalculateCategoryDiscovery(
        city: city,
        visits: visits,
        places: places,
      );
      expect(calc.execute(CategoryType.historicalPlaces), 10.0);
    });

    // ── 5. Clamping: verified visits exceed the target ─────────────────

    test('clamps to 100.0 when verified visits exceed the target', () {
      // target = 1, but 2 distinct places verified
      final city = _makeCity(targets: {
        'historicalPlaces': 1,
        'foodRestaurants': 10,
        'cafes': 10,
        'museumsArt': 10,
        'routes': 8,
        'nature': 6,
        'nightlife': 8,
        'localMarkets': 6,
        'hiddenGems': 10,
        'events': 8,
      });
      final places = [
        _makePlace('p1', CategoryType.historicalPlaces),
        _makePlace('p2', CategoryType.historicalPlaces),
      ];
      final visits = [_makeVerifiedVisit('p1'), _makeVerifiedVisit('p2')];
      final calc = CalculateCategoryDiscovery(
        city: city,
        visits: visits,
        places: places,
      );
      expect(calc.execute(CategoryType.historicalPlaces), 100.0);
    });

    // ── 6. Unverified visits must not count ───────────────────────────────

    test('unverified visits are ignored', () {
      final city = _makeCity();
      final places = [_makePlace('p1', CategoryType.historicalPlaces)];
      final calc = CalculateCategoryDiscovery(
        city: city,
        visits: [_makeUnverifiedVisit('p1')],
        places: places,
      );
      expect(calc.execute(CategoryType.historicalPlaces), 0.0);
    });

    // ── 7. Duplicate verified visits for the same place count once ────────

    test('duplicate verified visits for the same place are deduplicated', () {
      // target = 4, same place visited twice → still 1 unique place → 25 %
      final city = _makeCity(targets: {
        'historicalPlaces': 4,
        'foodRestaurants': 10,
        'cafes': 10,
        'museumsArt': 10,
        'routes': 8,
        'nature': 6,
        'nightlife': 8,
        'localMarkets': 6,
        'hiddenGems': 10,
        'events': 8,
      });
      final places = [_makePlace('p1', CategoryType.historicalPlaces)];
      final visits = [
        _makeVerifiedVisit('p1').copyWith(id: 'v1a'),
        _makeVerifiedVisit('p1').copyWith(id: 'v1b'),
      ];
      final calc = CalculateCategoryDiscovery(
        city: city,
        visits: visits,
        places: places,
      );
      expect(calc.execute(CategoryType.historicalPlaces), 25.0);
    });

    // ── 8. Places from a different city are not counted ───────────────────

    test('places belonging to a different city are excluded', () {
      final city = _makeCity(); // id = 'test_city'
      final places = [
        _makePlace('p1', CategoryType.historicalPlaces, cityId: 'other_city'),
      ];
      final visits = [_makeVerifiedVisit('p1')];
      final calc = CalculateCategoryDiscovery(
        city: city,
        visits: visits,
        places: places,
      );
      expect(calc.execute(CategoryType.historicalPlaces), 0.0);
    });

    // ── 9. Category isolation ─────────────────────────────────────────────

    test('visits in one category do not affect a different category', () {
      final city = _makeCity();
      final places = [
        _makePlace('p1', CategoryType.foodRestaurants),
        _makePlace('p2', CategoryType.historicalPlaces),
      ];
      final visits = [_makeVerifiedVisit('p1')]; // only food
      final calc = CalculateCategoryDiscovery(
        city: city,
        visits: visits,
        places: places,
      );
      // historicalPlaces target = 10, 0 verified → 0 %
      expect(calc.execute(CategoryType.historicalPlaces), 0.0);
      // foodRestaurants target = 10, 1 verified → 10 %
      expect(calc.execute(CategoryType.foodRestaurants), 10.0);
    });

    // ── 10. executeAll returns a map for every CategoryType ───────────────

    test('executeAll returns a value for every CategoryType', () {
      final city = _makeCity();
      final calc = CalculateCategoryDiscovery(
        city: city,
        visits: [],
        places: [],
      );
      final result = calc.executeAll();
      expect(result.keys.toSet(), CategoryType.values.toSet());
      expect(result.values, everyElement(0.0));
    });
  });

  // -------------------------------------------------------------------------
  // CalculateCityDiscovery tests
  // -------------------------------------------------------------------------

  group('CalculateCityDiscovery', () {
    // ── 1. Empty visits → 0 % ─────────────────────────────────────────────

    test('returns 0.0 when visits list is empty', () {
      final city = _makeCity();
      final result =
          CalculateCityDiscovery(city: city, visits: [], places: []).execute();
      expect(result, 0.0);
    });

    // ── 2. Mean across all 10 categories ──────────────────────────────────

    test('returns mean of all 10 category scores', () {
      // 1 verified visit on a historicalPlaces place
      // target = 10 → historicalPlaces = 10 %, all others = 0 %
      // mean = 10 / 10 = 1.0
      final city = _makeCity(); // all targets default to 6–10
      final places = [_makePlace('p1', CategoryType.historicalPlaces)];
      final visits = [_makeVerifiedVisit('p1')];
      final result = CalculateCityDiscovery(
        city: city,
        visits: visits,
        places: places,
      ).execute();
      expect(result, closeTo(1.0, 0.01));
    });

    // ── 3. All categories at 100 % → city = 100 % ─────────────────────────

    test('returns 100.0 when every category is fully discovered', () {
      // Give each category a target of 1 and provide 1 verified visit per place.
      final targets = {
        for (final cat in CategoryType.values) cat.jsonKey: 1,
      };
      final city = _makeCity(targets: targets);
      final places = CategoryType.values
          .map((cat) => _makePlace(cat.jsonKey, cat))
          .toList();
      final visits = places.map((p) => _makeVerifiedVisit(p.id)).toList();
      final result = CalculateCityDiscovery(
        city: city,
        visits: visits,
        places: places,
      ).execute();
      expect(result, 100.0);
    });

    // ── 4. Two categories partially filled ────────────────────────────────

    test('averages correctly with two partially filled categories', () {
      // historicalPlaces target = 4, 2 verified → 50 %
      // foodRestaurants target = 4, 1 verified  → 25 %
      // All 8 remaining categories → 0 %
      // Expected mean = (50 + 25) / 10 = 7.5
      final city = _makeCity(targets: {
        'historicalPlaces': 4,
        'foodRestaurants': 4,
        'cafes': 10,
        'museumsArt': 10,
        'routes': 8,
        'nature': 6,
        'nightlife': 8,
        'localMarkets': 6,
        'hiddenGems': 10,
        'events': 8,
      });
      final places = [
        _makePlace('h1', CategoryType.historicalPlaces),
        _makePlace('h2', CategoryType.historicalPlaces),
        _makePlace('f1', CategoryType.foodRestaurants),
      ];
      final visits = [
        _makeVerifiedVisit('h1'),
        _makeVerifiedVisit('h2'),
        _makeVerifiedVisit('f1'),
      ];
      final result = CalculateCityDiscovery(
        city: city,
        visits: visits,
        places: places,
      ).execute();
      expect(result, closeTo(7.5, 0.01));
    });

    // ── 5. Unverified visits do not contribute ────────────────────────────

    test('unverified visits yield 0.0 city discovery', () {
      final city = _makeCity();
      final places = [_makePlace('p1', CategoryType.nature)];
      final visits = [_makeUnverifiedVisit('p1')];
      final result = CalculateCityDiscovery(
        city: city,
        visits: visits,
        places: places,
      ).execute();
      expect(result, 0.0);
    });

    // ── 6. categoryTargets division is respected ──────────────────────────

    test('categoryTargets value is used as the denominator for each category', () {
      // nature target = 2, 1 verified → 50 %
      // All other targets = 1, no visits → 0 %
      // mean = 50 / 10 = 5.0
      final city = _makeCity(targets: {
        'historicalPlaces': 1,
        'foodRestaurants': 1,
        'cafes': 1,
        'museumsArt': 1,
        'routes': 1,
        'nature': 2,
        'nightlife': 1,
        'localMarkets': 1,
        'hiddenGems': 1,
        'events': 1,
      });
      final places = [_makePlace('n1', CategoryType.nature)];
      final visits = [_makeVerifiedVisit('n1')];
      final result = CalculateCityDiscovery(
        city: city,
        visits: visits,
        places: places,
      ).execute();
      expect(result, closeTo(5.0, 0.01));
    });
  });
}
