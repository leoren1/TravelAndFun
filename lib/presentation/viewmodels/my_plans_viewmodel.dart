// lib/presentation/viewmodels/my_plans_viewmodel.dart

import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/country.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/trip_plan.dart';
import 'package:explore_index/data/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Supporting model
// ---------------------------------------------------------------------------

/// A trip plan enriched with Place and City objects for the UI.
class TripPlanDetail {
  final TripPlan plan;
  final City? city;
  final Country? country;
  final List<Place> places;

  const TripPlanDetail({
    required this.plan,
    this.city,
    this.country,
    required this.places,
  });
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class MyPlansState {
  final List<TripPlanDetail> upcoming;
  final List<TripPlanDetail> past;

  const MyPlansState({
    required this.upcoming,
    required this.past,
  });

  bool get isEmpty => upcoming.isEmpty && past.isEmpty;

  MyPlansState copyWith({
    List<TripPlanDetail>? upcoming,
    List<TripPlanDetail>? past,
  }) =>
      MyPlansState(
        upcoming: upcoming ?? this.upcoming,
        past: past ?? this.past,
      );
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class MyPlansViewModel extends AsyncNotifier<MyPlansState> {
  @override
  Future<MyPlansState> build() async {
    final plans    = ref.watch(tripPlanRepositoryProvider).getAllPlans();
    final cities   = await ref.read(cityRepositoryProvider).getAllCities();
    final places   = await ref.read(placeRepositoryProvider).getAllPlaces();
    final countries = await ref.read(countryRepositoryProvider).getAllCountries();

    final cityById    = {for (final c in cities) c.id: c};
    final placeById   = {for (final p in places) p.id: p};
    final countryById = {for (final c in countries) c.id: c};

    TripPlanDetail enrich(TripPlan plan) {
      final city    = cityById[plan.cityId];
      final country = city != null ? countryById[city.countryId] : null;
      final ps      = plan.placeIds
          .map((id) => placeById[id])
          .whereType<Place>()
          .toList();
      return TripPlanDetail(plan: plan, city: city, country: country, places: ps);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcoming = plans
        .where((p) =>
            p.status == TripPlanStatus.planned &&
            !p.plannedDate.isBefore(today))
        .map(enrich)
        .toList()
      ..sort((a, b) => a.plan.plannedDate.compareTo(b.plan.plannedDate));

    final past = plans
        .where((p) =>
            p.status == TripPlanStatus.completed ||
            (p.status == TripPlanStatus.planned && p.plannedDate.isBefore(today)))
        .map(enrich)
        .toList()
      ..sort((a, b) => b.plan.plannedDate.compareTo(a.plan.plannedDate));

    return MyPlansState(upcoming: upcoming, past: past);
  }

  Future<void> deletePlan(String planId) async {
    await ref.read(tripPlanRepositoryProvider).deletePlan(planId);
    ref.invalidateSelf();
  }

  Future<void> completePlan(String planId) async {
    await ref.read(tripPlanRepositoryProvider).updateStatus(
        planId, TripPlanStatus.completed);
    ref.invalidateSelf();
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final myPlansViewModelProvider =
    AsyncNotifierProvider<MyPlansViewModel, MyPlansState>(
  MyPlansViewModel.new,
);
