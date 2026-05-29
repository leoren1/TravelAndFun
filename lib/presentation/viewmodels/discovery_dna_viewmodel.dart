// lib/presentation/viewmodels/discovery_dna_viewmodel.dart

import 'package:explore_index/data/models/badge.dart';
import 'package:explore_index/data/models/category.dart';
import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/discovery_dna.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/providers.dart';
import 'package:explore_index/domain/usecases/compute_discovery_dna.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Supporting models
// ---------------------------------------------------------------------------

/// A single axis entry for the radar / spider chart.
class DnaAxis {
  final String label;
  final double value; // 0–100

  const DnaAxis({required this.label, required this.value});
}

// ---------------------------------------------------------------------------
// Tier system
// ---------------------------------------------------------------------------

/// One tier (Bronze / Silver / Gold / Platinum) within a single DNA dimension.
class DnaTierEntry {
  /// Matching badge ID from the repository (e.g. 'history_t3').
  final String tierId;

  /// 1 = Bronze, 2 = Silver, 3 = Gold, 4 = Platinum.
  final int tier;

  /// Human-readable tier name (e.g. "Heritage Guardian").
  final String badgeName;

  /// Tier medal emoji (🥉 / 🥈 / 🥇 / 💎).
  final String tierIcon;

  /// True when this tier has been unlocked.
  final bool isEarned;

  /// Current DNA dimension value for this category (0–100).
  final double currentPct;

  /// DNA percentage required to unlock this tier (0–100).
  final double thresholdPct;

  /// Badge description text.
  final String description;

  const DnaTierEntry({
    required this.tierId,
    required this.tier,
    required this.badgeName,
    required this.tierIcon,
    required this.isEarned,
    required this.currentPct,
    required this.thresholdPct,
    required this.description,
  });

  /// How far the user is towards THIS tier's threshold (0–1, clamped).
  /// Uses the absolute ratio: currentPct / thresholdPct.
  double get progressFraction =>
      thresholdPct > 0 ? (currentPct / thresholdPct).clamp(0.0, 1.0) : 0;

  /// Percentage points still needed (0 if already earned).
  double get remaining =>
      isEarned ? 0.0 : (thresholdPct - currentPct).clamp(0.0, 100.0);

  /// Tier label string.
  String get tierLabel => switch (tier) {
        1 => 'Bronze',
        2 => 'Silver',
        3 => 'Gold',
        4 => 'Platinum',
        _ => 'Tier $tier',
      };
}

/// All 4 tiers for one DNA dimension (e.g. History, Food …).
class DnaDimensionBlock {
  final String dimensionLabel; // e.g. 'History'
  final String dimensionIcon;  // e.g. '🏛️'
  final double currentPct;     // current DNA value 0–100

  /// Ordered Bronze → Silver → Gold → Platinum.
  final List<DnaTierEntry> tiers;

  const DnaDimensionBlock({
    required this.dimensionLabel,
    required this.dimensionIcon,
    required this.currentPct,
    required this.tiers,
  });

  /// Number of tiers already earned (0–4).
  int get earnedTiers => tiers.where((t) => t.isEarned).length;

  /// Label of the highest earned tier, or 'Beginner' if none earned.
  String get currentTierLabel {
    final earned = tiers.where((t) => t.isEarned).toList();
    if (earned.isEmpty) return 'Beginner';
    return earned.last.tierLabel;
  }

