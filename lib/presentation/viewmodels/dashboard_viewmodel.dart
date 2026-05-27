// lib/presentation/viewmodels/dashboard_viewmodel.dart

import 'package:explore_index/data/models/category.dart';
import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/providers.dart';
import 'package:explore_index/domain/usecases/calculate_city_discovery.dart';
import 'package:explore_index/domain/usecases/calculate_world_discovery.dart';
import 'package:explore_index/domain/usecases/compute_worth_visiting_again.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Supporting model
// ---------------------------------------------------------------------------

class RecentDiscovery {
  final String cityName;
  final double boost;

  const RecentDiscovery({required this.cityName, required this.boost});
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class DashboardState {
  final double worldDiscovery;
  final int countriesVisited;
  final int citiesVisited;
  final int placesVerified;
  final City? nextCityToRevisit;
  final double nextCityDiscovery;
  final List<String> nextCityRemaining;
  final List<RecentDiscovery> recentDiscoveries;
  final String greeting;

  const DashboardState({
    required this.worldDiscovery,
    required this.countriesVisited,
    required this.citiesVisited,
    required this.placesVerified,
    this.nextCityToRevisit,
    required this.nextCityDiscovery,
    required this.nextCityRemaining,
    required this.recentDiscoveries,
    required this.greeting,
  });

  DashboardState copyWith({
    double? worldDiscovery,
    int? countriesVisited,
    int? citiesVisited,
    int? placesVerified,
    City? nextCityToRevisit,
    double? nextCityDiscovery,
    List<String>? nextCityRemaining,
    List<RecentDiscovery>? recentDiscoveries,
    String? greeting,
  }) {
    return DashboardState(
      worldDiscovery: worldDiscovery ?? this.worldDiscovery,
      countriesVisited: countriesVisited ?? this.countriesVisited,
      citiesVisited: citiesVisited ?? this.citiesVisited,
      placesVerified: placesVerified ?? this.placesVerified,
      nextCityToRevisit: nextCityToRevisit ?? this.nextCityToRevisit,
      nextCityDiscovery: nextCityDiscovery ?? this.nextCityDiscovery,
      nextCityRemaining: nextCityRemaining ?? this.nextCityRemaining,
      recentDiscoveries: recentDiscoveries ?? this.recentDiscoveries,
      greeting: greeting ?? this.greeting,
    );
  }
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class DashboardViewModel extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() async {
    final countries =
        await ref.read(countryRepositoryProvider).getAllCountries();
    final cities = await ref.read(cityRepositoryProvider).getAllCities();
    final places = await ref.read(placeRepositoryProvider).getAllPlaces();
    final visits = await ref.read(visitRepositoryProvider).getAllVisits();
    final user = await ref.read(userRepositoryProvider).getUserProfile();

    final worldDisc = CalculateWorldDiscovery(
      countries: countries,
      cities: cities,
      visits: visits,
      places: places,
    ).execute();

    // Determine visited city/country ids.
    final visitedCityIds = <String>{};
    for (final v in visits) {
      final placeIndex = places.indexWhere((p) => p.id == v.placeId);
      if (placeIndex >= 0) visitedCityIds.add(places[placeIndex].cityId);
    }

    final visitedCountryIds = cities
        .where((c) => visitedCityIds.contains(c.id))
        .map((c) => c.countryId)
        .toSet();

    // Find the best city to revisit (10% – 80% discovery).
    City? bestCity;
    double bestCityDisc = 0;
    List<String> remaining = [];

    for (final city in cities) {
      final cityVisits = visits.where((v) {
        final idx = places.indexWhere((p) => p.id == v.placeId);
        return idx >= 0 && places[idx].cityId == city.id;
      }).toList();

      final disc = CalculateCityDiscovery(
        city: city,
        visits: cityVisits,
        places: places,
      ).execute();

      if (disc >= 10 && disc <= 80) {
        if (bestCity == null || disc > bestCityDisc) {
          bestCity = city;
          bestCityDisc = disc;
          final worth = ComputeWorthVisitingAgain(
            city: city,
            visits: cityVisits,
            places: places,
          ).execute();
          remaining =
              worth.missingCategories.take(3).map((c) => c.displayName).toList();
        }
      }
    }

    // Collect the 5 most recent visit discoveries.
    final sorted = [...visits]
      ..sort((a, b) => b.visitedAt.compareTo(a.visitedAt));

    final recent = sorted.take(5).map((v) {
      final placeIdx = places.indexWhere((p) => p.id == v.placeId);
      final place = placeIdx >= 0 ? places[placeIdx] : places.first;
      final cityIdx = cities.indexWhere((c) => c.id == place.cityId);
      final city = cityIdx >= 0 ? cities[cityIdx] : cities.first;
      return RecentDiscovery(cityName: city.name, boost: place.discoveryBoost);
    }).toList();

    final hour = DateTime.now().hour;
    final firstName = user.name.split(' ').first;
    final greeting = hour < 12
        ? 'Good morning, $firstName'
        : hour < 17
            ? 'Good afternoon, $firstName'
            : 'Good evening, $firstName';

    return DashboardState(
      worldDiscovery: worldDisc,
      countriesVisited: visitedCountryIds.length,
      citiesVisited: visitedCityIds.length,
      placesVerified: visits.length,
      nextCityToRevisit: bestCity,
      nextCityDiscovery: bestCityDisc,
      nextCityRemaining: remaining,
      recentDiscoveries: recent,
      greeting: greeting,
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
