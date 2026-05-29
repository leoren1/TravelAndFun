// lib/presentation/viewmodels/social_feed_viewmodel.dart

import 'package:explore_index/data/models/social_feed.dart';
import 'package:explore_index/data/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class SocialFeedState {
  final List<SocialFeedItem> items;
  final bool showingFriendsOnly;

  const SocialFeedState({
    required this.items,
    this.showingFriendsOnly = false,
  });

  SocialFeedState copyWith({
    List<SocialFeedItem>? items,
    bool? showingFriendsOnly,
  }) {
    return SocialFeedState(
      items: items ?? this.items,
      showingFriendsOnly: showingFriendsOnly ?? this.showingFriendsOnly,
    );
  }
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class SocialFeedViewModel extends AsyncNotifier<SocialFeedState> {
  // Mock friend IDs — replace with real friends from user profile when API ready.
  static const _friendIds = {'u1', 'u3', 'u5'};

  @override
  Future<SocialFeedState> build() async {
    final repo  = ref.read(socialFeedRepositoryProvider);
    final items = repo.getFeed();

    return SocialFeedState(items: items);
  }

  void toggleFriendsFilter() {
    state.whenData((s) {
      final repo = ref.read(socialFeedRepositoryProvider);
      final newShowingFriends = !s.showingFriendsOnly;
      final items = newShowingFriends
          ? repo.getFriendFeed(_friendIds)
          : repo.getFeed();

      state = AsyncData(SocialFeedState(
        items: items,
        showingFriendsOnly: newShowingFriends,
      ));
    });
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final socialFeedViewModelProvider =
    AsyncNotifierProvider<SocialFeedViewModel, SocialFeedState>(
  SocialFeedViewModel.new,
);
