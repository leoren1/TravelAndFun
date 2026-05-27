// lib/data/repositories/visit_repository.dart
// Abstract contract for visit data access.

import 'package:explore_index/data/models/visit.dart';

abstract class VisitRepository {
  /// Returns all persisted visits.
  Future<List<Visit>> getAllVisits();

  /// Returns all visits recorded for [userId].
  Future<List<Visit>> getVisitsByUser(String userId);

  /// Returns all visits logged at [placeId].
  Future<List<Visit>> getVisitsByPlace(String placeId);

  /// Returns the visit identified by [id], or null if not found.
  Future<Visit?> getVisitById(String id);

  /// Persists [visit], inserting it if new or updating if it already exists.
  Future<void> saveVisit(Visit visit);

  /// Removes the visit identified by [visitId].
  Future<void> deleteVisit(String visitId);
}
