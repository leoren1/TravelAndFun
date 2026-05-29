// lib/presentation/viewmodels/dashboard_viewmodel.dart

import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/country.dart';
import 'package:explore_index/data/models/travel_mode.dart';
import 'package:explore_index/data/models/trip_plan.dart';
import 'package:explore_index/data/providers.dart';
import 'package:explore_index/domain/usecases/calculate_city_discovery.dart';
import 'package:explore_index/domain/usecases/calculate_world_discovery.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Supporting models
// ---------------------------------------------------------------------------

class RecentDiscovery {
  final String cityName;
  final double boost;

  const RecentDiscovery({required this.cityName, required this.boost});
}

/// The next upcoming scheduled trip — shown on the dashboard.
class UpcomingPlan {
  final TripPlan plan;
  final String countryName;
  final String countryCode; // 2-letter ISO, e.g. "FR"

  const UpcomingPlan({
    required this.plan,
    required this.countryName,
    required this.countryCode,
  });

  /// Days until the planned date (0 = today, negative = overdue).
  int get daysUntil {
    final today = DateTime.now();
    final d = DateTime(today.year, today.month, today.day);
    final p = DateTime(plan.plannedDate.year, plan.plannedDate.month, plan.plannedDate.day);
    return p.difference(d).inDays;
  }
}

/// One "trip" on the journey timeline — a contiguous cluster of visits in a city.
class TripSegment {
  final City city;
  final Country? country;
  final DateTime startDate;
  final DateTime endDate;
  final int visitCount;
  final double avgRating;
  final double discoveryPct;

  const TripSegment({
    required this.city,
    this.country,
    required this.startDate,
    required this.endDate,
    required this.visitCount,
    required this.avgRating,
    required this.discoveryPct,
  });