  /// The first unearned tier, or null if all 4 are earned.
  DnaTierEntry? get nextTier {
    for (final t in tiers) {
      if (!t.isEarned) return t;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Target suggestion
// ---------------------------------------------------------------------------

/// A personalised suggestion: visit these places in this city to boost a
/// weak DNA dimension.
class DnaTarget {
  final City city;
  final String categoryLabel;
  final String categoryIcon;
  final double currentPct;
  final List<String> suggestedPlaceNames;

  const DnaTarget({
    required this.city,
    required this.categoryLabel,
    required this.categoryIcon,
    required this.currentPct,
    required this.suggestedPlaceNames,
  });
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class DiscoveryDnaState {
  final DiscoveryDna dna;

  /// Radar chart axes, sorted descending by value.
  final List<DnaAxis> axes;

  /// Axis with the highest value (null when no data).
  final DnaAxis? topAxis;

  /// Axis with the lowest value (null when no data).
  final DnaAxis? bottomAxis;

  /// Whether the user has enough activity for meaningful insights.
  final bool hasData;

  /// One block per DNA dimension, each with 4 tier entries.
  /// Sorted descending by [DnaDimensionBlock.currentPct].
  final List<DnaDimensionBlock> dimensionBlocks;

  /// Up to 3 personalised target suggestions (weakest DNA dimensions).
  final List<DnaTarget> targets;

  /// Total tiers earned across all dimensions.
  int get earnedCount =>
      dimensionBlocks.fold(0, (sum, b) => sum + b.earnedTiers);

  /// Maximum possible tiers (dimensions × 4).
  int get totalTiers =>
      dimensionBlocks.fold(0, (sum, b) => sum + b.tiers.length);

  const DiscoveryDnaState({
    required this.dna,
    required this.axes,
    this.topAxis,
    this.bottomAxis,
    required this.hasData,
    required this.dimensionBlocks,
    required this.targets,
  });

  DiscoveryDnaState copyWith({
    DiscoveryDna? dna,
    List<DnaAxis>? axes,
    DnaAxis? topAxis,
    DnaAxis? bottomAxis,
    bool? hasData,
    List<DnaDimensionBlock>? dimensionBlocks,
    List<DnaTarget>? targets,
  }) {
    return DiscoveryDnaState(
      dna: dna ?? this.dna,
      axes: axes ?? this.axes,
      topAxis: topAxis ?? this.topAxis,
      bottomAxis: bottomAxis ?? this.bottomAxis,
      hasData: hasData ?? this.hasData,
      dimensionBlocks: dimensionBlocks ?? this.dimensionBlocks,
      targets: targets ?? this.targets,
    );
  }
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class DiscoveryDnaViewModel extends AsyncNotifier<DiscoveryDnaState> {
  @override
  Future<DiscoveryDnaState> build() async {
    final cities    = await ref.read(cityRepositoryProvider).getAllCities();
    final places    = await ref.read(placeRepositoryProvider).getAllPlaces();
    final visits    = await ref.read(visitRepositoryProvider).getAllVisits();
    final profile   = await ref.read(userRepositoryProvider).getUserProfile();
    final allBadges = await ref.read(userRepositoryProvider).getAllBadges();

    // ── Discovery DNA ──────────────────────────────────────────────────
    final dna = ComputeDiscoveryDna(
      cities: cities,
      visits: visits,
      places: places,
    ).execute();

    final axesList = dna.dimensions.entries
        .map((e) => DnaAxis(label: e.key, value: e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final hasData = visits.isNotEmpty;

    // ── Dimension blocks (4 tiers per dimension) ───────────────────────
    final earnedIds = profile.badgeIds.toSet();
    final dimensionBlocks = _computeDimensionBlocks(
      allBadges: allBadges,
      earnedIds: earnedIds,
      dna: dna,
    );

    // ── Target suggestions ─────────────────────────────────────────────
    final visitedPlaceIds = visits.map((v) => v.placeId).toSet();
    final targets = _computeTargets(
      weakAxes: axesList.reversed.take(3).toList(),
      cities: cities,
      places: places,
      visitedPlaceIds: visitedPlaceIds,
    );

    return DiscoveryDnaState(
      dna: dna,
      axes: axesList,
      topAxis: axesList.isNotEmpty ? axesList.first : null,
      bottomAxis: axesList.isNotEmpty ? axesList.last : null,
      hasData: hasData,
      dimensionBlocks: dimensionBlocks,
      targets: targets,
    );
  }

  Future<void> refresh() async => ref.invalidateSelf();

  // ── Helpers ──────────────────────────────────────────────────────────

  /// Maps a badge's [categoryKey] to the corresponding DNA dimension value
  /// (0–100).  This is the single source of truth for the tier calculations.
  static double _dnaForCategory(String key, DiscoveryDna dna) {
    return switch (key) {
      'historicalPlaces' => dna.history,
      'foodRestaurants'  => dna.food,
      'cafes'            => dna.food * 0.8, // cafés share the food dimension
      'museumsArt'       => dna.museums,
      'routes'           => dna.localExp,
      'nature'           => dna.nature,
      'nightlife'        => dna.nightlife,
      'localMarkets'     => dna.shopping,
      'hiddenGems'       => dna.localExp,
      'events'           => dna.events,
      _                  => 0.0,
    };
  }

  /// Human-readable label for a DNA category key.
  static String _dimensionLabel(String categoryKey) => switch (categoryKey) {
        'historicalPlaces' => 'History',
        'foodRestaurants'  => 'Food',
        'nature'           => 'Nature',
        'events'           => 'Events',
        'nightlife'        => 'Nightlife',
        'hiddenGems'       => 'Local Exp',
        'localMarkets'     => 'Shopping',
        'museumsArt'       => 'Museums',
        _                  => categoryKey,
      };

  /// Emoji icon for a DNA category key.
  static String _dimensionIcon(String categoryKey) => switch (categoryKey) {
        'historicalPlaces' => '🏛️',
        'foodRestaurants'  => '🍽️',
        'nature'           => '🌿',
        'events'           => '🎭',
        'nightlife'        => '🌙',
        'hiddenGems'       => '🗺️',
        'localMarkets'     => '🛍️',
        'museumsArt'       => '🎨',
        _                  => '📍',
      };

  /// Returns [CategoryType] matching a radar-axis label.
  static CategoryType _categoryForAxisLabel(String label) {
    return switch (label) {
      'History'   => CategoryType.historicalPlaces,
      'Food'      => CategoryType.foodRestaurants,
      'Nature'    => CategoryType.nature,
      'Events'    => CategoryType.events,
      'Nightlife' => CategoryType.nightlife,
      'Local Exp' => CategoryType.hiddenGems,
      'Shopping'  => CategoryType.localMarkets,
      'Museums'   => CategoryType.museumsArt,
      _           => CategoryType.hiddenGems,
    };
  }

  // ── Dimension blocks builder ──────────────────────────────────────────

  /// Fixed dimension order (matches [DiscoveryDna.dimensions] map order).
  static const _dimOrder = [
    'historicalPlaces',
    'foodRestaurants',
    'nature',
    'events',
    'nightlife',
    'hiddenGems',
    'localMarkets',
    'museumsArt',
  ];

  static List<DnaDimensionBlock> _computeDimensionBlocks({
    required List<Badge> allBadges,
    required Set<String> earnedIds,
    required DiscoveryDna dna,
  }) {
    final blocks = <DnaDimensionBlock>[];

    for (final catKey in _dimOrder) {
      final currentPct = _dnaForCategory(catKey, dna);

      // All badges for this dimension, sorted Bronze → Platinum.
      final dimBadges = allBadges
          .where((b) => b.categoryKey == catKey)
          .toList()
        ..sort((a, b) => a.tier.compareTo(b.tier));

      final tierEntries = dimBadges.map((badge) {
        final threshPct = badge.threshold * 100;
        // A tier is earned if explicitly recorded on the profile OR if the
        // current DNA value already meets or exceeds its threshold.
        final isEarned =
            earnedIds.contains(badge.id) || currentPct >= threshPct;
        return DnaTierEntry(
          tierId: badge.id,
          tier: badge.tier,
          badgeName: badge.name,
          tierIcon: badge.icon,
          isEarned: isEarned,
          currentPct: currentPct,
          thresholdPct: threshPct,
          description: badge.description,
        );
      }).toList();

      blocks.add(DnaDimensionBlock(
        dimensionLabel: _dimensionLabel(catKey),
        dimensionIcon: _dimensionIcon(catKey),
        currentPct: currentPct,
        tiers: tierEntries,
      ));
    }

    // Strongest DNA dimension first.
    blocks.sort((a, b) => b.currentPct.compareTo(a.currentPct));
    return blocks;
  }

  // ── Target suggestions builder ────────────────────────────────────────

  /// Finds the best city + unvisited places for each of the given weak axes.
  static List<DnaTarget> _computeTargets({
    required List<DnaAxis> weakAxes,
    required List<City> cities,
    required List<Place> places,
    required Set<String> visitedPlaceIds,
  }) {
    final targets = <DnaTarget>[];

    for (final axis in weakAxes) {
      final category = _categoryForAxisLabel(axis.label);

      City? bestCity;
      List<String> bestPlaces = [];

      for (final city in cities) {
        final unvisited = places
            .where((p) =>
                p.cityId == city.id &&
                p.category == category &&
                !visitedPlaceIds.contains(p.id))
            .toList();
        if (unvisited.length > bestPlaces.length) {
          bestCity   = city;
          bestPlaces = unvisited.take(3).map((p) => p.name).toList();
        }
      }

      if (bestCity != null && bestPlaces.isNotEmpty) {
        targets.add(DnaTarget(
          city: bestCity,
          categoryLabel: axis.label,
          categoryIcon: _dimensionIcon(_categoryForAxisLabel(axis.label).jsonKey),
          currentPct: axis.value,
          suggestedPlaceNames: bestPlaces,
        ));
      }
    }

    return targets;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final discoveryDnaViewModelProvider =
    AsyncNotifierProvider<DiscoveryDnaViewModel, DiscoveryDnaState>(
  DiscoveryDnaViewModel.new,
);
