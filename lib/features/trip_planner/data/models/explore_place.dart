// Detailed place model for immersive discovery
import 'package:flutter/material.dart';

enum DiscoveryTier { mustVisit, popular, hiddenGem }

extension DiscoveryTierX on DiscoveryTier {
  String get label => switch (this) {
        DiscoveryTier.mustVisit => 'Must Visit',
        DiscoveryTier.popular => 'Popular',
        DiscoveryTier.hiddenGem => 'Hidden Gem',
      };

  String get emoji => switch (this) {
        DiscoveryTier.mustVisit => '⭐',
        DiscoveryTier.popular => '🔥',
        DiscoveryTier.hiddenGem => '💎',
      };

  Color get color => switch (this) {
        DiscoveryTier.mustVisit => const Color(0xFFF59E0B),
        DiscoveryTier.popular => const Color(0xFFEF4444),
        DiscoveryTier.hiddenGem => const Color(0xFF7B5BFF),
      };
}

class ExplorePlace {
  final String id;
  final String cityId;
  final String categoryId;
  final String name;
  final String shortDescription;
  final String fullDescription;
  final String gradientStartHex;
  final String gradientEndHex;
  final double rating;          // 0.0–5.0
  final int reviewCount;
  final String estimatedDuration; // "2–3 hours"
  final String bestVisitTime;     // "Early morning"
  final DiscoveryTier tier;
  final int discoveryPoints;      // points awarded for visiting
  final List<String> nearbyPlaceIds;
  final List<String> tags;        // ["Outdoor", "Architecture", "Photography"]
  final double lat;
  final double lng;
  final bool isHighlight;         // featured in hero sections

  const ExplorePlace({
    required this.id,
    required this.cityId,
    required this.categoryId,
    required this.name,
    required this.shortDescription,
    required this.fullDescription,
    required this.gradientStartHex,
    required this.gradientEndHex,
    required this.rating,
    required this.reviewCount,
    required this.estimatedDuration,
    required this.bestVisitTime,
    required this.tier,
    required this.discoveryPoints,
    required this.nearbyPlaceIds,
    required this.tags,
    required this.lat,
    required this.lng,
    required this.isHighlight,
  });

  Color get gradientStart =>
      Color(int.parse('0xFF${gradientStartHex.replaceAll('#', '')}'));
  Color get gradientEnd =>
      Color(int.parse('0xFF${gradientEndHex.replaceAll('#', '')}'));

  String get ratingDisplay => rating.toStringAsFixed(1);
  String get reviewDisplay => reviewCount >= 1000
      ? '${(reviewCount / 1000).toStringAsFixed(1)}k'
      : reviewCount.toString();
}
