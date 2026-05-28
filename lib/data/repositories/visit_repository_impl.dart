// lib/data/repositories/visit_repository_impl.dart
// Hive-backed implementation of VisitRepository.
// Visits are persisted in a Hive box named 'visits' as JSON strings,
// keyed by visit id.  The box must be opened before using this class
// (see LocalStorageService.openBoxes).

import 'dart:convert';

import 'package:explore_index/core/utils/app_logger.dart';
import 'package:explore_index/data/models/visit.dart';
import 'package:explore_index/data/repositories/visit_repository.dart';
import 'package:explore_index/data/services/local_storage_service.dart';

class VisitRepositoryImpl implements VisitRepository {
  VisitRepositoryImpl({required LocalStorageService localStorage})
      : _storage = localStorage;

  final LocalStorageService _storage;

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Decodes every non-null value in the Hive visits box into a [Visit].
  List<Visit> _decodeAll() {
    final box = _storage.visitsBox;
    final visits = <Visit>[];
    for (final key in box.keys) {
      final raw = box.get(key as String);
      if (raw != null) {
        try {
          visits.add(Visit.fromJson(json.decode(raw) as Map<String, dynamic>));
        } catch (e) {
          AppLogger.w('VisitRepository', 'Skipping corrupt visit entry for key $key', e);
        }
      }
    }
    return visits;
  }

  // ── VisitRepository implementation ────────────────────────────────────────

  @override
  Future<List<Visit>> getAllVisits() async => _decodeAll();

  @override
  Future<List<Visit>> getVisitsByUser(String userId) async =>
      _decodeAll().where((v) => v.userId == userId).toList();

  @override
  Future<List<Visit>> getVisitsByPlace(String placeId) async =>
      _decodeAll().where((v) => v.placeId == placeId).toList();

  @override
  Future<Visit?> getVisitById(String id) async {
    final raw = _storage.visitsBox.get(id);
    if (raw == null) return null;
    try {
      return Visit.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (e) {
      AppLogger.w('VisitRepository', 'Corrupt visit for id $id', e);
      return null;
    }
  }

  @override
  Future<void> saveVisit(Visit visit) async {
    await _storage.visitsBox.put(visit.id, json.encode(visit.toJson()));
  }

  @override
  Future<void> deleteVisit(String visitId) async {
    await _storage.visitsBox.delete(visitId);
  }
}
