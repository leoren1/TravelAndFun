// lib/presentation/viewmodels/trip_planner_viewmodel.dart
//
// Manages the planning session state:
//   - Which city is currently selected
//   - Which places have been toggled
//   - Live "projected discovery" preview
//   - Save → TripPlan persisted in repository

import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/country.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/travel_mode.dart';
import 'package:explore_index/data/models/trip_plan.dart';
import 'package:explore_index/data/providers.dart';
import 'package:explore_index/domain/usecases/calculate_city_discovery.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class TripPlannerState {
  final List<City> cities;
  final List<Place> places;
  final List<Country> countries;
  final TravelMode mode;

  /// Currently selected city in the bottom sheet.
  final City? selectedCity;

  /// Place IDs the user has ticked for the current city.
  final Set<String> selectedPlaceIds;

  /// Current discovery % for the selected city (before plan).
  final double currentDiscovery;

  /// Projected discovery % if all selected places are visited.
  final double projectedDiscovery;

  const TripPlannerState({
    required this.cities,
    required this.places,
    required this.countries,
    required this.mode,
    this.selectedCity,
    this.selectedPlaceIds = const {},
    this.currentDiscovery = 0,
    this.projectedDiscovery = 0,
  });

  TripPlannerState copyWith({
    List<City>? cities,
    List<Place>? places,
    List<Country>? countries,
    TravelMode? mode,
    City? selectedCity,
    bool clearCity = false,
    Set<String>? selectedPlaceIds,
    double? currentDiscovery,
    double? projectedDiscovery,
  }) =>
      TripPlannerState(
        cities: cities ?? this.cities,
        places: places ?? this.places,
        countries: countries ?? this.countries,
        mode: mode ?? this.mode,
        selectedCity: clearCity ? null : (selectedCity ?? this.selectedCity),
        selectedPlaceIds: selectedPlaceIds ?? this.selectedPlaceIds,
        currentDiscovery: currentDiscovery ?? this.currentDiscovery,
        projectedDiscovery: projectedDiscovery ?? this.projectedDiscovery,
      );

  /// Mode-filtered places for [selectedCity].
  List<Place> get cityModePlaces {
    if (selectedCity == null) return [];
    return places
        .where((p) => p.cityId == selectedCity!.id && mode.includesPlace(p.tier))
        .toList();
  }

  /// Country for [selectedCity].
  Country? get selectedCountry {
    if (selectedCity == null) return null;
    try {
      return countries.firstWhere((c) => c.id == selectedCity!.countryId);
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TripPlannerNotifier extends AsyncNotifier<TripPlannerState> {
  @override
  Future<TripPlannerState> build() async {
    final mode     = ref.watch(travelModeProvider);
    final cities   = await ref.read(cityRepositoryProvider).getAllCities();
    final places   = await ref.read(placeRepositoryProvider).getAllPlaces();
    final countries = await ref.read(countryRepositoryProvider).getAllCountries();

    return TripPlannerState(
      cities: cities,
      places: places,
      countries: countries,
      mode: mode,
    );
  }

  // ── City selection ─────────────────────────────────────────────────────────

  void selectCity(City city) async {
    final s = state.value;
    if (s == null) return;

    final visits = await ref.read(visitRepositoryProvider).getAllVisits();
    final cityVisits = visits.where((v) {
      final p = s.places.firstWhere((p) => p.id == v.placeId,
          orElse: () => s.places.first);
      return p.cityId == city.id;
    }).toList();

    final current = CalculateCityDiscovery(
      city: city,
      visits: cityVisits,
      places: s.places,
      mode: s.mode,
    ).execute();

    state = AsyncData(s.copyWith(
      selectedCity: city,
      selectedPlaceIds: {},
      currentDiscovery: current,
      projectedDiscovery: current,
    ));
  }

  void clearCity() {
    state.whenData((s) => state = AsyncData(s.copyWith(clearCity: true)));
  }

  // ── Place selection ────────────────────────────────────────────────────────

  void togglePlace(String placeId) async {
    final s = state.value;
    if (s == null || s.selectedCity == null) return;

    final updated = Set<String>.from(s.selectedPlaceIds);
    if (updated.contains(placeId)) {
      updated.remove(placeId);
    } else {
      updated.add(placeId);
    }

    final projected = await _computeProjected(s, updated);
    state = AsyncData(s.copyWith(
      selectedPlaceIds: updated,
      projectedDiscovery: projected,
    ));
  }

  Future<double> _computeProjected(
      TripPlannerState s, Set<String> selectedIds) async {
    if (s.selectedCity == null) return 0;

    final visits = await ref.read(visitRepositoryProvider).getAllVisits();

    // All verified place IDs in this city.
    final verifiedIds = visits
        .where((v) => v.verified)
        .map((v) => v.placeId)
        .toSet();

    // New places = selected but not yet verified.
    final newPlaceIds = selectedIds.difference(verifiedIds);

    final modePlaces = s.places
        .where((p) =>
            p.cityId == s.selectedCity!.id && s.mode.includesPlace(p.tier))
        .toList();

    if (modePlaces.isEmpty) return 0;

    final totalTarget = modePlaces.length;
    final currentVerified = modePlaces.where((p) => verifiedIds.contains(p.id)).length;
    final afterVisit = currentVerified + newPlaceIds.length;

    return (afterVisit / totalTarget * 100).clamp(0.0, 100.0);
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> savePlan(DateTime plannedDate) async {
    final s = state.value;
    if (s == null || s.selectedCity == null || s.selectedPlaceIds.isEmpty) return;

    final plan = TripPlan(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      cityId: s.selectedCity!.id,
      cityName: s.selectedCity!.name,
      countryId: s.selectedCity!.countryId,
      plannedDate: plannedDate,
      placeIds: s.selectedPlaceIds.toList(),
      currentDiscovery: s.currentDiscovery,
      projectedDiscovery: s.projectedDiscovery,
      status: TripPlanStatus.planned,
      createdAt: DateTime.now(),
    );

    await ref.read(tripPlanRepositoryProvider).savePlan(plan);

    // Reset selection after save.
    state = AsyncData(s.copyWith(clearCity: true, selectedPlaceIds: {}));
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final tripPlannerProvider =
    AsyncNotifierProvider<TripPlannerNotifier, TripPlannerState>(
  TripPlannerNotifier.new,
);
