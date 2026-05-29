// lib/presentation/viewmodels/my_page_viewmodel.dart

import 'package:explore_index/data/models/badge.dart';
import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/country.dart';
import 'package:explore_index/data/models/discovery_dna.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/travel_mode.dart';
import 'package:explore_index/data/models/trip_plan.dart';
import 'package:explore_index/data/models/user_profile.dart';
import 'package:explore_index/data/models/visit.dart';
import 'package:explore_index/data/providers.dart';
import 'package:explore_index/domain/usecases/calculate_world_discovery.dart';
import 'package:explore_index/domain/usecases/compute_discovery_dna.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Supporting models
// ---------------------------------------------------------------------------

/// One trip in the past-journey timeline.
class JourneyEntry {
  final City city;
  final Country? country;
  final DateTime tripDate;
  final int placeCount;
  final double avgRating;
  final double discoveryPct;
  /// Verified visits for this trip (for photo display).
  final List<Visit> visits;
  final List<Place> places;

  const JourneyEntry({
    required this.city,
    required this.country,
    required this.tripDate,
    required this.placeCount,
    required this.avgRating,
    required this.discoveryPct,
    required this.visits,
    required this.places,
  });
}

/// DNA personality archetype derived from top category.
class DnaArchetype {
  final String title;
  final String tagline;
  final String emoji;
  final String topCategory;
  final double topValue;

  const DnaArchetype({
    required this.title,
    required this.tagline,
    required this.emoji,
    required this.topCategory,
    required this.topValue,
  });
}

