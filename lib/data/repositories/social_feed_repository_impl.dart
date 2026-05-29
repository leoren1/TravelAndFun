// lib/data/repositories/social_feed_repository_impl.dart
//
// Static mock feed with rich variety of event types.
// API-ready: replace _buildFeed() with a Dio call when the backend is ready.

import 'package:explore_index/data/models/social_feed.dart';
import 'package:explore_index/data/repositories/social_feed_repository.dart';

class SocialFeedRepositoryImpl implements SocialFeedRepository {
  const SocialFeedRepositoryImpl();

  @override
  List<SocialFeedItem> getFeed() => _feed;

  @override
  List<SocialFeedItem> getFriendFeed(Set<String> friendIds) =>
      _feed.where((item) => friendIds.contains(item.user.id)).toList();

  // ── Mock data ────────────────────────────────────────────────────────────

  static final _users = <String, FeedUser>{
    'u1': const FeedUser(
      id: 'u1',
      name: 'Leila M.',
      avatarUrl: 'https://i.pravatar.cc/150?img=47',
      travelModeEmoji: '🥇',
    ),
    'u2': const FeedUser(
      id: 'u2',
      name: 'Carlos R.',
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
      travelModeEmoji: '🥈',
    ),
    'u3': const FeedUser(
      id: 'u3',
      name: 'Yuki T.',
      avatarUrl: 'https://i.pravatar.cc/150?img=33',
      travelModeEmoji: '🥇',
    ),
    'u4': const FeedUser(
      id: 'u4',
      name: 'Sofia P.',
      avatarUrl: 'https://i.pravatar.cc/150?img=56',
      travelModeEmoji: '🥉',
    ),
    'u5': const FeedUser(
      id: 'u5',
      name: 'Ahmed K.',
      avatarUrl: 'https://i.pravatar.cc/150?img=68',
      travelModeEmoji: '🥈',
    ),
  };

