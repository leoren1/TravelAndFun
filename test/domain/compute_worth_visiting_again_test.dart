// test/domain/compute_worth_visiting_again_test.dart
//
// Tests for ComputeWorthVisitingAgain and WorthVisitingResult.
// Run with: flutter test test/domain/compute_worth_visiting_again_test.dart

import 'package:explore_index/data/models/category.dart';
import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/visit.dart';
import 'package:explore_index/domain/usecases/compute_worth_visiting_again.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a City whose categoryTargets can produce a known city-discovery %.
///
/// When [targetPerCategory] = 10 and you provide N verified places spread
/// evenly across all categories, city discovery ≈ N/10 * 100 / 10.
/// (Each category contributes verified/target * 100, then averaged over 10.)
City _makeCity({Map<String, int>? targets}) => City(
      id: 'test_city',
      name: 'Test City',
      countryId: 'tc',
      heroImage: '',
      latitude: 0,
      longitude: 0,
      categoryTargets: targets ??
          {
            'historicalPlaces': 10,
            'foodRestaurants': 10,
            'cafes': 10,
            'museumsArt': 10,
            'routes': 10,
            'nature': 10,
            'nightlife': 10,
            'localMarkets': 10,
            'hiddenGems': 10,
            'events': 10,
          },
    );

