// lib/data/repositories/trip_plan_repository.dart

import 'package:explore_index/data/models/trip_plan.dart';

abstract interface class TripPlanRepository {
  List<TripPlan> getAllPlans();
  List<TripPlan> getPlansForCity(String cityId);
  List<TripPlan> getUpcomingPlans();
  Future<void> savePlan(TripPlan plan);
  Future<void> updateStatus(String planId, TripPlanStatus status);
  Future<void> deletePlan(String planId);
}