  static List<SocialFeedItem> get _feed => [
        SocialFeedItem(
          id: 'f1',
          user: _users['u3']!,
          eventType: FeedEventType.hiddenGemFound,
          timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
          subject: 'Yanaka Cemetery at Dawn',
          context: 'Tokyo',
          photoUrl:
              'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=600',
          caption:
              'Found the most peaceful spot in all of Tokyo — a neighbourhood cemetery that turns into a forest walk at dawn. Zero tourists, infinite tranquility.',
          flavourEmoji: '🗾',
          inspiredCount: 47,
          commentCount: 9,
        ),
        SocialFeedItem(
          id: 'f2',
          user: _users['u1']!,
          eventType: FeedEventType.countryUnlock,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          subject: 'Japan',
          context: 'Asia',
          photoUrl:
              'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=600',
          caption:
              'Japan unlocked 🇯🇵 First steps in Kyoto — I\'ve been dreaming about this for three years.',
          discoveryPercent: 3.2,
          flavourEmoji: '🇯🇵',
          inspiredCount: 134,
          commentCount: 28,
        ),
        SocialFeedItem(
          id: 'f3',
          user: _users['u2']!,
          eventType: FeedEventType.explorationStreak,
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          subject: '14-day streak',
          context: 'Barcelona → Madrid',
          caption:
              '14 days straight discovering Spain 🔥 From Gaudí to flamenco, I haven\'t stopped moving. The streak lives.',
          flavourEmoji: '🇪🇸',
          inspiredCount: 88,
          commentCount: 14,
        ),
        SocialFeedItem(
          id: 'f4',
          user: _users['u4']!,
          eventType: FeedEventType.cityUnlock,
          timestamp: DateTime.now().subtract(const Duration(hours: 6)),
          subject: 'Rome',
          context: 'Italy',
          photoUrl:
              'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=600',
          caption:
              'Roma, finalmente! City unlocked 🏙️ The Colosseum at golden hour is literally everything.',
          discoveryPercent: 8.0,
          flavourEmoji: '🇮🇹',
          inspiredCount: 211,
          commentCount: 41,
        ),
        SocialFeedItem(
          id: 'f5',
          user: _users['u3']!,
          eventType: FeedEventType.locationVisit,
          timestamp: DateTime.now().subtract(const Duration(hours: 8)),
          subject: 'Tsukiji Outer Market',
          context: 'Tokyo',
          photoUrl:
              'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=600',
          caption:
              'Early morning tuna auction culture — the most intense food experience I\'ve ever had. Worth the 4am alarm.',
          inspiredCount: 63,
          commentCount: 7,
        ),
        SocialFeedItem(
          id: 'f6',
          user: _users['u5']!,
          eventType: FeedEventType.milestoneReached,
          timestamp: DateTime.now().subtract(const Duration(hours: 14)),
          subject: '100 Places Verified',
          caption:
              'Triple digits 🏆 100 verified places across 8 countries. The world is bigger than I thought and smaller than I feared.',
          flavourEmoji: '🏆',
          inspiredCount: 302,
          commentCount: 67,
        ),
        SocialFeedItem(
          id: 'f7',
          user: _users['u1']!,
          eventType: FeedEventType.locationVisit,
          timestamp: DateTime.now().subtract(const Duration(hours: 20)),
          subject: 'Fushimi Inari Shrine',
          context: 'Kyoto',
          photoUrl:
              'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=600',
          caption:
              'The tunnel of 10,000 torii gates. I walked until there were no more tourists — it took 2 hours but the silence at the top was sacred.',
          inspiredCount: 189,
          commentCount: 33,
        ),
        SocialFeedItem(
          id: 'f8',
          user: _users['u2']!,
          eventType: FeedEventType.firstAmongFriends,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          subject: 'Sagrada Família',
          context: 'Barcelona',
          photoUrl:
              'https://images.unsplash.com/photo-1539037116277-4db20889f2d4?w=600',
          caption:
              'First in my friend group to stand inside Gaudí\'s masterpiece 🥇 The stained glass alone is a religious experience.',
          flavourEmoji: '⛪',
          inspiredCount: 97,
          commentCount: 19,
        ),
        SocialFeedItem(
          id: 'f9',
          user: _users['u5']!,
          eventType: FeedEventType.dnaEvolution,
          timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
          subject: 'Architecture Seeker → Culture Nomad',
          caption:
              'My Travel DNA just evolved 🧬 After 3 weeks immersed in Istanbul\'s history, museums, and bazaars, I\'m officially a Culture Nomad. The algorithm sees me.',
          flavourEmoji: '🧬',
          inspiredCount: 74,
          commentCount: 22,
        ),
        SocialFeedItem(
          id: 'f10',
          user: _users['u4']!,
          eventType: FeedEventType.continentProgress,
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          subject: 'Europe',
          context: '25% milestone',
          photoUrl:
              'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=600',
          caption:
              'One quarter of Europe discovered 🗺️ From Paris to Rome, city by city. The other 75% is calling.',
          discoveryPercent: 25.0,
          flavourEmoji: '🇪🇺',
          inspiredCount: 156,
          commentCount: 31,
        ),
        SocialFeedItem(
          id: 'f11',
          user: _users['u3']!,
          eventType: FeedEventType.hiddenGemFound,
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          subject: 'Golden Gai Alley',
          context: 'Tokyo',
          photoUrl:
              'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=600',
          caption:
              'Six narrow alleys, 200 tiny bars, infinite stories. Golden Gai is Tokyo\'s best-kept secret and I\'m in love with every inch of it.',
          inspiredCount: 118,
          commentCount: 25,
        ),
        SocialFeedItem(
          id: 'f12',
          user: _users['u2']!,
          eventType: FeedEventType.cityUnlock,
          timestamp: DateTime.now().subtract(const Duration(days: 4)),
          subject: 'Madrid',
          context: 'Spain',
          photoUrl:
              'https://images.unsplash.com/photo-1543783207-ec64e4d95325?w=600',
          caption:
              'Madrid unlocked. The Prado holds more beauty per square metre than anywhere else on Earth. Starting Silver mode for Spain 🥈',
          discoveryPercent: 5.5,
          flavourEmoji: '🇪🇸',
          inspiredCount: 82,
          commentCount: 11,
        ),
      ];
}