Place _makePlace(String id, CategoryType cat) => Place(
      id: id,
      name: id,
      description: '',
      image: '',
      cityId: 'test_city',
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

/// Creates N verified places and visits for the given category.
/// All targets are set to [targetPerCategory] for all categories.
({List<Place> places, List<Visit> visits}) _makeFullCategory(
  CategoryType cat, {
  int count = 10,
  int targetPerCategory = 10,
}) {
  final places =
      List.generate(count, (i) => _makePlace('${cat.jsonKey}_$i', cat));
  final visits = places.map((p) => _makeVerifiedVisit(p.id)).toList();
  return (places: places, visits: visits);
}

// ---------------------------------------------------------------------------
// Discovery % → worthIt boundary
// worthIt = cityDiscovery >= 10 && cityDiscovery <= 80
// ---------------------------------------------------------------------------

void main() {
  group('ComputeWorthVisitingAgain — worthIt flag', () {
    // ── 1. 0 % discovery → worthIt = false ───────────────────────────────

    test('worthIt is false when city discovery is 0 % (no visits)', () {
      final city = _makeCity();
      final places = [_makePlace('p1', CategoryType.historicalPlaces)];

      final result = ComputeWorthVisitingAgain(
        city: city,
        visits: [],
        places: places,
      ).execute();

      expect(result.worthIt, isFalse);
      expect(result.discoveryPercent, 0.0);
    });

    // ── 2. 50 % discovery → worthIt = true ───────────────────────────────
    //
    // Each target = 10, 10 categories.
    // Fill 5 categories completely (50 places, each target = 10).
    // Each full category contributes 100 %, the other 5 contribute 0 %.
    // City discovery = (5 * 100 + 5 * 0) / 10 = 50 %.

    test('worthIt is true when city discovery is ~50 %', () {
      final city = _makeCity();

      final filledCategories = [
        CategoryType.historicalPlaces,
        CategoryType.foodRestaurants,
        CategoryType.cafes,
        CategoryType.museumsArt,
        CategoryType.routes,
      ];

      final allPlaces = <Place>[];
      final allVisits = <Visit>[];

      for (final cat in filledCategories) {
        final data = _makeFullCategory(cat);
        allPlaces.addAll(data.places);
        allVisits.addAll(data.visits);
      }

      final result = ComputeWorthVisitingAgain(
        city: city,
        visits: allVisits,
        places: allPlaces,
      ).execute();

      expect(result.discoveryPercent, closeTo(50.0, 0.01));
      expect(result.worthIt, isTrue);
    });

    // ── 3. 85 % discovery → worthIt = false (already thoroughly explored) ─
    //
    // Fill 9 out of 10 categories completely (the 10th remains 0 %).
    // City discovery = (9 * 100 + 0) / 10 = 90 % > 80 % → worthIt = false.

    test('worthIt is false when city discovery exceeds 80 % (~90 %)', () {
      final city = _makeCity();

      final filledCategories = [
        CategoryType.historicalPlaces,
        CategoryType.foodRestaurants,
        CategoryType.cafes,
        CategoryType.museumsArt,
        CategoryType.routes,
        CategoryType.nature,
        CategoryType.nightlife,
        CategoryType.localMarkets,
        CategoryType.hiddenGems,
        // events intentionally left empty
      ];

      final allPlaces = <Place>[];
      final allVisits = <Visit>[];

      for (final cat in filledCategories) {
        final data = _makeFullCategory(cat);
        allPlaces.addAll(data.places);
        allVisits.addAll(data.visits);
      }

      final result = ComputeWorthVisitingAgain(
        city: city,
        visits: allVisits,
        places: allPlaces,
      ).execute();

      expect(result.discoveryPercent, closeTo(90.0, 0.01));
      expect(result.worthIt, isFalse);
    });

    // ── 4. Exactly at the lower boundary (10 %) → worthIt = true ─────────
    //
    // 1 verified place in historicalPlaces (target = 10) → 10 % for that
    // category, 0 % for all others → city = 10 / 10 = 1 %... Wait — that
    // would be 1 %, which is < 10.  We need city ≥ 10 %.
    //
    // To get exactly 10 % city discovery, fill 1 full category out of 10:
    // category 1 = 100 %, others = 0 → mean = 10 %.

    test('worthIt is true when city discovery is exactly 10 %', () {
      final city = _makeCity();
      final data = _makeFullCategory(CategoryType.historicalPlaces);

      final result = ComputeWorthVisitingAgain(
        city: city,
        visits: data.visits,
        places: data.places,
      ).execute();

      expect(result.discoveryPercent, closeTo(10.0, 0.01));
      expect(result.worthIt, isTrue);
    });

    // ── 5. Exactly at the upper boundary (80 %) → worthIt = true ─────────
    //
    // Fill exactly 8 categories out of 10 → city = 80 %.

    test('worthIt is true when city discovery is exactly 80 %', () {
      final city = _makeCity();

      final filledCategories = [
        CategoryType.historicalPlaces,
        CategoryType.foodRestaurants,
        CategoryType.cafes,
        CategoryType.museumsArt,
        CategoryType.routes,
        CategoryType.nature,
        CategoryType.nightlife,
        CategoryType.localMarkets,
        // hiddenGems and events left empty
      ];

      final allPlaces = <Place>[];
      final allVisits = <Visit>[];

      for (final cat in filledCategories) {
        final data = _makeFullCategory(cat);
        allPlaces.addAll(data.places);
        allVisits.addAll(data.visits);
      }

      final result = ComputeWorthVisitingAgain(
        city: city,
        visits: allVisits,
        places: allPlaces,
      ).execute();

      expect(result.discoveryPercent, closeTo(80.0, 0.01));
      expect(result.worthIt, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // missingCategories — lowest 3 by discovery %
  // -------------------------------------------------------------------------

  group('ComputeWorthVisitingAgain — missingCategories', () {
    // ── 6. Returns exactly 3 missing categories ───────────────────────────

    test('missingCategories always contains exactly 3 entries', () {
      final city = _makeCity();
      final result = ComputeWorthVisitingAgain(
        city: city,
        visits: [],
        places: [],
      ).execute();

      expect(result.missingCategories, hasLength(3));
    });

    // ── 7. missingCategories are the lowest-discovery categories ─────────
    //
    // Fill historicalPlaces (100 %), foodRestaurants (100 %), cafes (100 %),
    // museumsArt (100 %), routes (100 %), nature (100 %), nightlife (100 %),
    // localMarkets (0 %), hiddenGems (0 %), events (0 %).
    // The 3 lowest are localMarkets, hiddenGems, events (all 0 %).

    test('missingCategories are the three lowest-discovery categories', () {
      final city = _makeCity();

      final filledCategories = [
        CategoryType.historicalPlaces,
        CategoryType.foodRestaurants,
        CategoryType.cafes,
        CategoryType.museumsArt,
        CategoryType.routes,
        CategoryType.nature,
        CategoryType.nightlife,
      ];

      final allPlaces = <Place>[];
      final allVisits = <Visit>[];

      for (final cat in filledCategories) {
        final data = _makeFullCategory(cat);
        allPlaces.addAll(data.places);
        allVisits.addAll(data.visits);
      }

      final result = ComputeWorthVisitingAgain(
        city: city,
        visits: allVisits,
        places: allPlaces,
      ).execute();

      // The three un-visited categories must be in missingCategories.
      expect(
        result.missingCategories,
        containsAll([
          CategoryType.localMarkets,
          CategoryType.hiddenGems,
          CategoryType.events,
        ]),
      );
    });

    // ── 8. missingCategories when all categories are empty ────────────────

    test(
        'missingCategories returns 3 entries even when all categories are 0 %',
        () {
      final city = _makeCity();
      final result = ComputeWorthVisitingAgain(
        city: city,
        visits: [],
        places: [],
      ).execute();

      expect(result.missingCategories, hasLength(3));
      // All are valid CategoryType values
      for (final cat in result.missingCategories) {
        expect(CategoryType.values, contains(cat));
      }
    });

    // ── 9. missingCategories does not include fully-discovered categories ──

    test('a fully discovered category does not appear in missingCategories when'
        ' other categories are empty', () {
      // Only historicalPlaces is fully discovered; all others are 0 %.
      // missingCategories should NOT include historicalPlaces.
      final city = _makeCity();
      final data = _makeFullCategory(CategoryType.historicalPlaces);

      final result = ComputeWorthVisitingAgain(
        city: city,
        visits: data.visits,
        places: data.places,
      ).execute();

      expect(
        result.missingCategories,
        isNot(contains(CategoryType.historicalPlaces)),
      );
    });
  });

  // -------------------------------------------------------------------------
  // tripPlanPlaceIds
  // -------------------------------------------------------------------------

  group('ComputeWorthVisitingAgain — tripPlanPlaceIds', () {
    // ── 10. Contains only unvisited places from missing categories ─────────

    test('tripPlanPlaceIds contains unvisited places from missing categories',
        () {
      final city = _makeCity();

      // Fully visit historicalPlaces so it is NOT in missingCategories.
      final histData = _makeFullCategory(CategoryType.historicalPlaces);

      // Add some unvisited cafes places (cafes will be in missingCategories
      // because they are 0 %).
      final cafePlaces = List.generate(
        3,
        (i) => _makePlace('cafe_$i', CategoryType.cafes),
      );

      final allPlaces = [...histData.places, ...cafePlaces];
      final allVisits = histData.visits; // cafes not visited

      final result = ComputeWorthVisitingAgain(
        city: city,
        visits: allVisits,
        places: allPlaces,
      ).execute();

      // tripPlanPlaceIds should not include already-visited place IDs
      final visitedIds =
          allVisits.map((v) => v.placeId).toSet();
      for (final id in result.tripPlanPlaceIds) {
        expect(visitedIds, isNot(contains(id)));
      }
    });

    // ── 11. At most 5 place IDs are returned ──────────────────────────────

    test('tripPlanPlaceIds contains at most 5 entries', () {
      final city = _makeCity();

      // Create 10 unvisited places in localMarkets (will be in missing).
      final places = List.generate(
        10,
        (i) => _makePlace('lm_$i', CategoryType.localMarkets),
      );

      final result = ComputeWorthVisitingAgain(
        city: city,
        visits: [],
        places: places,
      ).execute();

      expect(result.tripPlanPlaceIds.length, lessThanOrEqualTo(5));
    });

    // ── 12. Empty when all places are already visited ─────────────────────

    test('tripPlanPlaceIds is empty when all city places have been visited', () {
      final city = _makeCity();
      final data = _makeFullCategory(CategoryType.events);

      final result = ComputeWorthVisitingAgain(
        city: city,
        visits: data.visits,
        places: data.places,
      ).execute();

      // Only events places exist; events target = 10, all 10 visited.
      // missingCategories will contain other categories, but there are no
      // places registered for those categories → tripPlanPlaceIds empty.
      expect(result.tripPlanPlaceIds, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // reason and insightParagraph
  // -------------------------------------------------------------------------

  group('ComputeWorthVisitingAgain — reason and insightParagraph', () {
    test('reason is non-empty for any input', () {
      final city = _makeCity();
      final result = ComputeWorthVisitingAgain(
        city: city,
        visits: [],
        places: [],
      ).execute();
      expect(result.reason, isNotEmpty);
    });

    test('insightParagraph is non-empty for any input', () {
      final city = _makeCity();
      final result = ComputeWorthVisitingAgain(
        city: city,
        visits: [],
        places: [],
      ).execute();
      expect(result.insightParagraph, isNotEmpty);
    });

    test('reason for 0 % discovery encourages first visit', () {
      final city = _makeCity();
      final result = ComputeWorthVisitingAgain(
        city: city,
        visits: [],
        places: [],
      ).execute();
      expect(result.reason.toLowerCase(), contains('first'));
    });

    test('reason for >80 % discovery acknowledges thorough exploration', () {
      final city = _makeCity();

      // Fill 9 categories → 90 % city discovery → worthIt = false (>80)
      final filledCats = [
        CategoryType.historicalPlaces,
        CategoryType.foodRestaurants,
        CategoryType.cafes,
        CategoryType.museumsArt,
        CategoryType.routes,
        CategoryType.nature,
        CategoryType.nightlife,
        CategoryType.localMarkets,
        CategoryType.hiddenGems,
      ];

      final allPlaces = <Place>[];
      final allVisits = <Visit>[];
      for (final cat in filledCats) {
        final data = _makeFullCategory(cat);
        allPlaces.addAll(data.places);
        allVisits.addAll(data.visits);
      }

      final result = ComputeWorthVisitingAgain(
        city: city,
        visits: allVisits,
        places: allPlaces,
      ).execute();

      expect(result.worthIt, isFalse);
      expect(result.discoveryPercent, greaterThan(80.0));
      // Reason should convey "done / thorough" message
      expect(result.reason.toLowerCase(), contains('explored'));
    });
  });

  // -------------------------------------------------------------------------
  // discoveryPercent consistency
  // -------------------------------------------------------------------------

  group('ComputeWorthVisitingAgain — discoveryPercent', () {
    test('discoveryPercent equals the city discovery calculated independently',
        () {
      final city = _makeCity();
      final data = _makeFullCategory(CategoryType.nature);

      // 1 full category out of 10 → 10 %
      final result = ComputeWorthVisitingAgain(
        city: city,
        visits: data.visits,
        places: data.places,
      ).execute();

      expect(result.discoveryPercent, closeTo(10.0, 0.01));
    });

    test('discoveryPercent is between 0 and 100', () {
      final city = _makeCity();
      final data = _makeFullCategory(CategoryType.events);

      final result = ComputeWorthVisitingAgain(
        city: city,
        visits: data.visits,
        places: data.places,
      ).execute();

      expect(result.discoveryPercent, inInclusiveRange(0.0, 100.0));
    });
  });
}
