// lib/presentation/views/social_feed/social_feed_view.dart
//
// Premium travel social feed — NOT an Instagram clone.
// Every card is a milestone, discovery, or travel story.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/data/models/social_feed.dart';
import 'package:explore_index/presentation/viewmodels/social_feed_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

class SocialFeedView extends ConsumerWidget {
  const SocialFeedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(socialFeedViewModelProvider);

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        titleSpacing: AppSpacing.lg,
        title: const Text('Travel Feed', style: AppTextStyles.titleSmall),
        actions: [
          asyncState.whenOrNull(
            data: (state) => GestureDetector(
              onTap: () => ref
                  .read(socialFeedViewModelProvider.notifier)
                  .toggleFriendsFilter(),
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: state.showingFriendsOnly
                      ? AppColors.primary.withOpacity(0.2)
                      : context.appColors.surfaceElevated,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusChip),
                  border: Border.all(
                    color: state.showingFriendsOnly
                        ? AppColors.primary
                        : context.appColors.divider,
                  ),
                ),
                child: Text(
                  state.showingFriendsOnly ? 'Friends ✓' : 'Everyone',
                  style: AppTextStyles.overline.copyWith(
                    color: state.showingFriendsOnly
                        ? AppColors.primary
                        : context.appColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ) ?? const SizedBox.shrink(),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: asyncState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Text(err.toString(), style: AppTextStyles.body),
        ),
        data: (state) => SafeArea(
          top: false,
          bottom: true,
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: context.appColors.surfaceElevated,
            onRefresh: () =>
                ref.read(socialFeedViewModelProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: AppSpacing.lg,
                bottom: AppSpacing.xxxl,
              ),
              itemCount: state.items.length,
              itemBuilder: (context, index) =>
                  _FeedCard(item: state.items[index]),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feed Card
// ---------------------------------------------------------------------------

class _FeedCard extends StatelessWidget {
  final SocialFeedItem item;
  const _FeedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal, 0,
        AppSpacing.pageHorizontal, AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: context.appColors.surfaceElevated,
                  backgroundImage:
                      CachedNetworkImageProvider(item.user.avatarUrl),
                ),
                const SizedBox(width: AppSpacing.md),
                // Name + event type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(item.user.name, style: AppTextStyles.bodyMedium),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            item.user.travelModeEmoji,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      Text(
                        _buildSubtitle(),
                        style: AppTextStyles.captionMuted,
                      ),
                    ],
                  ),
                ),
                // Time ago
                Text(_timeAgo(item.timestamp),
                    style: AppTextStyles.captionMuted),
              ],
            ),
          ),

          // ── Event type banner ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _EventBanner(item: item),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Photo (optional — one photo per location rule) ───────────────
          if (item.photoUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: CachedNetworkImage(
                imageUrl: item.photoUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 200,
                  color: context.appColors.surfaceElevated,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 200,
                  color: context.appColors.surfaceElevated,
                  alignment: Alignment.center,
                  child: Icon(Icons.broken_image_outlined,
                      color: context.appColors.textMuted),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // ── Caption ──────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              item.caption,
              style: AppTextStyles.body.copyWith(
                color: context.appColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Footer: reactions + comments ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            child: Row(
              children: [
                _ReactionButton(
                  emoji: '🌍',
                  label: 'Inspired',
                  count: item.inspiredCount,
                ),
                const SizedBox(width: AppSpacing.xl),
                _ReactionButton(
                  emoji: '💬',
                  label: 'Comments',
                  count: item.commentCount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle() {
    final verb = item.eventType.verb;
    if (item.context != null) {
      return '$verb · ${item.context}';
    }
    return verb;
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

// ---------------------------------------------------------------------------
// Event Banner — colour-coded by event type
// ---------------------------------------------------------------------------

class _EventBanner extends StatelessWidget {
  final SocialFeedItem item;
  const _EventBanner({required this.item});

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor) = _colors(item.eventType);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Row(
        children: [
          Text(
            item.eventType.emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _bannerText(),
              style: AppTextStyles.caption.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (item.discoveryPercent != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${item.discoveryPercent!.toStringAsFixed(1)}%',
              style: AppTextStyles.overline.copyWith(
                color: textColor.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _bannerText() {
    final emoji = item.flavourEmoji != null ? '${item.flavourEmoji} ' : '';
    switch (item.eventType) {
      case FeedEventType.locationVisit:
        return '${emoji}Visited ${item.subject}';
      case FeedEventType.cityUnlock:
        return '${emoji}City Unlocked: ${item.subject}';
      case FeedEventType.countryUnlock:
        return '${emoji}Country Unlocked: ${item.subject}';
      case FeedEventType.milestoneReached:
        return '${emoji}${item.subject}';
      case FeedEventType.hiddenGemFound:
        return '${emoji}Hidden Gem: ${item.subject}';
      case FeedEventType.firstAmongFriends:
        return '${emoji}First Among Friends — ${item.subject}';
      case FeedEventType.explorationStreak:
        return '${emoji}${item.subject}';
      case FeedEventType.dnaEvolution:
        return '${emoji}DNA Evolved';
      case FeedEventType.continentProgress:
        return '${emoji}${item.subject} — ${item.context}';
    }
  }

  static (Color, Color) _colors(FeedEventType type) {
    return switch (type) {
      FeedEventType.locationVisit     => (AppColors.primary.withOpacity(0.12), AppColors.primary),
      FeedEventType.cityUnlock        => (AppColors.success.withOpacity(0.12), AppColors.success),
      FeedEventType.countryUnlock     => (AppColors.success.withOpacity(0.18), AppColors.success),
      FeedEventType.milestoneReached  => (const Color(0xFFFFD700).withOpacity(0.15), const Color(0xFFFFD700)),
      FeedEventType.hiddenGemFound    => (const Color(0xFF38BDF8).withOpacity(0.12), const Color(0xFF38BDF8)),
      FeedEventType.firstAmongFriends => (const Color(0xFFFFD700).withOpacity(0.12), const Color(0xFFFFD700)),
      FeedEventType.explorationStreak => (AppColors.warning.withOpacity(0.12), AppColors.warning),
      FeedEventType.dnaEvolution      => (AppColors.primary.withOpacity(0.12), AppColors.primary),
      FeedEventType.continentProgress => (AppColors.success.withOpacity(0.12), AppColors.success),
    };
  }
}

// ---------------------------------------------------------------------------
// Reaction button
// ---------------------------------------------------------------------------

class _ReactionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final int count;

  const _ReactionButton({
    required this.emoji,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 15)),
        SizedBox(width: 5),
        Text(
          '$count',
          style: AppTextStyles.captionMuted.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

