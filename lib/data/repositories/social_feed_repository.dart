// lib/data/repositories/social_feed_repository.dart

import 'package:explore_index/data/models/social_feed.dart';

abstract interface class SocialFeedRepository {
  /// Returns the global travel feed, newest-first.
  List<SocialFeedItem> getFeed();

  /// Returns only feed items from [friendIds].
  List<SocialFeedItem> getFriendFeed(Set<String> friendIds);
}
