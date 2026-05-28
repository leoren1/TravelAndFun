// lib/data/repositories/user_repository.dart
// Abstract contract AND concrete implementation for user/badge data access.
// Both live in one file because the impl has no platform-specific dependencies.

import 'dart:convert';

import 'package:explore_index/core/utils/app_logger.dart';
import 'package:explore_index/data/models/badge.dart';
import 'package:explore_index/data/models/discovery_dna.dart';
import 'package:explore_index/data/models/user_profile.dart';
import 'package:explore_index/data/services/local_storage_service.dart';
import 'package:explore_index/data/services/static_data_service.dart';

// ── Abstract interface ────────────────────────────────────────────────────────

abstract class UserRepository {
  /// Returns the current user's profile.
  Future<UserProfile> getUserProfile();

  /// Persists [profile] and returns the saved version.
  Future<UserProfile> updateUserProfile(UserProfile profile);

  /// Returns all badge definitions.
  Future<List<Badge>> getAllBadges();

  /// Returns only badges that have been earned by [userId].
  Future<List<Badge>> getBadgesByUser(String userId);

  /// Returns the Discovery DNA for [userId].
  Future<DiscoveryDna?> getDiscoveryDna(String userId);

  /// Persists [dna] for [userId].
  Future<void> saveDiscoveryDna(String userId, DiscoveryDna dna);
}

// ── Concrete implementation ───────────────────────────────────────────────────

/// [UserRepository] implementation that:
///  - reads the initial profile from the bundled JSON asset (via [StaticDataService])
///  - persists profile updates in Hive (via [LocalStorageService])
///  - stores Discovery DNA in Hive as a JSON string
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({
    required StaticDataService staticDataService,
    required LocalStorageService localStorage,
  })  : _static = staticDataService,
        _storage = localStorage;

  final StaticDataService _static;
  final LocalStorageService _storage;

  static const String _profileKey = 'current_user_profile';
  static const String _dnaCachePrefix = 'discovery_dna_';

  // ── Profile ────────────────────────────────────────────────────────────────

  @override
  Future<UserProfile> getUserProfile() async {
    // Try persisted version first.
    final cached = _storage.userProfileBox.get(_profileKey);
    if (cached != null) {
      try {
        return UserProfile.fromJson(
            json.decode(cached) as Map<String, dynamic>);
      } catch (e) {
        AppLogger.w('UserRepository', 'Corrupt profile cache — falling back to asset', e);
      }
    }

    // Fall back to bundled static data.
    return _static.getUserProfile();
  }

  @override
  Future<UserProfile> updateUserProfile(UserProfile profile) async {
    await _storage.userProfileBox.put(_profileKey, json.encode(profile.toJson()));
    return profile;
  }

  // ── Badges ─────────────────────────────────────────────────────────────────

  /// Loads badge definitions from the bundled JSON asset.
  @override
  Future<List<Badge>> getAllBadges() => _static.getBadges();

  @override
  Future<List<Badge>> getBadgesByUser(String userId) async {
    final profile = await getUserProfile();
    final all = await getAllBadges();
    return all.where((b) => profile.badgeIds.contains(b.id)).toList();
  }

  // ── Discovery DNA ──────────────────────────────────────────────────────────

  @override
  Future<DiscoveryDna?> getDiscoveryDna(String userId) async {
    final cached = _storage.cacheBox.get('$_dnaCachePrefix$userId');
    if (cached != null) {
      try {
        return DiscoveryDna.fromJson(
            json.decode(cached) as Map<String, dynamic>);
      } catch (e) {
        AppLogger.w('UserRepository', 'Corrupt DNA cache for $userId', e);
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> saveDiscoveryDna(String userId, DiscoveryDna dna) async {
    await _storage.cacheBox.put(
      '$_dnaCachePrefix$userId',
      json.encode(dna.toJson()),
    );
  }

}
