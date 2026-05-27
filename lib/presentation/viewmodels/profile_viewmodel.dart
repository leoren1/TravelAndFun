// lib/presentation/viewmodels/profile_viewmodel.dart

import 'package:explore_index/data/models/badge.dart';
import 'package:explore_index/data/models/user_profile.dart';
import 'package:explore_index/data/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Supporting models
// ---------------------------------------------------------------------------

class BadgeEntry {
  final Badge badge;

  /// True when the badge id is present in the user's [UserProfile.badgeIds].
  final bool isUnlocked;

  const BadgeEntry({required this.badge, required this.isUnlocked});

  BadgeEntry copyWith({Badge? badge, bool? isUnlocked}) {
    return BadgeEntry(
      badge: badge ?? this.badge,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}

class UserStats {
  /// Total verified visits across all places.
  final int totalVisits;

  /// Distinct cities that have at least one verified visit.
  final int citiesVisited;

  /// Distinct countries visited (derived from cities).
  final int countriesVisited;

  /// Average rating across all visits (0.0 if none).
  final double averageRating;

  /// Number of places the user has verified (distinct place ids).
  final int uniquePlacesVisited;

  const UserStats({
    required this.totalVisits,
    required this.citiesVisited,
    required this.countriesVisited,
    required this.averageRating,
    required this.uniquePlacesVisited,
  });

  UserStats copyWith({
    int? totalVisits,
    int? citiesVisited,
    int? countriesVisited,
    double? averageRating,
    int? uniquePlacesVisited,
  }) {
    return UserStats(
      totalVisits: totalVisits ?? this.totalVisits,
      citiesVisited: citiesVisited ?? this.citiesVisited,
      countriesVisited: countriesVisited ?? this.countriesVisited,
      averageRating: averageRating ?? this.averageRating,
      uniquePlacesVisited: uniquePlacesVisited ?? this.uniquePlacesVisited,
    );
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ProfileState {
  final UserProfile profile;

  /// All badge definitions, each annotated with locked/unlocked status.
  final List<BadgeEntry> badges;

  /// Aggregated user statistics.
  final UserStats stats;

  const ProfileState({
    required this.profile,
    required this.badges,
    required this.stats,
  });

  List<BadgeEntry> get unlockedBadges =>
      badges.where((b) => b.isUnlocked).toList();
  List<BadgeEntry> get lockedBadges =>
      badges.where((b) => !b.isUnlocked).toList();

  ProfileState copyWith({
    UserProfile? profile,
    List<BadgeEntry>? badges,
    UserStats? stats,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      badges: badges ?? this.badges,
      stats: stats ?? this.stats,
    );
  }
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class ProfileViewModel extends AsyncNotifier<ProfileState> {
  @override
  Future<ProfileState> build() async {
    final userRepo = ref.read(userRepositoryProvider);
    final placeRepo = ref.read(placeRepositoryProvider);
    final visitRepo = ref.read(visitRepositoryProvider);
    final cityRepo = ref.read(cityRepositoryProvider);

    final profile = await userRepo.getUserProfile();
    final allBadges = await userRepo.getAllBadges();
    final visits = await visitRepo.getAllVisits();
    final places = await placeRepo.getAllPlaces();
    final cities = await cityRepo.getAllCities();

    // Build badge entries with locked/unlocked status.
    final badgeEntries = allBadges.map((badge) {
      return BadgeEntry(
        badge: badge,
        isUnlocked: profile.badgeIds.contains(badge.id),
      );
    }).toList();

    // Sort: unlocked first, then alphabetically by name.
    badgeEntries.sort((a, b) {
      if (a.isUnlocked != b.isUnlocked) return a.isUnlocked ? -1 : 1;
      return a.badge.name.compareTo(b.badge.name);
    });

    // Compute stats.
    final uniquePlaceIds = visits.map((v) => v.placeId).toSet();

    final visitedCityIds = <String>{};
    for (final placeId in uniquePlaceIds) {
      final idx = places.indexWhere((p) => p.id == placeId);
      if (idx >= 0) visitedCityIds.add(places[idx].cityId);
    }

    final visitedCountryIds = cities
        .where((c) => visitedCityIds.contains(c.id))
        .map((c) => c.countryId)
        .toSet();

    final ratingSum =
        visits.fold<double>(0, (sum, v) => sum + v.rating);
    final avgRating =
        visits.isEmpty ? 0.0 : ratingSum / visits.length;

    final stats = UserStats(
      totalVisits: visits.length,
      citiesVisited: visitedCityIds.length,
      countriesVisited: visitedCountryIds.length,
      averageRating: avgRating,
      uniquePlacesVisited: uniquePlaceIds.length,
    );

    return ProfileState(
      profile: profile,
      badges: badgeEntries,
      stats: stats,
    );
  }

  Future<void> refresh() async => ref.invalidateSelf();

  /// Updates the user profile and refreshes state.
  Future<void> updateProfile(UserProfile updated) async {
    await ref.read(userRepositoryProvider).updateUserProfile(updated);
    await refresh();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final profileViewModelProvider =
    AsyncNotifierProvider<ProfileViewModel, ProfileState>(
  ProfileViewModel.new,
);
