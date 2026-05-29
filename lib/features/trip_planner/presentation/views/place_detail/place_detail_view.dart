// PlaceDetailView — the addiction page.
// "I MUST go here. And here. And here too."
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/features/trip_planner/data/models/explore_category.dart';
import 'package:explore_index/features/trip_planner/data/models/explore_city.dart';
import 'package:explore_index/features/trip_planner/data/models/explore_place.dart';
import 'package:explore_index/features/trip_planner/data/models/itinerary.dart';
import 'package:explore_index/features/trip_planner/data/models/schedule_slot.dart';
import 'package:explore_index/features/trip_planner/presentation/providers/explore_providers.dart';
import 'package:explore_index/features/trip_planner/presentation/widgets/tp_cinematic_header.dart';
import 'package:explore_index/features/trip_planner/presentation/widgets/tp_glass_card.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main view
// ─────────────────────────────────────────────────────────────────────────────

class PlaceDetailView extends ConsumerWidget {
  final String placeId;
  const PlaceDetailView({super.key, required this.placeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(placeDetailProvider(placeId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: context.appColors.background,
      body: detailAsync.when(
        loading: () => const _LoadingState(),
        error: (e, _) => _ErrorState(message: e.toString()),
        data: (state) => Stack(
          children: [
            CustomScrollView(
              physics: BouncingScrollPhysics(),
              slivers: [
                // ── Hero app bar ─────────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 380,
                  pinned: true,
                  backgroundColor: context.appColors.background,
                  surfaceTintColor: context.appColors.surface,
                  elevation: 0,
                  leading: _GlassBackButton(),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Row(
                        children: [
                          TpGlassCard(
                            padding: const EdgeInsets.all(8),
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _sharePlace(context, state.place),
                            child: Icon(Icons.share_rounded, color: context.appColors.textPrimary, size: 20),
                          ),
                          const SizedBox(width: 8),
                          TpGlassCard(
                            padding: const EdgeInsets.all(8),
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${state.place.name} saved to wishlist'),
                                  backgroundColor: context.appColors.surfaceElevated,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Icon(Icons.bookmark_border_rounded, color: context.appColors.textPrimary, size: 20),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: Hero(
                      tag: 'place_explore_${state.place.id}',
                      child: _PlaceHeroContent(
                        place: state.place,
                        category: state.category,
                      ),
                    ),
                  ),
                ),

                // ── Quick info strip ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _QuickInfoStrip(place: state.place),
                ),

                // ── Full description ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _DescriptionSection(place: state.place),
                ),

                // ── Gallery ──────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _GallerySection(place: state.place),
                ),

                // ── Tags ─────────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _TagsSection(place: state.place),
                ),

                // ── Discovery psychology card ────────────────────────────────
                SliverToBoxAdapter(
                  child: _DiscoveryInsightCard(place: state.place),
                ),

                // ── Nearby places ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _NearbyPlacesSection(
                    nearbyPlaces: state.nearbyPlaces,
                    currentPlace: state.place,
                    ref: ref,
                    city: state.city,
                    category: state.category,
                  ),
                ),

                // ── Mock reviews ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _ReviewsSection(place: state.place),
                ),

                // Bottom padding for the floating button
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: 100),
                ),
              ],
            ),

            // ── Floating add button ──────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _FloatingAddButton(
                place: state.place,
                city: state.city,
                category: state.category,
                ref: ref,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sharePlace(BuildContext context, ExplorePlace place) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share "${place.name}" — coming soon'),
        backgroundColor: context.appColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero content
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceHeroContent extends StatelessWidget {
  final ExplorePlace place;
  final ExploreCategory category;

  const _PlaceHeroContent({required this.place, required this.category});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Stack(
      fit: StackFit.expand,
      children: [
        TpCinematicHeader(
          gradientStart: place.gradientStart,
          gradientEnd: place.gradientEnd,
          height: 380,
          addOverlay: true,
          overlayOpacity: 0.60,
        ),

        // Tier badge — top right
        Positioned(
          top: 60 + topPad,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: place.tier.color.withOpacity(0.90),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(place.tier.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  place.tier.label,
                  style: AppTextStyles.caption.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),

        // Discovery points badge — top left
        Positioned(
          top: 60 + topPad,
          left: 16,
          child: TpGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            borderRadius: BorderRadius.circular(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, color: AppColors.warning, size: 14),
                const SizedBox(width: 4),
                Text(
                  '+${place.discoveryPoints} pts',
                  style: AppTextStyles.caption.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),

        // Bottom info overlay
        Positioned(
          bottom: 0,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${category.emoji} ${category.label}',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withOpacity(0.80),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                place.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                place.shortDescription,
                style: AppTextStyles.body.copyWith(
                  color: Colors.white.withOpacity(0.85),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick info strip
// ─────────────────────────────────────────────────────────────────────────────

class _QuickInfoStrip extends StatelessWidget {
  final ExplorePlace place;
  const _QuickInfoStrip({required this.place});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        border: Border(bottom: BorderSide(color: context.appColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _InfoChip(
            icon: Icons.star_rounded,
            value: place.ratingDisplay,
            label: '${place.reviewDisplay} reviews',
            color: AppColors.warning,
          ),
          _VerticalDivider(),
          _InfoChip(
            icon: Icons.schedule_rounded,
            value: place.estimatedDuration,
            label: 'Duration',
            color: AppColors.primary,
          ),
          _VerticalDivider(),
          _InfoChip(
            icon: Icons.wb_sunny_rounded,
            value: place.bestVisitTime,
            label: 'Best time',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppTextStyles.captionMuted,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      color: context.appColors.divider,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full description
// ─────────────────────────────────────────────────────────────────────────────

class _DescriptionSection extends StatelessWidget {
  final ExplorePlace place;
  const _DescriptionSection({required this.place});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About this place', style: AppTextStyles.titleSmall),
          const SizedBox(height: 12),
          TpGlassCard(
            padding: EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(16),
            child: Text(
              place.fullDescription,
              style: AppTextStyles.body.copyWith(
                color: context.appColors.textSecondary,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Simulated gallery
// ─────────────────────────────────────────────────────────────────────────────

class _GallerySection extends StatelessWidget {
  final ExplorePlace place;
  const _GallerySection({required this.place});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text('Gallery', style: AppTextStyles.titleSmall),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            itemBuilder: (context, i) {
              final startColor = Color.lerp(
                place.gradientStart,
                Colors.black,
                i * 0.10,
              )!;
              final endColor = Color.lerp(
                place.gradientEnd,
                Colors.white,
                i * 0.05,
              )!;
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [startColor, endColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.image_outlined,
                    color: Colors.white.withOpacity(0.4),
                    size: 28,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tags
// ─────────────────────────────────────────────────────────────────────────────

class _TagsSection extends StatelessWidget {
  final ExplorePlace place;
  const _TagsSection({required this.place});

  @override
  Widget build(BuildContext context) {
    if (place.tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tags', style: AppTextStyles.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: place.tags.map((tag) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.appColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.appColors.divider),
                ),
                child: Text(
                  '# $tag',
                  style: AppTextStyles.caption.copyWith(color: context.appColors.textSecondary),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Discovery insight card
// ─────────────────────────────────────────────────────────────────────────────

class _DiscoveryInsightCard extends StatelessWidget {
  final ExplorePlace place;
  const _DiscoveryInsightCard({required this.place});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TpGlassCard(
        tintColor: AppColors.primary,
        opacity: 0.10,
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('🔍 Discovery Insight', style: AppTextStyles.titleSmall),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withOpacity(0.50)),
                  ),
                  child: Text(
                    '${place.discoveryPoints} pts',
                    style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'People who visited ${place.name} also explored ${place.nearbyPlaceIds.length} more places nearby. Don\'t miss what\'s waiting around the corner.',
              style: AppTextStyles.body.copyWith(color: context.appColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'City discovery impact',
                    style: AppTextStyles.captionMuted,
                  ),
                ),
                Text(
                  '+${place.discoveryPoints} pts',
                  style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (place.discoveryPoints / 200.0).clamp(0.0, 1.0),
                backgroundColor: context.appColors.divider,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nearby places — the discovery addiction section
// ─────────────────────────────────────────────────────────────────────────────

class _NearbyPlacesSection extends StatelessWidget {
  final List<ExplorePlace> nearbyPlaces;
  final ExplorePlace currentPlace;
  final WidgetRef ref;
  final ExploreCity city;
  final ExploreCategory category;

  const _NearbyPlacesSection({
    required this.nearbyPlaces,
    required this.currentPlace,
    required this.ref,
    required this.city,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    if (nearbyPlaces.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📍 Nearby Places', style: AppTextStyles.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        'Since you\'re here, also explore...',
                        style: AppTextStyles.captionMuted,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      context.push('/trip-planner/city/${city.id}'),
                  child: Text(
                    'View all →',
                    style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: nearbyPlaces.length,
              itemBuilder: (context, i) {
                final nearby = nearbyPlaces[i];
                return GestureDetector(
                  onTap: () => context.push('/trip-planner/place/${nearby.id}'),
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background gradient
                        TpCinematicHeader(
                          gradientStart: nearby.gradientStart,
                          gradientEnd: nearby.gradientEnd,
                          height: 200,
                          addOverlay: true,
                          overlayOpacity: 0.65,
                        ),

                        // Tier badge top-left
                        Positioned(
                          top: 8,
                          left: 8,
                          child: _NearbyTierBadge(tier: nearby.tier),
                        ),

                        // Add prompt top-right
                        Positioned(
                          top: 8,
                          right: 8,
                          child: TpGlassCard(
                            padding: const EdgeInsets.all(4),
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _showAddSheet(context, nearby),
                            child: const Icon(
                              Icons.add_circle_outline_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),

                        // Name at bottom
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.80),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  nearby.name,
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  nearby.estimatedDuration,
                                  style: AppTextStyles.captionMuted.copyWith(
                                    color: Colors.white.withOpacity(0.60),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context, ExplorePlace place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleAddSheet(
        place: place,
        city: city,
        category: category,
        onConfirm: (date, time) => _addToSchedule(ref, place, date, time),
      ),
    );
  }

  void _addToSchedule(
    WidgetRef ref,
    ExplorePlace place,
    DateTime date,
    TimeOfDay time,
  ) {
    final scheduleNotifier = ref.read(scheduleProvider.notifier);
    final scheduleState = ref.read(scheduleProvider);

    if (scheduleState.activeItinerary == null) {
      final newItinerary = Itinerary(
        id: const Uuid().v4(),
        title: '${city.name} Trip',
        countryId: city.countryId,
        countryName: city.countryName,
        countryFlag: city.flagEmoji,
        cityIds: [city.id],
        startDate: date,
        endDate: date.add(const Duration(days: 6)),
        slots: const [],
        isAutoGenerated: false,
      );
      scheduleNotifier.createItinerary(newItinerary);
    }

    final endTotalMins = time.hour * 60 + time.minute + 120;
    final slot = ScheduleSlot(
      id: const Uuid().v4(),
      placeId: place.id,
      placeName: place.name,
      cityId: place.cityId,
      cityName: city.name,
      countryName: city.countryName,
      date: date,
      startTime: time,
      endTime: TimeOfDay(
        hour: (endTotalMins ~/ 60).clamp(0, 23),
        minute: endTotalMins % 60,
      ),
      categoryId: category.id,
      categoryEmoji: category.emoji,
      gradientStartHex: place.gradientStartHex,
      gradientEndHex: place.gradientEndHex,
      notes: '',
    );
    scheduleNotifier.addSlot(slot);
  }
}

class _NearbyTierBadge extends StatelessWidget {
  final DiscoveryTier tier;
  const _NearbyTierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tier.color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        tier.emoji,
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reviews section
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewsSection extends StatelessWidget {
  final ExplorePlace place;
  const _ReviewsSection({required this.place});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Reviews', style: AppTextStyles.titleSmall),
              ),
              Row(
                children: [
                  ...List.generate(
                    5,
                    (i) => Icon(
                      i < place.rating.round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: AppColors.warning,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    place.ratingDisplay,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ReviewCard(
            text:
                'Amazing experience! The ${place.name} exceeded all expectations. Absolutely must-visit.',
            name: 'Sarah M.',
            timeAgo: '2 days ago',
            rating: 5,
          ),
          const SizedBox(height: 8),
          _ReviewCard(
            text:
                'Hidden treasure in the heart of the city. Plan at least ${place.estimatedDuration}.',
            name: 'James K.',
            timeAgo: '1 week ago',
            rating: 4,
          ),
          const SizedBox(height: 8),
          _ReviewCard(
            text:
                'Best visited during ${place.bestVisitTime}. The atmosphere is incomparable.',
            name: 'Yuki T.',
            timeAgo: '2 weeks ago',
            rating: 5,
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String text;
  final String name;
  final String timeAgo;
  final int rating;

  const _ReviewCard({
    required this.text,
    required this.name,
    required this.timeAgo,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    // Derive a stable colour from the name
    final hue = (name.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();

    return TpGlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: HSLColor.fromAHSL(1, hue, 0.55, 0.45).toColor(),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(
                          rating,
                          (_) => const Icon(
                            Icons.star_rounded,
                            color: AppColors.warning,
                            size: 11,
                          ),
                        ),
                        ...List.generate(
                          5 - rating,
                          (_) => Icon(
                            Icons.star_outline_rounded,
                            color: context.appColors.textMuted,
                            size: 11,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(timeAgo, style: AppTextStyles.captionMuted),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            text,
            style: AppTextStyles.body.copyWith(color: context.appColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating add button
// ─────────────────────────────────────────────────────────────────────────────

class _FloatingAddButton extends StatelessWidget {
  final ExplorePlace place;
  final ExploreCity city;
  final ExploreCategory category;
  final WidgetRef ref;

  const _FloatingAddButton({
    required this.place,
    required this.city,
    required this.category,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPad),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        border: Border(top: BorderSide(color: context.appColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Add to your journey', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  'Requires date & time selection',
                  style: AppTextStyles.captionMuted,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _showSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.40),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_circle_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Add to Schedule',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleAddSheet(
        place: place,
        city: city,
        category: category,
        onConfirm: (date, time) => _addToSchedule(ref, date, time),
      ),
    );
  }

  void _addToSchedule(WidgetRef ref, DateTime date, TimeOfDay time) {
    final scheduleNotifier = ref.read(scheduleProvider.notifier);
    final scheduleState = ref.read(scheduleProvider);

    if (scheduleState.activeItinerary == null) {
      final newItinerary = Itinerary(
        id: const Uuid().v4(),
        title: '${city.name} Trip',
        countryId: city.countryId,
        countryName: city.countryName,
        countryFlag: city.flagEmoji,
        cityIds: [city.id],
        startDate: date,
        endDate: date.add(const Duration(days: 6)),
        slots: const [],
        isAutoGenerated: false,
      );
      scheduleNotifier.createItinerary(newItinerary);
    }

    final endTotalMins = time.hour * 60 + time.minute + 120;
    final slot = ScheduleSlot(
      id: const Uuid().v4(),
      placeId: place.id,
      placeName: place.name,
      cityId: place.cityId,
      cityName: city.name,
      countryName: city.countryName,
      date: date,
      startTime: time,
      endTime: TimeOfDay(
        hour: (endTotalMins ~/ 60).clamp(0, 23),
        minute: endTotalMins % 60,
      ),
      categoryId: category.id,
      categoryEmoji: category.emoji,
      gradientStartHex: place.gradientStartHex,
      gradientEndHex: place.gradientEndHex,
      notes: '',
    );
    scheduleNotifier.addSlot(slot);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass back button
// ─────────────────────────────────────────────────────────────────────────────

class _GlassBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TpGlassCard(
        padding: const EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.pop(),
        child: Icon(Icons.arrow_back_ios_new_rounded, color: context.appColors.textPrimary, size: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading and error states
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(AppColors.primary),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Oops! Could not load place.',
              style: AppTextStyles.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.captionMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: Text(
                  'Go back',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared schedule add sheet (StatefulWidget)
// ─────────────────────────────────────────────────────────────────────────────

class _ScheduleAddSheet extends StatefulWidget {
  final ExplorePlace place;
  final ExploreCity city;
  final ExploreCategory category;
  final void Function(DateTime date, TimeOfDay time) onConfirm;

  const _ScheduleAddSheet({
    required this.place,
    required this.city,
    required this.category,
    required this.onConfirm,
  });

  @override
  State<_ScheduleAddSheet> createState() => _ScheduleAddSheetState();
}

class _ScheduleAddSheetState extends State<_ScheduleAddSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            surface: context.appColors.surfaceElevated,
            onSurface: context.appColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            surface: context.appColors.surfaceElevated,
            onSurface: context.appColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final canConfirm = _selectedDate != null && _selectedTime != null;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: context.appColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.appColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Place info header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.place.gradientStart,
                      widget.place.gradientEnd,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    widget.category.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.place.name, style: AppTextStyles.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      widget.place.estimatedDuration,
                      style: AppTextStyles.captionMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Date picker row
          const Text('Select visit date', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          TpGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            borderRadius: BorderRadius.circular(14),
            onTap: _pickDate,
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                        : 'Tap to choose date',
                    style: AppTextStyles.body.copyWith(
                      color: _selectedDate != null
                          ? context.appColors.textPrimary
                          : context.appColors.textMuted,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: context.appColors.textMuted, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Time picker row
          const Text('Start time', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          TpGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            borderRadius: BorderRadius.circular(14),
            onTap: _pickTime,
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedTime != null
                        ? _formatTime(_selectedTime!)
                        : 'Tap to choose time',
                    style: AppTextStyles.body.copyWith(
                      color: _selectedTime != null
                          ? context.appColors.textPrimary
                          : context.appColors.textMuted,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: context.appColors.textMuted, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: canConfirm
                  ? () {
                      widget.onConfirm(_selectedDate!, _selectedTime!);
                      context.pop();
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: canConfirm
                      ? LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDeep],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: canConfirm ? null : context.appColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: canConfirm
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_rounded,
                      color: canConfirm ? Colors.white : context.appColors.textMuted,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Add to Schedule',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: canConfirm ? Colors.white : context.appColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


