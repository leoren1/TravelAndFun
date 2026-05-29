// lib/presentation/viewmodels/worth_it_again_viewmodel.dart

import 'package:explore_index/data/models/category.dart';
import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/providers.dart';
import 'package:explore_index/domain/usecases/calculate_category_discovery.dart';
import 'package:explore_index/domain/usecases/compute_worth_visiting_again.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class WorthItAgainState {
  final City city;

  /// True when the city is between 10%–80% discovered.
  final bool worthIt;

  /// Overall city discovery percentage 0.0–100.0.
  final double discoveryPercent;

  /// Short human-readable reason for the recommendation.
  final String reason;

  /// Top-3 categories that are least explored.
  final List<CategoryType> missingCategories;

  /// Discovery percentage for each missing category (0.0–100.0).
  final Map<CategoryType, double> missingCategoryPcts;

  /// Long-form insight paragraph to show the user.
  final String insightParagraph;

  /// Ids of up to 5 unvisited places from the missing categories (trip plan).
  final List<String> tripPlanPlaceIds;

  /// Resolved [Place] objects for [tripPlanPlaceIds].
  final List<Place> tripPlanPlaces;

  const WorthItAgainState({
    required this.city,
    required this.worthIt,
    required this.discoveryPercent,
    required this.reason,
    required this.missingCategories,
    required this.missingCategoryPcts,
    required this.insightParagraph,
    required this.tripPlanPlaceIds,
    required this.tripPlanPlaces,
  });

  WorthItAgainState copyWith({
    City? city,
    bool? worthIt,
    double? discoveryPercent,
    String? reason,
    List<CategoryType>? missingCategories,
    Map<CategoryType, double>? missingCategoryPcts,
    String? insightParagraph,
    List<String>? tripPlanPlaceIds,
    List<Place>? tripPlanPlaces,
  }) {
    return WorthItAgainState(
      city: city ?? this.city,
      worthIt: worthIt ?? this.worthIt,
      discoveryPercent: discoveryPercent ?? this.discoveryPercent,
      reason: reason ?? this.reason,
      missingCategories: missingCategories ?? this.missingCategories,
      missingCategoryPcts: missingCategoryPcts ?? this.missingCategoryPcts,
      insightParagraph: insightParagraph ?? this.insightParagraph,
      tripPlanPlaceIds: tripPlanPlaceIds ?? this.tripPlanPlaceIds,
      tripPlanPlaces: tripPlanPlaces ?? this.tripPlanPlaces,
    );
  }
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class WorthItAgainViewModel
    extends AutoDisposeFamilyAsyncNotifier<WorthItAgainState, String> {
  @override
  Future<WorthItAgainState> build(String cityId) async {
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

    final result = ComputeWorthVisitingAgain(
      city: city,
      visits: cityVisits,
      places: places,
    ).execute();

    // Compute per-missing-category discovery percentages.
    final catCalc = CalculateCategoryDiscovery(
      city: city,
      visits: cityVisits,
      places: places,
    );
    final missingCategoryPcts = {
      for (final cat in result.missingCategories) cat: catCalc.execute(cat),
    };

    // Resolve trip plan place ids to Place objects.
    final tripPlanPlaces = result.tripPlanPlaceIds
        .map((id) {
          final idx = places.indexWhere((p) => p.id == id);
          return idx >= 0 ? places[idx] : null;
        })
        .whereType<Place>()
        .toList();

    return WorthItAgainState(
      city: city,
      worthIt: result.worthIt,
      discoveryPercent: result.discoveryPercent,
      reason: result.reason,
      missingCategories: result.missingCategories,
      missingCategoryPcts: missingCategoryPcts,
      insightParagraph: result.insightParagraph,
      tripPlanPlaceIds: result.tripPlanPlaceIds,
      tripPlanPlaces: tripPlanPlaces,
    );
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final worthItAgainViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<WorthItAgainViewModel, WorthItAgainState, String>(
  WorthItAgainViewModel.new,
);