class ModeDiscovery {
  final double bronze;
  final double silver;
  final double gold;
  const ModeDiscovery({required this.bronze, required this.silver, required this.gold});
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class MyPageState {
  final UserProfile profile;
  final List<Badge> unlockedBadges;

  final int totalCountriesVisited;
  final int totalCitiesVisited;
  final int totalPlacesVerified;
  final double averageRating;

  final ModeDiscovery modeDiscovery;
  final TravelMode currentMode;

  /// Past trips sorted newest-first.
  final List<JourneyEntry> journeyTimeline;

  /// All cities (for map layer).
  final List<City> allCities;

  /// IDs of cities with at least one verified visit.
  final Set<String> visitedCityIds;

  /// Discovery % per city.
  final Map<String, double> cityDiscoveryPcts;

  /// Upcoming plans.
  final List<TripPlan> upcomingPlans;

  final DnaArchetype archetype;

  /// Full computed DNA scores for all 8 dimensions, used by _DnaSection bars.
  final Map<String, double> dnaScores;

  const MyPageState({
    required this.profile,
    required this.unlockedBadges,
    required this.totalCountriesVisited,
    required this.totalCitiesVisited,
    required this.totalPlacesVerified,
    required this.averageRating,
    required this.modeDiscovery,
    required this.currentMode,
    required this.journeyTimeline,
    required this.allCities,
    required this.visitedCityIds,
    required this.cityDiscoveryPcts,
    required this.upcomingPlans,
    required this.archetype,
    required this.dnaScores,
  });
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class MyPageViewModel extends AsyncNotifier<MyPageState> {
  @override
  Future<MyPageState> build() async {
    final mode = ref.watch(travelModeProvider);

    final userRepo    = ref.read(userRepositoryProvider);
    final cityRepo    = ref.read(cityRepositoryProvider);
    final placeRepo   = ref.read(placeRepositoryProvider);
    final visitRepo   = ref.read(visitRepositoryProvider);
    final countryRepo = ref.read(countryRepositoryProvider);
    final planRepo    = ref.read(tripPlanRepositoryProvider);

    final profile    = await userRepo.getUserProfile();
    final allBadges  = await userRepo.getAllBadges();
    final cities     = await cityRepo.getAllCities();
    final places     = await placeRepo.getAllPlaces();
    final visits     = await visitRepo.getAllVisits();
    final countries  = await countryRepo.getAllCountries();
    // Compute DNA from actual visit data — same logic as DiscoveryDnaViewModel.
    final dna = ComputeDiscoveryDna(
      cities: cities,
      visits: visits,
      places: places,
    ).execute();

    final cityById    = {for (final c in cities) c.id: c};
    final placeById   = {for (final p in places) p.id: p};
    final countryById = {for (final c in countries) c.id: c};

    // ── Visited sets ────────────────────────────────────────────────────────
    final visitedCityIds = <String>{};
    for (final v in visits) {
      final p = placeById[v.placeId];
      if (p != null) visitedCityIds.add(p.cityId);
    }

    final visitedCountryIds = cities
        .where((c) => visitedCityIds.contains(c.id))
        .map((c) => c.countryId)
        .toSet();

    // ── Stats ────────────────────────────────────────────────────────────────
    final uniquePlaceIds = visits.map((v) => v.placeId).toSet();
    final ratingSum = visits.fold<double>(0, (s, v) => s + v.rating);
    final avgRating = visits.isEmpty ? 0.0 : ratingSum / visits.length;

    // ── Discovery ────────────────────────────────────────────────────────────
    double _disc(TravelMode m) => CalculateWorldDiscovery(
      countries: countries, cities: cities, visits: visits, places: places, mode: m,
    ).execute();

    final modeDiscovery = ModeDiscovery(
      bronze: _disc(TravelMode.bronze),
      silver: _disc(TravelMode.silver),
      gold:   _disc(TravelMode.gold),
    );

    // ── City discovery pcts ──────────────────────────────────────────────────
    final cityDiscoveryPcts = <String, double>{};
    for (final city in cities) {
      final cv = visits.where((v) => placeById[v.placeId]?.cityId == city.id).toList();
      final target = places
          .where((p) => p.cityId == city.id && mode.includesPlace(p.tier))
          .length;
      if (target == 0) { cityDiscoveryPcts[city.id] = 0; continue; }
      final verified = cv.where((v) => v.verified).map((v) => v.placeId).toSet().length;
      cityDiscoveryPcts[city.id] = (verified / target * 100).clamp(0.0, 100.0);
    }

    // ── Journey timeline ─────────────────────────────────────────────────────
    final cityVisitMap  = <String, List<Visit>>{};
    for (final v in visits) {
      final p = placeById[v.placeId];
      if (p != null) cityVisitMap.putIfAbsent(p.cityId, () => []).add(v);
    }

    final timeline = <JourneyEntry>[];
    for (final entry in cityVisitMap.entries) {
      final city = cityById[entry.key];
      if (city == null) continue;
      final cv = entry.value;
      final dates = cv.map((v) => v.visitedAt).toList()..sort();
      final ratings = cv.map((v) => v.rating).toList();
      final avg = ratings.isEmpty ? 0.0 : ratings.fold<int>(0, (s, r) => s + r) / ratings.length;
      final cityPlaces = cv.map((v) => placeById[v.placeId]).whereType<Place>().toList();

      timeline.add(JourneyEntry(
        city: city,
        country: countryById[city.countryId],
        tripDate: dates.last,
        placeCount: cv.length,
        avgRating: avg,
        discoveryPct: cityDiscoveryPcts[city.id] ?? 0,
        visits: cv,
        places: cityPlaces,
      ));
    }
    timeline.sort((a, b) => b.tripDate.compareTo(a.tripDate));

    // ── DNA archetype ────────────────────────────────────────────────────────
    final dnaValues = dna.dimensions;
    final topEntry = dnaValues.entries
        .reduce((a, b) => a.value >= b.value ? a : b);

    final archetype = DnaArchetype(
      title: _archetypeTitle(topEntry.key, topEntry.value),
      tagline: _archetypeTagline(topEntry.key),
      emoji: _archetypeEmoji(topEntry.key),
      topCategory: topEntry.key,
      topValue: topEntry.value,
    );

    // ── Upcoming plans ───────────────────────────────────────────────────────
    final upcomingPlans = planRepo.getUpcomingPlans().take(5).toList();

    return MyPageState(
      profile: profile,
      unlockedBadges: allBadges
          .where((b) => profile.badgeIds.contains(b.id))
          .toList(),
      totalCountriesVisited: visitedCountryIds.length,
      totalCitiesVisited: visitedCityIds.length,
      totalPlacesVerified: uniquePlaceIds.length,
      averageRating: avgRating,
      modeDiscovery: modeDiscovery,
      currentMode: mode,
      journeyTimeline: timeline,
      allCities: cities,
      visitedCityIds: visitedCityIds,
      cityDiscoveryPcts: cityDiscoveryPcts,
      upcomingPlans: upcomingPlans,
      archetype: archetype,
      dnaScores: dna.dimensions,
    );
  }

  Future<void> refresh() async => ref.invalidateSelf();

  // ── DNA archetype helpers ────────────────────────────────────────────────
  static const _defaultDna = DiscoveryDna(
    history: 0, food: 0, nature: 0, events: 0,
    nightlife: 0, localExp: 0, shopping: 0, museums: 0,
    summary: 'Start exploring to discover your travel DNA.',
  );

  static String _archetypeTitle(String top, double val) {
    if (val < 5) return 'The Explorer';
    return switch (top) {
      'History'   => 'The Historian',
      'Food'      => 'The Gastronaut',
      'Nature'    => 'The Earth Walker',
      'Events'    => 'The Pulse Chaser',
      'Nightlife' => 'The Night Wanderer',
      'Local Exp' => 'The Urban Scout',
      'Shopping'  => 'The Market Diver',
      'Museums'   => 'The Curator Soul',
      _           => 'The Free Spirit',
    };
  }

  static String _archetypeTagline(String top) => switch (top) {
    'History'   => 'Ancient walls speak to you first.',
    'Food'      => 'Every meal is a new destination.',
    'Nature'    => 'You prefer horizons over hotel lobbies.',
    'Events'    => 'You\'re always where the energy is.',
    'Nightlife' => 'The city reveals itself after midnight.',
    'Local Exp' => 'You live where tourists only look.',
    'Shopping'  => 'Markets are your museums.',
    'Museums'   => 'Art is your compass.',
    _           => 'Every path is a story.',
  };

  static String _archetypeEmoji(String top) => switch (top) {
    'History'   => '🏛️',
    'Food'      => '🍽️',
    'Nature'    => '🌿',
    'Events'    => '🎭',
    'Nightlife' => '🌙',
    'Local Exp' => '🧭',
    'Shopping'  => '🛍️',
    'Museums'   => '🎨',
    _           => '✈️',
  };
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final myPageViewModelProvider =
    AsyncNotifierProvider<MyPageViewModel, MyPageState>(
  MyPageViewModel.new,
);
