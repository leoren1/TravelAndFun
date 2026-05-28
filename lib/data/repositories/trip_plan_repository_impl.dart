// lib/data/repositories/trip_plan_repository_impl.dart
//
// Hive-backed implementation. Plans stored as a JSON array under
// LocalStorageService.cacheBox key "trip_plans".

import 'package:explore_index/core/utils/app_logger.dart';
import 'package:explore_index/data/models/trip_plan.dart';
import 'package:explore_index/data/repositories/trip_plan_repository.dart';
import 'package:explore_index/data/services/local_storage_service.dart';

class TripPlanRepositoryImpl implements TripPlanRepository {
  final LocalStorageService _storage;
  static const _key = 'trip_plans';

  const TripPlanRepositoryImpl(this._storage);

  // ── Reads ──────────────────────────────────────────────────────────────────

  @override
  List<TripPlan> getAllPlans() {
    final raw = _storage.getCachedJson(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return decodePlans(raw);
    } catch (e) {
      AppLogger.e('TripPlanRepository', 'Failed to decode persisted plans', e);
      return [];
    }
  }

  @override
  List<TripPlan> getPlansForCity(String cityId) =>
      getAllPlans().where((p) => p.cityId == cityId).toList();

  @override
  List<TripPlan> getUpcomingPlans() {
    final now = DateTime.now();
    return getAllPlans()
        .where((p) =>
            p.status == TripPlanStatus.planned &&
            !p.plannedDate.isBefore(DateTime(now.year, now.month, now.day)))
        .toList()
      ..sort((a, b) => a.plannedDate.compareTo(b.plannedDate));
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  @override
  Future<void> savePlan(TripPlan plan) async {
    final plans = getAllPlans();
    final idx = plans.indexWhere((p) => p.id == plan.id);
    if (idx >= 0) {
      plans[idx] = plan;
    } else {
      plans.add(plan);
    }
    await _persist(plans);
  }

  @override
  Future<void> updateStatus(String planId, TripPlanStatus status) async {
    final plans = getAllPlans();
    final idx = plans.indexWhere((p) => p.id == planId);
    if (idx < 0) return;
    plans[idx] = plans[idx].copyWith(status: status);
    await _persist(plans);
  }

  @override
  Future<void> deletePlan(String planId) async {
    final plans = getAllPlans()..removeWhere((p) => p.id == planId);
    await _persist(plans);
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<void> _persist(List<TripPlan> plans) =>
      _storage.cacheJson(_key, encodePlans(plans));
}
