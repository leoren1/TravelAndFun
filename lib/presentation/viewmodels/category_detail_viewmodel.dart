// lib/presentation/viewmodels/category_detail_viewmodel.dart

import 'package:explore_index/data/models/category.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/visit.dart';
import 'package:explore_index/data/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:explore_index/domain/usecases/calculate_category_discovery.dart';

// ---------------------------------------------------------------------------
// Parameter object (cityId + categoryName)
// ---------------------------------------------------------------------------

class CategoryDetailParams {
  final String cityId;
  final String categoryName;

  const CategoryDetailParams({
    required this.cityId,
    required this.categoryName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryDetailParams &&
          runtimeType == other.runtimeType &&
          cityId == other.cityId &&
          categoryName == other.categoryName;

  @override
  int get hashCode => Object.hash(cityId, categoryName);
}

// ---------------------------------------------------------------------------
// Supporting model
// ---------------------------------------------------------------------------

class PlaceDiscoveryEntry {
  final Place place;

  /// Whether the user has at least one verified visit for this place.
  final bool isVerified;

  /// The most recent verified visit for this place, or null if none.
  final Visit? latestVisit;

  const PlaceDiscoveryEntry({
    required this.place,
    required this.isVerified,
    this.latestVisit,
  });

  PlaceDiscoveryEntry copyWith({
    Place? place,
    bool? isVerified,
    Visit? latestVisit,
  }) {
    return PlaceDiscoveryEntry(
      place: place ?? this.place,
      isVerified: isVerified ?? this.isVerified,
      latestVisit: latestVisit ?? this.latestVisit,
    );
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class CategoryDetailState {
  final CategoryType category;
  final String cityId;

  /// All places for this city/category, each annotated with visit status.
  final List<PlaceDiscoveryEntry> entries;

  /// Number of places that have been verified.
  final int verifiedCount;

  /// Total number of places in this category for the city.
  final int totalCount;

  /// Discovery percentage 0.0–100.0.
  final double discoveryPercent;

  const CategoryDetailState({
    required this.category,
    required this.cityId,
    required this.entries,
    required this.verifiedCount,
    required this.totalCount,
    required this.discoveryPercent,
  });

  CategoryDetailState copyWith({
    CategoryType? category,
    String? cityId,
    List<PlaceDiscoveryEntry>? entries,
    int? verifiedCount,
    int? totalCount,
    double? discoveryPercent,
  }) {
    return CategoryDetailState(
      category: category ?? this.category,
      cityId: cityId ?? this.cityId,
      entries: entries ?? this.entries,
      verifiedCount: verifiedCount ?? this.verifiedCount,
      totalCount: totalCount ?? this.totalCount,
      discoveryPercent: discoveryPercent ?? this.discoveryPercent,
    );
  }
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class CategoryDetailViewModel extends AutoDisposeFamilyAsyncNotifier<
    CategoryDetailState, CategoryDetailParams> {
  @override
  Future<CategoryDetailState> build(CategoryDetailParams param) async {
    final cityId = param.cityId;
    final categoryName = param.categoryName;

    // Resolve category from name.
    final category = CategoryType.values.firstWhere(
      (c) => c.jsonKey == categoryName || c.displayName == categoryName,
      orElse: () => throw ArgumentError('Unknown category: $categoryName'),
    );

    final placeRepo = ref.read(placeRepositoryProvider);
    final visitRepo = ref.read(visitRepositoryProvider);
    final cityRepo = ref.read(cityRepositoryProvider);

    final places =
        await placeRepo.getPlacesByCityAndCategory(cityId, category.jsonKey);
    final allVisits = await visitRepo.getAllVisits();
    final city = await cityRepo.getCityById(cityId);

    // Index visits by placeId for quick lookup.
    final visitsByPlace = <String, List<Visit>>{};
    for (final v in allVisits) {
      visitsByPlace.putIfAbsent(v.placeId, () => []).add(v);
    }

    final entries = places.map((place) {
      final placeVisits = visitsByPlace[place.id] ?? [];
      final verifiedVisits = placeVisits.where((v) => v.verified).toList()
        ..sort((a, b) => b.visitedAt.compareTo(a.visitedAt));

      return PlaceDiscoveryEntry(
        place: place,
        isVerified: verifiedVisits.isNotEmpty,
        latestVisit:
            verifiedVisits.isNotEmpty ? verifiedVisits.first : null,
      );
    }).toList();

    // Sort: verified places first, then alphabetically.
    entries.sort((a, b) {
      if (a.isVerified != b.isVerified) {
        return a.isVerified ? -1 : 1;
      }
      return a.place.name.compareTo(b.place.name);
    });

    final verifiedCount = entries.where((e) => e.isVerified).length;
    final totalCount = entries.length;

    // Use categoryTarget as denominator (same as CalculateCategoryDiscovery)
    // so the % shown here is always consistent with CityDashboard progress tiles.
    final discoveryPercent = city != null
        ? CalculateCategoryDiscovery(
            city: city,
            visits: allVisits,
            places: places,
          ).execute(category)
        : (totalCount == 0
            ? 0.0
            : (verifiedCount / totalCount * 100).clamp(0.0, 100.0));

    return CategoryDetailState(
      category: category,
      cityId: cityId,
      entries: entries,
      verifiedCount: verifiedCount,
      totalCount: totalCount,
      discoveryPercent: discoveryPercent,
    );
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final categoryDetailViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<CategoryDetailViewModel, CategoryDetailState, CategoryDetailParams>(
  CategoryDetailViewModel.new,
);
