// lib/presentation/viewmodels/profile_viewmodel.dart

import 'package:explore_index/data/models/badge.dart';
import 'package:explore_index/data/models/travel_mode.dart';
import 'package:explore_index/data/models/user_profile.dart';
import 'package:explore_index/data/providers.dart';
import 'package:explore_index/domain/usecases/calculate_world_discovery.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Supporting models
// ---------------------------------------------------------------------------

class BadgeEntry {
  final Badge badge;
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
  final int totalVisits;
  final int citiesVisited;
  final int countriesVisited;
  final double averageRating;
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

/// Mode-specific discovery percentages.
class ModeDiscovery {
  final double bronze;
  final double silver;
  final double gold;

  const ModeDiscovery({
    required this.bronze,
    required this.silver,
    required this.gold,
  });
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ProfileState {
  final UserProfile profile;
  final List<BadgeEntry> badges;
  final UserStats stats;

  /// Discovery % for each travel mode — used in the profile mode stats section.
  final ModeDiscovery modeDiscovery;

  /// Currently active travel mode.
  final TravelMode currentMode;

  const ProfileState({
    required this.profile,
    required this.badges,
    required this.stats,
    required this.modeDiscovery,
    required this.currentMode,
  });

  List<BadgeEntry> get unlockedBadges =>
      badges.where((b) => b.isUnlocked).toList();
  List<BadgeEntry> get lockedBadges =>
      badges.where((b) => !b.isUnlocked).toList();

  ProfileState copyWith({
    UserProfile? profile,
    List<BadgeEntry>? badges,
    UserStats? stats,
    ModeDiscovery? modeDiscovery,
    TravelMode? currentMode,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      badges: badges ?? this.badges,
      stats: stats ?? this.stats,
      modeDiscovery: modeDiscovery ?? this.modeDiscovery,
      currentMode: currentMode ?? this.currentMode,
    );
  }
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class ProfileViewModel extends AsyncNotifier<ProfileState> {
  @override
  Future<ProfileState> build() async {
    // Rebuild when mode changes so the active mode chip updates.
    final currentMode = ref.watch(travelModeProvider);

    final userRepo  = ref.read(userRepositoryProvider);
    final placeRepo = ref.read(placeRepositoryProvider);
    final visitRepo = ref.read(visitRepositoryProvider);
    final cityRepo  = ref.read(cityRepositoryProvider);
    final countryRepo = ref.read(countryRepositoryProvider);

    final profile    = await userRepo.getUserProfile();
    final allBadges  = await userRepo.getAllBadges();
    final visits     = await visitRepo.getAllVisits();
    final places     = await placeRepo.getAllPlaces();
    final cities     = await cityRepo.getAllCities();
    final countries  = await countryRepo.getAllCountries();

    // Build badge entries.
    final badgeEntries = allBadges.map((badge) {
      return BadgeEntry(
        badge: badge,
        isUnlocked: profile.badgeIds.contains(badge.id),
      );
    }).toList()
      ..sort((a, b) {
        if (a.isUnlocked != b.isUnlocked) return a.isUnlocked ? -1 : 1;
        return a.badge.name.compareTo(b.badge.name);
      });

    // Stats.
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

    final ratingSum = visits.fold<double>(0, (sum, v) => sum + v.rating);
    final avgRating = visits.isEmpty ? 0.0 : ratingSum / visits.length;

    final stats = UserStats(
      totalVisits: visits.length,
      citiesVisited: visitedCityIds.length,
      countriesVisited: visitedCountryIds.length,
      averageRating: avgRating,
      uniquePlacesVisited: uniquePlaceIds.length,
    );

    // Mode-specific discovery percentages.
    double _disc(TravelMode m) => CalculateWorldDiscovery(
          countries: countries,
          cities: cities,
          visits: visits,
          places: places,
          mode: m,
        ).execute();

    final modeDiscovery = ModeDiscovery(
      bronze: _disc(TravelMode.bronze),
      silver: _disc(TravelMode.silver),
      gold:   _disc(TravelMode.gold),
    );

    return ProfileState(
      profile: profile,
      badges: badgeEntries,
      stats: stats,
      modeDiscovery: modeDiscovery,
      currentMode: currentMode,
    );
  }

  Future<void> refresh() async => ref.invalidateSelf();

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
