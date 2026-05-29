// lib/presentation/viewmodels/photo_journal_viewmodel.dart

import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/country.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/visit.dart';
import 'package:explore_index/data/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Iterable extension
// ---------------------------------------------------------------------------

extension _IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// JournalEntry
// ---------------------------------------------------------------------------

class JournalEntry {
  final Visit visit;
  final Place place;
  final City? city;
  final Country? country;

  const JournalEntry({
    required this.visit,
    required this.place,
    this.city,
    this.country,
  });

  /// True if photoPath is a real device file (not a demo path).
  bool get hasUserPhoto =>
      visit.photoPath.isNotEmpty && !visit.photoPath.startsWith('/demo/');

  /// The display image: place stock image URL (fallback for network image).
  String get displayImageUrl => place.image;

  /// The user's actual photo path if real, else null.
  String? get userPhotoPath => hasUserPhoto ? visit.photoPath : null;

  /// Month-year string for section grouping, e.g. "May 2026".
  String get monthYear {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final d = visit.visitedAt;
    return '${months[d.month - 1]} ${d.year}';
  }
}

// ---------------------------------------------------------------------------
// PhotoJournalState
// ---------------------------------------------------------------------------

class PhotoJournalState {
  final List<JournalEntry> entries;

  /// Month-year key → entries (insertion order = newest month first).
  final Map<String, List<JournalEntry>> byMonth;

  const PhotoJournalState({
    required this.entries,
    required this.byMonth,
  });

  bool get isEmpty => entries.isEmpty;
}

// ---------------------------------------------------------------------------
// PhotoJournalViewModel
// ---------------------------------------------------------------------------

class PhotoJournalViewModel extends AsyncNotifier<PhotoJournalState> {
  @override
  Future<PhotoJournalState> build() async {
    final visitRepo = ref.read(visitRepositoryProvider);
    final placeRepo = ref.read(placeRepositoryProvider);
    final cityRepo = ref.read(cityRepositoryProvider);
    final countryRepo = ref.read(countryRepositoryProvider);

    final visits = await visitRepo.getAllVisits();
    final places = await placeRepo.getAllPlaces();
    final cities = await cityRepo.getAllCities();
    final countries = await countryRepo.getAllCountries();

    // Build quick lookups
    final placeById = {for (final p in places) p.id: p};
    final cityById = {for (final c in cities) c.id: c};

    // Only verified visits with resolvable places, sorted newest first
    final entries = visits
        .where((v) => v.verified && placeById.containsKey(v.placeId))
        .map((v) {
          final place = placeById[v.placeId]!;

          // Find city by place.cityId
          final city = cityById[place.cityId];

          // Find country that contains this city
          Country? country;
          if (city != null) {
            country = countries.firstWhereOrNull(
              (c) => c.cityIds.contains(city.id),
            );
          }

          return JournalEntry(
            visit: v,
            place: place,
            city: city,
            country: country,
          );
        })
        .toList()
      ..sort((a, b) => b.visit.visitedAt.compareTo(a.visit.visitedAt));

    // Group by month (map preserves insertion order — newest month first)
    final byMonth = <String, List<JournalEntry>>{};
    for (final e in entries) {
      byMonth.putIfAbsent(e.monthYear, () => []).add(e);
    }

    return PhotoJournalState(entries: entries, byMonth: byMonth);
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final photoJournalViewModelProvider =
    AsyncNotifierProvider<PhotoJournalViewModel, PhotoJournalState>(
  PhotoJournalViewModel.new,
);
