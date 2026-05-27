// lib/domain/usecases/seed_demo_data.dart
// Seeds demo visit data into Hive on first app launch.

import 'dart:convert';
import 'package:explore_index/data/models/visit.dart';
import 'package:explore_index/data/repositories/visit_repository.dart';
import 'package:explore_index/data/services/local_storage_service.dart';
import 'package:flutter/services.dart';

class SeedDemoData {
  final VisitRepository visitRepo;
  final LocalStorageService storage;

  const SeedDemoData({required this.visitRepo, required this.storage});

  /// Seeds demo visits only once (when the visits box is empty).
  Future<void> execute() async {
    if (storage.visitsBox.isNotEmpty) return;

    try {
      final jsonString = await rootBundle
          .loadString('lib/static_data/demo_visits.json');
      final list = jsonDecode(jsonString) as List<dynamic>;
      for (final item in list) {
        final visit = Visit.fromJson(item as Map<String, dynamic>);
        await visitRepo.saveVisit(visit);
      }
    } catch (_) {
      // Silently skip if demo data fails to load — app still works without it.
    }
  }
}
