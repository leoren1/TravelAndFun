// test/domain/compute_discovery_dna_test.dart
//
// Tests for ComputeDiscoveryDna.
// Run with: flutter test test/domain/compute_discovery_dna_test.dart

import 'package:explore_index/data/models/category.dart';
import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/discovery_dna.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/visit.dart';
import 'package:explore_index/domain/usecases/compute_discovery_dna.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

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

City _makeCity(String id, {Map<String, int>? targets}) => City(
      id: id,
      name: 'City $id',
      countryId: 'country_1',
      heroImage: '',
      latitude: 0,
      longitude: 0,
      categoryTargets: targets ?? _defaultTargets,
    );

Place _makePlace(String id, CategoryType cat, String cityId) => Place(
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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ComputeDiscoveryDna', () {
    // ── 1. Empty data returns an all-zero DiscoveryDna ────────────────────

    test('returns all-zero DNA when cities list is empty', () {
      final dna = ComputeDiscoveryDna(
        cities: [],
        visits: [],
        places: [],
      ).execute();

      _expectAllZero(dna);
      expect(dna.summary, isNotEmpty);
    });

    test('returns all-zero DNA when visits list is empty', () {
      final city = _makeCity('c1');
      final places = [_makePlace('p1', CategoryType.foodRestaurants, 'c1')];

      final dna = ComputeDiscoveryDna(
        cities: [city],
        visits: [],
        places: places,
      ).execute();

      _expectAllZero(dna);
    });

    test('returns all-zero DNA when both cities and visits are empty', () {
      final dna = ComputeDiscoveryDna(
        cities: [],
        visits: [],
        places: [],
      ).execute();

      _expectAllZero(dna);
    });

    // ── 2. Food visits increase the food axis ─────────────────────────────

    test('food axis is non-zero after verified food restaurant visits', () {
      // target foodRestaurants = 2, visit both → 100 % food contribution
      final city = _makeCity('c1', targets: {
        'historicalPlaces': 10,
        'foodRestaurants': 2,
        'cafes': 10,
        'museumsArt': 10,
        'routes': 10,
        'nature': 10,
        'nightlife': 10,
        'localMarkets': 10,
        'hiddenGems': 10,
        'events': 10,
      });
      final places = [
        _makePlace('f1', CategoryType.foodRestaurants, 'c1'),
        _makePlace('f2', CategoryType.foodRestaurants, 'c1'),
      ];
      final visits = [_makeVerifiedVisit('f1'), _makeVerifiedVisit('f2')];

      final dna = ComputeDiscoveryDna(
        cities: [city],
        visits: visits,
        places: places,
      ).execute();

      expect(dna.food, greaterThan(0));
    });

    test('food axis reflects only food-related category visits', () {
      // Visit 1 food restaurant and 0 cafes.
      // food = foodRestaurants * 0.7 + cafes * 0.3
      // With target 2 and 1 visit → foodRestaurants = 50 %, cafes = 0 %
      // food = 50 * 0.7 + 0 * 0.3 = 35
      final city = _makeCity('c1', targets: {
        'historicalPlaces': 10,
        'foodRestaurants': 2,
        'cafes': 2,
        'museumsArt': 10,
        'routes': 10,
        'nature': 10,
        'nightlife': 10,
        'localMarkets': 10,
        'hiddenGems': 10,
        'events': 10,
      });
      final places = [
        _makePlace('f1', CategoryType.foodRestaurants, 'c1'),
        _makePlace('f2', CategoryType.foodRestaurants, 'c1'),
      ];
      final visits = [_makeVerifiedVisit('f1')];

      final dna = ComputeDiscoveryDna(
        cities: [city],
        visits: visits,
        places: places,
      ).execute();

      expect(dna.food, closeTo(35.0, 0.1));
    });

    // ── 3. History axis is non-zero after historical visits ───────────────

    test('history axis is non-zero after verified historicalPlaces visits', () {
      final city = _makeCity('c1', targets: {
        'historicalPlaces': 1,
        'foodRestaurants': 10,
        'cafes': 10,
        'museumsArt': 10,
        'routes': 10,
        'nature': 10,
        'nightlife': 10,
        'localMarkets': 10,
        'hiddenGems': 10,
        'events': 10,
      });
      final places = [_makePlace('h1', CategoryType.historicalPlaces, 'c1')];
      final visits = [_makeVerifiedVisit('h1')];

      final dna = ComputeDiscoveryDna(
        cities: [city],
        visits: visits,
        places: places,
      ).execute();

      expect(dna.history, greaterThan(0));
    });

    // ── 4. City with no matching visits contributes zero ─────────────────

    test('city with no matching visits is skipped (all axes remain zero)', () {
      final cityA = _makeCity('city_a');
      final cityB = _makeCity('city_b');

      // Place and visit are for city_a only; city_b has no matching visits.
      final places = [_makePlace('p1', CategoryType.nature, 'city_a')];
      final visits = [_makeVerifiedVisit('p1')];

      // Pass both cities but only city_a contributes.
      final dnaA = ComputeDiscoveryDna(
        cities: [cityA],
        visits: visits,
        places: places,
      ).execute();

      final dnaBoth = ComputeDiscoveryDna(
        cities: [cityA, cityB],
        visits: visits,
        places: places,
      ).execute();

      // city_b is skipped (no visits) so the mean is still computed from city_a only.
      expect(dnaBoth.nature, closeTo(dnaA.nature, 0.01));
    });

    // ── 5. Summary is populated and meaningful ────────────────────────────

    test('summary string is non-empty and contains traveler description', () {
      final city = _makeCity('c1', targets: {
        'historicalPlaces': 1,
        'foodRestaurants': 1,
        'cafes': 10,
        'museumsArt': 10,
        'routes': 10,
        'nature': 10,
        'nightlife': 10,
        'localMarkets': 10,
        'hiddenGems': 10,
        'events': 10,
      });
      final places = [
        _makePlace('h1', CategoryType.historicalPlaces, 'c1'),
        _makePlace('f1', CategoryType.foodRestaurants, 'c1'),
      ];
      final visits = [_makeVerifiedVisit('h1'), _makeVerifiedVisit('f1')];

      final dna = ComputeDiscoveryDna(
        cities: [city],
        visits: visits,
        places: places,
      ).execute();

      expect(dna.summary, isNotEmpty);
      // With real visits the summary should describe the traveler, not the
      // placeholder "Start exploring" message.
      expect(
        dna.summary,
        isNot('Start exploring to discover your travel DNA!'),
      );
    });

    // ── 6. Dimensions map exposes all 8 axes ──────────────────────────────

    test('dimensions map contains all 8 labelled axes', () {
      final dna = ComputeDiscoveryDna(
        cities: [],
        visits: [],
        places: [],
      ).execute();

      expect(dna.dimensions.keys, containsAll([
        'History',
        'Food',
        'Nature',
        'Events',
        'Nightlife',
        'Local Exp',
        'Shopping',
        'Museums',
      ]));
    });

    // ── 7. Multiple cities are averaged ───────────────────────────────────

    test('result is the mean of all contributing cities', () {
      // city_a: 1 nature place, target 1 → nature = 100 %
      // city_b: 0 nature visits, target 1 → nature = 0 %
      // expected mean nature = 50 %
      final cityA = _makeCity('city_a', targets: {
        'historicalPlaces': 10,
        'foodRestaurants': 10,
        'cafes': 10,
        'museumsArt': 10,
        'routes': 10,
        'nature': 1,
        'nightlife': 10,
        'localMarkets': 10,
        'hiddenGems': 10,
        'events': 10,
      });
      final cityB = _makeCity('city_b', targets: {
        'historicalPlaces': 10,
        'foodRestaurants': 10,
        'cafes': 10,
        'museumsArt': 10,
        'routes': 10,
        'nature': 1,
        'nightlife': 10,
        'localMarkets': 10,
        'hiddenGems': 10,
        'events': 10,
      });

      final places = [
        _makePlace('n1', CategoryType.nature, 'city_a'),
        _makePlace('n2', CategoryType.nature, 'city_b'),
      ];
      // Only visit city_a's nature place — city_b has no visits so it is skipped
      final visits = [_makeVerifiedVisit('n1')];

      final dna = ComputeDiscoveryDna(
        cities: [cityA, cityB],
        visits: visits,
        places: places,
      ).execute();

      // city_b has no visits → skipped in the average; only city_a contributes
      // city_a nature = 100% (1/1 target) → dna.nature = 100
      expect(dna.nature, closeTo(100.0, 0.1));
    });
  });
}

// ---------------------------------------------------------------------------
// Private assertion helper
// ---------------------------------------------------------------------------

void _expectAllZero(DiscoveryDna dna) {
  expect(dna.history, 0.0, reason: 'history should be 0');
  expect(dna.food, 0.0, reason: 'food should be 0');
  expect(dna.nature, 0.0, reason: 'nature should be 0');
  expect(dna.events, 0.0, reason: 'events should be 0');
  expect(dna.nightlife, 0.0, reason: 'nightlife should be 0');
  expect(dna.localExp, 0.0, reason: 'localExp should be 0');
  expect(dna.shopping, 0.0, reason: 'shopping should be 0');
  expect(dna.museums, 0.0, reason: 'museums should be 0');
}
