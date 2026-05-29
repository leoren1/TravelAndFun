// lib/domain/usecases/award_badges.dart
//
// Awards tier badges to a user based on their computed DiscoveryDna values.
// Each of the 8 DNA dimensions has 4 tiers (Bronze/Silver/Gold/Platinum).
// Thresholds mirror those in UserRepositoryImpl._defaultBadges exactly.
//
// NOTE: The DNA viewmodel auto-computes earned status from thresholds so this
// usecase is only needed when you want to persist earned badge IDs to the user
// profile (e.g. to show unlocked state even before DNA is recomputed).

import 'package:explore_index/data/models/discovery_dna.dart';

class _TierBadge {
  final String id;
  final String categoryKey; // DNA category key
  final double threshold;   // 0–1 fraction (same unit as badge.threshold)

  const _TierBadge(this.id, this.categoryKey, this.threshold);
}

class AwardBadges {
  /// All 32 tier badge definitions (8 dimensions × 4 tiers).
  /// Must stay in sync with UserRepositoryImpl._defaultBadges.
  static const List<_TierBadge> _definitions = [
    // History
    _TierBadge('history_t1',  'historicalPlaces', 0.20),
    _TierBadge('history_t2',  'historicalPlaces', 0.40),
    _TierBadge('history_t3',  'historicalPlaces', 0.65),
    _TierBadge('history_t4',  'historicalPlaces', 0.85),
    // Food
    _TierBadge('food_t1',     'foodRestaurants',  0.20),
    _TierBadge('food_t2',     'foodRestaurants',  0.40),
    _TierBadge('food_t3',     'foodRestaurants',  0.65),
    _TierBadge('food_t4',     'foodRestaurants',  0.85),
    // Nature
    _TierBadge('nature_t1',   'nature',           0.20),
    _TierBadge('nature_t2',   'nature',           0.40),
    _TierBadge('nature_t3',   'nature',           0.65),
    _TierBadge('nature_t4',   'nature',           0.85),
    // Events
    _TierBadge('events_t1',   'events',           0.20),
    _TierBadge('events_t2',   'events',           0.40),
    _TierBadge('events_t3',   'events',           0.65),
    _TierBadge('events_t4',   'events',           0.85),
    // Nightlife
    _TierBadge('nightlife_t1','nightlife',        0.20),
    _TierBadge('nightlife_t2','nightlife',        0.40),
    _TierBadge('nightlife_t3','nightlife',        0.65),
    _TierBadge('nightlife_t4','nightlife',        0.85),
    // Local Exp
    _TierBadge('localexp_t1', 'hiddenGems',       0.20),
    _TierBadge('localexp_t2', 'hiddenGems',       0.40),
    _TierBadge('localexp_t3', 'hiddenGems',       0.65),
    _TierBadge('localexp_t4', 'hiddenGems',       0.85),
    // Shopping
    _TierBadge('shopping_t1', 'localMarkets',     0.20),
    _TierBadge('shopping_t2', 'localMarkets',     0.40),
    _TierBadge('shopping_t3', 'localMarkets',     0.65),
    _TierBadge('shopping_t4', 'localMarkets',     0.85),
    // Museums
    _TierBadge('museums_t1',  'museumsArt',       0.20),
    _TierBadge('museums_t2',  'museumsArt',       0.40),
    _TierBadge('museums_t3',  'museumsArt',       0.65),
    _TierBadge('museums_t4',  'museumsArt',       0.85),
  ];

  final DiscoveryDna dna;
  final List<String> alreadyAwarded;

  const AwardBadges({
    required this.dna,
    required this.alreadyAwarded,
  });

  /// Returns badge IDs that should now be added to the user profile.
  List<String> execute() {
    final awarded = alreadyAwarded.toSet();
    final newBadges = <String>[];

    for (final def in _definitions) {
      if (awarded.contains(def.id)) continue;
      final dimensionValue = _dnaValue(def.categoryKey);
      if (dimensionValue >= def.threshold * 100) {
        newBadges.add(def.id);
      }
    }

    return newBadges;
  }

  /// Returns the current DNA percentage (0–100) for a given category key.
  /// Must match [DiscoveryDnaViewModel._dnaForCategory] exactly.
  double _dnaValue(String key) => switch (key) {
        'historicalPlaces' => dna.history,
        'foodRestaurants'  => dna.food,
        'nature'           => dna.nature,
        'events'           => dna.events,
        'nightlife'        => dna.nightlife,
        'hiddenGems'       => dna.localExp,
        'localMarkets'     => dna.shopping,
        'museumsArt'       => dna.museums,
        _                  => 0.0,
      };
}
