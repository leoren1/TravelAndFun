// lib/presentation/viewmodels/city_dashboard_viewmodel.dart

import 'package:explore_index/data/models/category.dart';
import 'package:explore_index/data/models/city.dart';
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

  /// Overall city discovery percentage 0.0–100.0.
  final double discoveryPercent;

  /// Whether the city is worth revisiting (10%–80% discovery).
  final bool worthVisitingAgain;

  /// Human-readable reason for the worth-revisiting recommendation.
  final String worthReason;

  /// Per-category discovery progress for all 10 categories.
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
    final cityRepo = ref.read(cityRepositoryProvider);
    final placeRepo = ref.read(placeRepositoryProvider);
    final visitRepo = ref.read(visitRepositoryProvider);

    final city = await cityRepo.getCityById(cityId);
    if (city == null) throw StateError('City not found: $cityId');

    final places = await placeRepo.getAllPlaces();
    final allVisits = await visitRepo.getAllVisits();

    final cityVisits = allVisits.where((v) {
      final idx = places.indexWhere((p) => p.id == v.placeId);
      return idx >= 0 && places[idx].cityId == cityId;
    }).toList();

    final disc = CalculateCityDiscovery(
      city: city,
      visits: cityVisits,
      places: places,
    ).execute();

    final worth = ComputeWorthVisitingAgain(
      city: city,
      visits: cityVisits,
      places: places,
    ).execute();

    final catCalc = CalculateCategoryDiscovery(
      city: city,
      visits: cityVisits,
      places: places,
    );

    final visitedPlaceIds = cityVisits.map((v) => v.placeId).toSet();

    final categoryProgress = CategoryType.values.map((cat) {
      final target = city.categoryTargets[cat.jsonKey] ?? 10;
      final catPlaces = places
          .where((p) => p.cityId == cityId && p.category == cat)
          .toList();
      final completed = catPlaces
          .where(
            (p) => visitedPlaceIds.contains(p.id) &&
                cityVisits.any((v) => v.placeId == p.id && v.verified),
          )
          .length;
      final pct = catCalc.execute(cat);

      return CategoryProgress(
        type: cat,
        completed: completed,
        total: target,
        percentage: pct,
      );
    }).toList();

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