  String get dateLabel {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (startDate.year == endDate.year && startDate.month == endDate.month) {
      return '${months[startDate.month - 1]} ${startDate.year}';
    }
    if (startDate.year == endDate.year) {
      return '${months[startDate.month - 1]} – ${months[endDate.month - 1]} ${startDate.year}';
    }
    return '${months[startDate.month - 1]} ${startDate.year} – ${months[endDate.month - 1]} ${endDate.year}';
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class DashboardState {
  final double worldDiscovery;
  final int countriesVisited;
  final int citiesVisited;
  final int placesVerified;
  final UpcomingPlan? nextPlan;
  final List<RecentDiscovery> recentDiscoveries;
  final String greeting;
  final List<TripSegment> journeyTimeline;

  /// Current travel mode (shown in AppBar badge).
  final TravelMode travelMode;

  const DashboardState({
    required this.worldDiscovery,
    required this.countriesVisited,
    required this.citiesVisited,
    required this.placesVerified,
    this.nextPlan,
    required this.recentDiscoveries,
    required this.greeting,
    required this.journeyTimeline,
    required this.travelMode,
  });

  DashboardState copyWith({
    double? worldDiscovery,
    int? countriesVisited,
    int? citiesVisited,
    int? placesVerified,
    UpcomingPlan? nextPlan,
    List<RecentDiscovery>? recentDiscoveries,
    String? greeting,
    List<TripSegment>? journeyTimeline,
    TravelMode? travelMode,
  }) {
    return DashboardState(
      worldDiscovery: worldDiscovery ?? this.worldDiscovery,
      countriesVisited: countriesVisited ?? this.countriesVisited,
      citiesVisited: citiesVisited ?? this.citiesVisited,
      placesVerified: placesVerified ?? this.placesVerified,
      nextPlan: nextPlan ?? this.nextPlan,
      recentDiscoveries: recentDiscoveries ?? this.recentDiscoveries,
      greeting: greeting ?? this.greeting,
      journeyTimeline: journeyTimeline ?? this.journeyTimeline,
      travelMode: travelMode ?? this.travelMode,
    );
  }
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class DashboardViewModel extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() async {
    // Watching travelMode causes a rebuild whenever the user switches modes.
    final mode = ref.watch(travelModeProvider);

    final countries = await ref.read(countryRepositoryProvider).getAllCountries();
    final cities    = await ref.read(cityRepositoryProvider).getAllCities();
    final places    = await ref.read(placeRepositoryProvider).getAllPlaces();
    final visits    = await ref.read(visitRepositoryProvider).getAllVisits();
    final user      = await ref.read(userRepositoryProvider).getUserProfile();

    // Mode-filtered cities (journey timeline still shows all visited cities).
    final modeCities  = cities.where((c) => mode.includesCity(c.tier)).toList();
    final modePlaces  = places.where((p) => mode.includesPlace(p.tier)).toList();

    final worldDisc = CalculateWorldDiscovery(
      countries: countries,
      cities: cities,
      visits: visits,
      places: places,
      mode: mode,
    ).execute();

    // Visited city/country tracking (based on all visits regardless of mode —
    // mode changes the % but not whether you've "been" somewhere).
    final visitedCityIds = <String>{};
    final placeById = {for (final p in places) p.id: p};
    for (final v in visits) {
      final place = placeById[v.placeId];
      if (place != null) visitedCityIds.add(place.cityId);
    }

    final countryById = {for (final c in countries) c.id: c};
    final cityById    = {for (final c in cities) c.id: c};

    final visitedCountryIds = cities
        .where((c) => visitedCityIds.contains(c.id))
        .map((c) => c.countryId)
        .toSet();

    // -----------------------------------------------------------------------
    // Journey timeline
    // -----------------------------------------------------------------------
    final cityVisitMap  = <String, List<DateTime>>{};
    final cityRatingMap = <String, List<int>>{};

    for (final v in visits) {
      final place = placeById[v.placeId];
      if (place == null) continue;
      cityVisitMap.putIfAbsent(place.cityId, () => []).add(v.visitedAt);
      cityRatingMap.putIfAbsent(place.cityId, () => []).add(v.rating);
    }

    final journeyTimeline = <TripSegment>[];
    for (final entry in cityVisitMap.entries) {
      final cityId = entry.key;
      final city   = cityById[cityId];
      if (city == null) continue;
      final dates   = entry.value..sort();
      final ratings = cityRatingMap[cityId] ?? [];
      final avgRating = ratings.isEmpty
          ? 0.0
          : ratings.fold<int>(0, (s, r) => s + r) / ratings.length;

      final cityVisits = visits.where((v) {
        final p = placeById[v.placeId];
        return p != null && p.cityId == cityId;
      }).toList();

      final disc = CalculateCityDiscovery(
        city: city,
        visits: cityVisits,
        places: places,
        mode: mode,
      ).execute();

      journeyTimeline.add(TripSegment(
        city: city,
        country: countryById[city.countryId],
        startDate: dates.first,
        endDate: dates.last,
        visitCount: dates.length,
        avgRating: avgRating,
        discoveryPct: disc,
      ));
    }
    journeyTimeline.sort((a, b) => b.startDate.compareTo(a.startDate));

    // -----------------------------------------------------------------------
    // Next upcoming planned trip
    // -----------------------------------------------------------------------
    UpcomingPlan? nextPlan;
    {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final allPlans = ref.read(tripPlanRepositoryProvider).getAllPlans();
      final upcoming = allPlans
          .where((p) =>
              p.status == TripPlanStatus.planned &&
              !p.plannedDate.isBefore(todayDate))
          .toList()
        ..sort((a, b) => a.plannedDate.compareTo(b.plannedDate));
      if (upcoming.isNotEmpty) {
        final plan    = upcoming.first;
        final country = countryById[plan.countryId];
        nextPlan = UpcomingPlan(
          plan: plan,
          countryName: country?.name ?? '',
          countryCode: country?.countryCode ?? '',
        );
      }
    }

    // -----------------------------------------------------------------------
    // Recent discoveries
    // -----------------------------------------------------------------------
    final sorted = [...visits]..sort((a, b) => b.visitedAt.compareTo(a.visitedAt));
    final recent = sorted.take(5).map((v) {
      final place = placeById[v.placeId] ?? places.first;
      final city  = cityById[place.cityId] ?? cities.first;
      return RecentDiscovery(cityName: city.name, boost: place.discoveryBoost);
    }).toList();

    final hour       = DateTime.now().hour;
    final firstName  = user.name.split(' ').first;
    final greeting   = hour < 12
        ? 'Good morning, $firstName'
        : hour < 17
            ? 'Good afternoon, $firstName'
            : 'Good evening, $firstName';

    return DashboardState(
      worldDiscovery: worldDisc,
      countriesVisited: visitedCountryIds.length,
      citiesVisited: visitedCityIds.length,
      placesVerified: visits.length,
      nextPlan: nextPlan,
      recentDiscoveries: recent,
      greeting: greeting,
      journeyTimeline: journeyTimeline,
      travelMode: mode,
    );
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final dashboardViewModelProvider =
    AsyncNotifierProvider<DashboardViewModel, DashboardState>(
  DashboardViewModel.new,
);
