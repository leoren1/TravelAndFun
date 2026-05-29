// lib/data/models/social_feed.dart
//
// Social Feed data models.
// The feed is travel-first — NOT a generic social network.
// One location = ONE photo maximum (core product philosophy).

enum FeedEventType {
  locationVisit,     // user verified a new place
  cityUnlock,        // user's first verified visit in a new city
  countryUnlock,     // user's first verified visit in a new country
  milestoneReached,  // e.g. "50 places verified"
  hiddenGemFound,    // verified a PlaceTier.gold place
  firstAmongFriends, // first in friend group to visit a place/city
  explorationStreak, // X days in a row with verified visits
  dnaEvolution,      // Travel DNA archetype changed
  continentProgress, // crossed 25/50/75/100% of a continent
}

extension FeedEventTypeX on FeedEventType {
  String get emoji => switch (this) {
        FeedEventType.locationVisit     => '📍',
        FeedEventType.cityUnlock        => '🏙️',
        FeedEventType.countryUnlock     => '🌍',
        FeedEventType.milestoneReached  => '🏆',
        FeedEventType.hiddenGemFound    => '💎',
        FeedEventType.firstAmongFriends => '🥇',
        FeedEventType.explorationStreak => '🔥',
        FeedEventType.dnaEvolution      => '🧬',
        FeedEventType.continentProgress => '🗺️',
      };

  String get verb => switch (this) {
        FeedEventType.locationVisit     => 'visited',
        FeedEventType.cityUnlock        => 'unlocked',
        FeedEventType.countryUnlock     => 'conquered',
        FeedEventType.milestoneReached  => 'reached a milestone',
        FeedEventType.hiddenGemFound    => 'found a hidden gem',
        FeedEventType.firstAmongFriends => 'was first among friends',
        FeedEventType.explorationStreak => 'is on a streak',
        FeedEventType.dnaEvolution      => 'evolved their DNA',
        FeedEventType.continentProgress => 'progressed in',
      };
}

// ---------------------------------------------------------------------------

class FeedUser {
  final String id;
  final String name;
  final String avatarUrl;
  final String travelModeEmoji; // 🥉🥈🥇

  const FeedUser({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.travelModeEmoji,
  });
}

// ---------------------------------------------------------------------------

class SocialFeedItem {
  final String id;
  final FeedUser user;
  final FeedEventType eventType;
  final DateTime timestamp;

  /// Primary subject text (place name, city name, milestone label, etc.)
  final String subject;

  /// Optional secondary context (city name for locationVisit, etc.)
  final String? context;

  /// Optional single photo (one-photo-per-location rule).
  final String? photoUrl;

  /// Short human-readable caption generated from the event.
  final String caption;

  /// Optional discovery percentage shown for city/country unlock events.
  final double? discoveryPercent;

  /// Optional emoji for extra flavour (e.g. flag emoji for country unlock).
  final String? flavourEmoji;

  /// Reaction count (likes equivalent but travel-themed: "🌍 Inspired").
  final int inspiredCount;

  /// Number of comments.
  final int commentCount;

  const SocialFeedItem({
    required this.id,
    required this.user,
    required this.eventType,
    required this.timestamp,
    required this.subject,
    this.context,
    this.photoUrl,
    required this.caption,
    this.discoveryPercent,
    this.flavourEmoji,
    this.inspiredCount = 0,
    this.commentCount = 0,
  });
}
