// lib/presentation/viewmodels/city_dashboard_viewmodel.dart

import 'package:explore_index/data/models/category.dart';
import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/travel_mode.dart';
import 'package:explore_index/data/providers.dart';
import 'package:explore_index/domain/usecases/calculate_category_discovery.dart';
import 'package:explore_index/domain/usecases/calculate_city_discovery.dart';
import 'package:explore_index/domain/usecases/compute_worth_visiting_again.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class CityDashboardState {
  final City city;
  final double discoveryPercent;
  final bool worthVisitingAgain;
  final String worthReason;
  final List<CategoryProgress> categoryProgress;

  const CityDashboardState({
    required this.city,
    required this.discoveryPercent,
    required this.worthVisitingAgain,
    required this.worthReason,
    required this.categoryProgress,
  });

  CityDashboardState copyWith({
    City? city,
    double? discoveryPercent,
    bool? worthVisitingAgain,
    String? worthReason,
    List<CategoryProgress>? categoryProgress,
  }) {
    return CityDashboardState(
      city: city ?? this.city,
      discoveryPercent: discoveryPercent ?? this.discoveryPercent,
      worthVisitingAgain: worthVisitingAgain ?? this.worthVisitingAgain,
      worthReason: worthReason ?? this.worthReason,
      categoryProgress: categoryProgress ?? this.categoryProgress,
    );
  }
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class CityDashboardViewModel
    extends AutoDisposeFamilyAsyncNotifier<CityDashboardState, String> {
  @override
  Future<CityDashboardState> build(String cityId) async {
    // Rebuild whenever the user switches travel mode.
    final mode = ref.watch(travelModeProvider);

    final cityRepo  = ref.read(cityRepositoryProvider);
    final placeRepo = ref.read(placeRepositoryProvider);
    final visitRepo = ref.read(visitRepositoryProvider);

    final city = await cityRepo.getCityById(cityId);
    if (city == null) throw StateError('City not found: $cityId');

    final allPlaces = await placeRepo.getAllPlaces();
    final allVisits = await visitRepo.getAllVisits();

    // Mode-filtered places for this city.
    final modePlaces = allPlaces
        .where((p) => p.cityId == cityId && mode.includesPlace(p.tier))
        .toList();

    final cityVisits = allVisits.where((v) {
      final idx = allPlaces.indexWhere((p) => p.id == v.placeId);
      return idx >= 0 && allPlaces[idx].cityId == cityId;
    }).toList();

    final disc = CalculateCityDiscovery(
      city: city,
      visits: cityVisits,
      places: allPlaces,
      mode: mode,
    ).execute();

    final worth = ComputeWorthVisitingAgain(
      city: city,
      visits: cityVisits,
      places: modePlaces,
    ).execute();

    final catCalc = CalculateCategoryDiscovery(
      city: city,
      visits: cityVisits,
      places: allPlaces,
      mode: mode,
    );

    final visitedPlaceIds = cityVisits.map((v) => v.placeId).toSet();

    // Only categories that have mode-filtered places in this city.
    final categoryProgress = CategoryType.values
        .map((cat) {
          final catPlaces = modePlaces.where((p) => p.category == cat).toList();
          if (catPlaces.isEmpty) return null;

          final completed = catPlaces
              .where((p) =>
                  visitedPlaceIds.contains(p.id) &&
                  cityVisits.any((v) => v.placeId == p.id && v.verified))
              .length;

          final pct = catCalc.execute(cat);

          return CategoryProgress(
            type: cat,
            completed: completed,
            total: catPlaces.length,
            percentage: pct,
          );
        })
        .whereType<CategoryProgress>()
        .toList();

    return CityDashboardState(
      city: city,
      discoveryPercent: disc,
      worthVisitingAgain: worth.worthIt,
      worthReason: worth.reason,
      categoryProgress: categoryProgress,
    );
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final cityDashboardViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<CityDashboardViewModel, CityDashboardState, String>(
  CityDashboardViewModel.new,
);
