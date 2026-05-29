// lib/presentation/viewmodels/world_map_viewmodel.dart

import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/country.dart';
import 'package:explore_index/data/models/travel_mode.dart';
import 'package:explore_index/data/providers.dart';
import 'package:explore_index/domain/usecases/calculate_city_discovery.dart';
import 'package:explore_index/domain/usecases/calculate_country_discovery.dart';
import 'package:explore_index/domain/usecases/calculate_world_discovery.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Supporting model
// ---------------------------------------------------------------------------

class CountryDiscoverySummary {
  final Country country;
  final double discoveryPercent;
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
  final double worldDiscovery;
  final int totalCountriesVisited;
  final Set<String> visitedCityIds;
  final List<City> cities;
  final Map<String, List<String>> cityVisitedPlaces;
  final Map<String, double> cityDiscoveryPcts;

  const WorldMapState({
    required this.countries,
    required this.worldDiscovery,
    required this.totalCountriesVisited,
    required this.visitedCityIds,
    required this.cities,
    required this.cityVisitedPlaces,
    required this.cityDiscoveryPcts,
  });

  WorldMapState copyWith({
    List<CountryDiscoverySummary>? countries,
    double? worldDiscovery,
    int? totalCountriesVisited,
    Set<String>? visitedCityIds,
    List<City>? cities,
    Map<String, List<String>>? cityVisitedPlaces,
    Map<String, double>? cityDiscoveryPcts,
  }) {
    return WorldMapState(
      countries: countries ?? this.countries,
      worldDiscovery: worldDiscovery ?? this.worldDiscovery,
      totalCountriesVisited:
          totalCountriesVisited ?? this.totalCountriesVisited,
      visitedCityIds: visitedCityIds ?? this.visitedCityIds,
      cities: cities ?? this.cities,
      cityVisitedPlaces: cityVisitedPlaces ?? this.cityVisitedPlaces,
      cityDiscoveryPcts: cityDiscoveryPcts ?? this.cityDiscoveryPcts,
    );
  }
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class WorldMapViewModel extends AsyncNotifier<WorldMapState> {
  @override
  Future<WorldMapState> build() async {
    // Rebuild whenever the user switches travel mode.
    final mode = ref.watch(travelModeProvider);

    final countries = await ref.read(countryRepositoryProvider).getAllCountries();
    final cities    = await ref.read(cityRepositoryProvider).getAllCities();
    final places    = await ref.read(placeRepositoryProvider).getAllPlaces();
    final visits    = await ref.read(visitRepositoryProvider).getAllVisits();

    // Map layer shows mode-filtered cities only.
    final modeCities = cities.where((c) => mode.includesCity(c.tier)).toList();

    final visitedCityIds    = <String>{};
    final cityVisitedPlaces = <String, List<String>>{};
    final placeById         = {for (final p in places) p.id: p};

    for (final v in visits) {
      final place = placeById[v.placeId];
      if (place == null) continue;
      visitedCityIds.add(place.cityId);
      final bucket = cityVisitedPlaces.putIfAbsent(place.cityId, () => []);
      if (!bucket.contains(place.name)) bucket.add(place.name);
    }

    // Per-city discovery (mode-filtered).
    final cityDiscoveryPcts = <String, double>{};
    for (final city in modeCities) {
      final cityVisits = visits.where((v) {
        final p = placeById[v.placeId];
        return p != null && p.cityId == city.id;
      }).toList();
      cityDiscoveryPcts[city.id] = CalculateCityDiscovery(
        city: city,
        visits: cityVisits,
        places: places,
        mode: mode,
      ).execute();
    }

    // Per-country summaries (mode-filtered).
    final summaries = countries.map((country) {
      final disc = CalculateCountryDiscovery(
        country: country,
        cities: cities,
        visits: visits,
        places: places,
        mode: mode,
      ).execute();

      final citiesVisited = modeCities
          .where((c) =>
              country.cityIds.contains(c.id) && visitedCityIds.contains(c.id))
          .length;

      return CountryDiscoverySummary(
        country: country,
        discoveryPercent: disc,
        citiesVisited: citiesVisited,
      );
    }).toList();

    final totalVisited = summaries.where((s) => s.discoveryPercent > 0).length;

    final worldDiscovery = CalculateWorldDiscovery(
      countries: countries,
      cities: cities,
      visits: visits,
      places: places,
      mode: mode,
    ).execute();

    return WorldMapState(
      countries: summaries,
      worldDiscovery: worldDiscovery,
      totalCountriesVisited: totalVisited,
      visitedCityIds: visitedCityIds,
      cities: modeCities,
      cityVisitedPlaces: cityVisitedPlaces,
      cityDiscoveryPcts: cityDiscoveryPcts,
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
