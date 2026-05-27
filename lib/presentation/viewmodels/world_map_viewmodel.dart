// lib/presentation/viewmodels/world_map_viewmodel.dart

import 'package:explore_index/data/models/country.dart';
import 'package:explore_index/data/providers.dart';
import 'package:explore_index/domain/usecases/calculate_country_discovery.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Supporting model
// ---------------------------------------------------------------------------

class CountryDiscoverySummary {
  final Country country;

  /// Discovery percentage 0.0–100.0.
  final double discoveryPercent;

  /// Number of cities in this country that the user has visited at least once.
  final int citiesVisited;

  const CountryDiscoverySummary({
    required this.country,
    required this.discoveryPercent,
    required this.citiesVisited,
  });

  CountryDiscoverySummary copyWith({
    Country? country,
    double? discoveryPercent,
    int? citiesVisited,
  }) {
    return CountryDiscoverySummary(
      country: country ?? this.country,
      discoveryPercent: discoveryPercent ?? this.discoveryPercent,
      citiesVisited: citiesVisited ?? this.citiesVisited,
    );
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class WorldMapState {
  final List<CountryDiscoverySummary> countries;

  /// Overall world discovery percentage (average across all countries).
  final double worldDiscovery;

  /// Total number of countries the user has visited at least one place in.
  final int totalCountriesVisited;

  const WorldMapState({
    required this.countries,
    required this.worldDiscovery,
    required this.totalCountriesVisited,
  });

  WorldMapState copyWith({
    List<CountryDiscoverySummary>? countries,
    double? worldDiscovery,
    int? totalCountriesVisited,
  }) {
    return WorldMapState(
      countries: countries ?? this.countries,
      worldDiscovery: worldDiscovery ?? this.worldDiscovery,
      totalCountriesVisited:
          totalCountriesVisited ?? this.totalCountriesVisited,
    );
  }
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class WorldMapViewModel extends AsyncNotifier<WorldMapState> {
  @override
  Future<WorldMapState> build() async {
    final countries =
        await ref.read(countryRepositoryProvider).getAllCountries();
    final cities = await ref.read(cityRepositoryProvider).getAllCities();
    final places = await ref.read(placeRepositoryProvider).getAllPlaces();
    final visits = await ref.read(visitRepositoryProvider).getAllVisits();

    // Build the set of city ids that have at least one verified visit.
    final visitedCityIds = <String>{};
    for (final v in visits) {
      final idx = places.indexWhere((p) => p.id == v.placeId);
      if (idx >= 0) visitedCityIds.add(places[idx].cityId);
    }

    final summaries = countries.map((country) {
      final disc = CalculateCountryDiscovery(
        country: country,
        cities: cities,
        visits: visits,
        places: places,
      ).execute();

      final citiesVisited = cities
          .where(
            (c) =>
                country.cityIds.contains(c.id) && visitedCityIds.contains(c.id),
          )
          .length;

      return CountryDiscoverySummary(
        country: country,
        discoveryPercent: disc,
        citiesVisited: citiesVisited,
      );
    }).toList();

    final totalVisited =
        summaries.where((s) => s.discoveryPercent > 0).length;

    final worldDiscovery = summaries.isEmpty
        ? 0.0
        : summaries.map((s) => s.discoveryPercent).reduce((a, b) => a + b) /
            summaries.length;

    return WorldMapState(
      countries: summaries,
      worldDiscovery: worldDiscovery,
      totalCountriesVisited: totalVisited,
    );
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final worldMapViewModelProvider =
    AsyncNotifierProvider<WorldMapViewModel, WorldMapState>(
  WorldMapViewModel.new,
);
