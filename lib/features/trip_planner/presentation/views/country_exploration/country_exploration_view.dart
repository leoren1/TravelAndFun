// CountryExplorationView — immersive country portal.
// Design: dramatic full-screen hero, magazine-cover city cards,
// travel facts, mood experiences and an AI auto-suggest CTA.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/features/trip_planner/data/models/explore_city.dart';
import 'package:explore_index/features/trip_planner/data/models/explore_country.dart';
import 'package:explore_index/features/trip_planner/data/models/explore_place.dart';
import 'package:explore_index/features/trip_planner/presentation/providers/explore_providers.dart';
import 'package:explore_index/features/trip_planner/presentation/widgets/tp_cinematic_header.dart';
import 'package:explore_index/features/trip_planner/presentation/widgets/tp_glass_card.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry widget
// ─────────────────────────────────────────────────────────────────────────────

class CountryExplorationView extends ConsumerWidget {
  final String countryId;

  const CountryExplorationView({super.key, required this.countryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(countryExplorationProvider(countryId));

    return Scaffold(
      backgroundColor: context.appColors.background,
      extendBodyBehindAppBar: true,
      body: asyncState.when(
        loading: () => const _CountryLoadingSkeleton(),
        error: (e, _) => _CountryErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(countryExplorationProvider(countryId)),
        ),
        data: (state) => _CountryBody(state: state),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main body
// ─────────────────────────────────────────────────────────────────────────────

class _CountryBody extends StatelessWidget {
  final CountryExplorationState state;
  const _CountryBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final country = state.country;
    final cities = state.cities;
    final highlights = state.highlights;

    return CustomScrollView(
      slivers: [
        // ── Hero SliverAppBar ────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 440,
          pinned: true,
          backgroundColor: context.appColors.background,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: _BackButton(),
          ),
          title: Text(
            country.name,
            style: AppTextStyles.titleSmall.copyWith(
              color: context.appColors.textPrimary,
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: _CountryHeroSection(country: country),
          ),
        ),

        // ── City magazine cards ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _CitiesScrollSection(
            cities: cities,
            countryId: country.id,
          ),
        ),

        // ── Top experiences ──────────────────────────────────────────────────
        if (highlights.isNotEmpty)
          SliverToBoxAdapter(
            child: _TopPlacesSection(highlights: highlights),
          ),

        // ── Country facts ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _CountryFactsSection(country: country),
        ),

        // ── Mood section ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _MoodSection(country: country),
        ),

        // ── Auto suggest CTA ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _AutoSuggestCta(country: country),
        ),

        const SliverPadding(
          padding: EdgeInsets.only(bottom: 40),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Country hero section
// ─────────────────────────────────────────────────────────────────────────────

class _CountryHeroSection extends StatelessWidget {
  final ExploreCountry country;
  const _CountryHeroSection({required this.country});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base cinematic gradient
        TpCinematicHeader(
          gradientStart: country.gradientStart,
          gradientEnd: country.gradientEnd,
          height: 440,
          addOverlay: true,
          overlayOpacity: 0.65,
        ),

        // Decorative planet-like circle — top right
        Positioned(
          top: -50,
          right: -50,
          child: _DecorativeOrb(
            size: 200,
            color: country.gradientEnd.withOpacity(0.30),
          ),
        ),

        // Secondary decorative orb — bottom left
        Positioned(
          bottom: 80,
          left: -30,
          child: _DecorativeOrb(
            size: 140,
            color: country.gradientStart.withOpacity(0.18),
          ),
        ),

        // Content at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Flag + mood tags
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      country.flagEmoji,
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: 6,
                        children: country.moodTags
                            .take(3)
                            .map((m) => _MoodChip(mood: m))
                            .toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Country name
                Text(
                  country.name,
                  style: AppTextStyles.display.copyWith(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                // Tagline
                Text(
                  country.tagline,
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white.withOpacity(0.90),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Stats row
                Row(
                  children: [
                    _StatBadge(
                      value: '${country.cityCount}',
                      label: 'Cities',
                    ),
                    const SizedBox(width: AppSpacing.xxl),
                    _StatBadge(
                      value: '${country.totalPlaces}',
                      label: 'Places',
                    ),
                    const SizedBox(width: AppSpacing.xxl),
                    _StatBadge(
                      value: '${country.popularityScore.toInt()}%',
                      label: 'Popularity',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DecorativeOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _DecorativeOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cities horizontal scroll — magazine covers
// ─────────────────────────────────────────────────────────────────────────────

class _CitiesScrollSection extends StatelessWidget {
  final List<ExploreCity> cities;
  final String countryId;

  const _CitiesScrollSection({
    required this.cities,
    required this.countryId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xxl,
        bottom: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
            ),
            child: _SectionHeader(
              title: '🏙️ Cities to Explore',
              subtitle: cities.isEmpty
                  ? 'Coming soon'
                  : '${cities.length} incredible destinations',
            ),
          ),
          if (cities.isEmpty)
            _CitiesComingSoon()
          else
            SizedBox(
              height: 248,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal,
                ),
                itemCount: cities.length,
                itemBuilder: (context, index) {
                  return _CityMagazineCard(city: cities[index]);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CitiesComingSoon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
        vertical: AppSpacing.md,
      ),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.20),
            width: 1.5,
          ),
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.06),
              AppColors.primaryDeep.withOpacity(0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🗺️', style: TextStyle(fontSize: 36)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Cities Coming Soon',
              style: AppTextStyles.titleSmall.copyWith(
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'We\'re curating the best destinations for this country.',
              style: AppTextStyles.caption.copyWith(
                color: context.appColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CityMagazineCard extends StatelessWidget {
  final ExploreCity city;
  const _CityMagazineCard({required this.city});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/trip-planner/city/${city.id}'),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: city.gradientStart.withOpacity(0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient photo
            TpCinematicHeader(
              gradientStart: city.gradientStart,
              gradientEnd: city.gradientEnd,
              height: 248,
            ),

            // Featured badge
            if (city.isFeatured)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.90),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '⭐ Featured',
                    style: AppTextStyles.overline.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // City info at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      city.name,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      city.region,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withOpacity(0.70),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        _MiniDiscoveryRing(
                            percent: city.discoveryPercent),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '${city.discoveryPercent.toInt()}% explored',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withOpacity(0.80),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      city.currentWeather,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withOpacity(0.80),
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
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini discovery ring (simplified — avoids external dependency)
// ─────────────────────────────────────────────────────────────────────────────

class _MiniDiscoveryRing extends StatelessWidget {
  final double percent;
  const _MiniDiscoveryRing({required this.percent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: (percent / 100).clamp(0.0, 1.0),
            strokeWidth: 3,
            backgroundColor: Colors.white.withOpacity(0.25),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top places preview
// ─────────────────────────────────────────────────────────────────────────────

class _TopPlacesSection extends StatelessWidget {
  final List<ExplorePlace> highlights;
  const _TopPlacesSection({required this.highlights});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.pageHorizontal,
        right: AppSpacing.pageHorizontal,
        bottom: AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: '📍 Top Experiences'),
          SizedBox(
            height: 168,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: highlights.take(4).length,
              itemBuilder: (context, index) {
                final place = highlights[index];
                return _TopPlaceCard(place: place);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TopPlaceCard extends StatelessWidget {
  final ExplorePlace place;
  const _TopPlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          boxShadow: [
            BoxShadow(
              color: place.gradientStart.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            TpCinematicHeader(
              gradientStart: place.gradientStart,
              gradientEnd: place.gradientEnd,
              height: 168,
            ),

            // Tier badge
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: place.tier.color.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${place.tier.emoji} ${place.tier.label}',
                  style: AppTextStyles.overline.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                  ),
                ),
              ),
            ),

            // Name at bottom
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                place.name,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Country facts section
// ─────────────────────────────────────────────────────────────────────────────

class _CountryFactsSection extends StatelessWidget {
  final ExploreCountry country;
  const _CountryFactsSection({required this.country});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
        vertical: AppSpacing.sm,
      ),
      child: TpGlassCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About ${country.name}',
              style: AppTextStyles.titleSmall,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              country.shortDescription,
              style: AppTextStyles.body.copyWith(
                color: context.appColors.textSecondary,
                height: 1.6,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Must-see highlights',
              style: AppTextStyles.caption.copyWith(
                color: context.appColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: country.highlights.map((h) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.appColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSmall),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.40),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '✦ $h',
                    style: AppTextStyles.caption.copyWith(
                      color: context.appColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mood section
// ─────────────────────────────────────────────────────────────────────────────

class _MoodSection extends StatelessWidget {
  final ExploreCountry country;
  const _MoodSection({required this.country});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: '🎭 Travel Moods'),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: country.moodTags.map((mood) {
              return _MoodCard(mood: mood);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  final String mood;
  const _MoodCard({required this.mood});

  static const _moodEmojis = {
    'Romantic': '💕',
    'Historical': '🏛️',
    'Gastronomic': '🍽️',
    'Adventure': '🧗',
    'Cultural': '🎭',
    'Nature': '🌿',
    'Urban': '🏙️',
    'Spiritual': '🕌',
    'Art': '🎨',
    'Relaxing': '🌊',
    'Nightlife': '🌃',
    'Family': '👨‍👩‍👧',
    'Luxury': '💎',
    'Budget': '💰',
    'Architecture': '🏰',
    'Photography': '📸',
    'Shopping': '🛍️',
    'Music': '🎵',
  };

  static const _moodGradients = {
    'Romantic': [Color(0xFFFF4081), Color(0xFFFF6EC7)],
    'Historical': [Color(0xFF795548), Color(0xFFBCAAA4)],
    'Gastronomic': [Color(0xFFFF6F00), Color(0xFFFFCA28)],
    'Adventure': [Color(0xFF1B5E20), Color(0xFF66BB6A)],
    'Cultural': [Color(0xFF4A148C), Color(0xFFAB47BC)],
    'Nature': [Color(0xFF2E7D32), Color(0xFFA5D6A7)],
    'Urban': [Color(0xFF1565C0), Color(0xFF42A5F5)],
    'Spiritual': [Color(0xFF4A148C), Color(0xFF7E57C2)],
    'Art': [Color(0xFF880E4F), Color(0xFFF48FB1)],
    'Relaxing': [Color(0xFF006064), Color(0xFF4DD0E1)],
  };

  @override
  Widget build(BuildContext context) {
    final gradColors = _moodGradients[mood] ??
        [AppColors.primary, AppColors.primaryDeep];
    final emoji = _moodEmojis[mood] ?? '✦';

    return Container(
      width: 100,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: [
          BoxShadow(
            color: gradColors.first.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            mood,
            style: AppTextStyles.overline.copyWith(
              color: Colors.white,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auto Suggest CTA
// ─────────────────────────────────────────────────────────────────────────────

class _AutoSuggestCta extends StatelessWidget {
  final ExploreCountry country;
  const _AutoSuggestCta({required this.country});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
        vertical: AppSpacing.lg,
      ),
      child: TpGlassCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        tintColor: AppColors.primary,
        opacity: 0.10,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✦ Plan your perfect trip',
                        style: AppTextStyles.titleSmall,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Let AI build your ideal ${country.name} itinerary',
                        style: AppTextStyles.caption.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Icon(
                  Icons.auto_awesome,
                  color: AppColors.primary,
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.40),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () =>
                      context.push('/trip-planner/auto-suggest'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusCard),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Auto Suggest Trip',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
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
// Back button
// ─────────────────────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: TpGlassCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        blurSigma: 10,
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: context.appColors.textPrimary,
          size: 18,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mood chip (used in hero)
// ─────────────────────────────────────────────────────────────────────────────

class _MoodChip extends StatelessWidget {
  final String mood;
  const _MoodChip({required this.mood});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      child: Text(
        mood,
        style: AppTextStyles.caption.copyWith(color: Colors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat badge (used in hero)
// ─────────────────────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final String value;
  final String label;
  const _StatBadge({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.titleSmall.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: Colors.white.withOpacity(0.70),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool seeAll;

  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.seeAll = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: AppTextStyles.titleSmall)),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: AppTextStyles.captionMuted),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading skeleton with shimmer effect
// ─────────────────────────────────────────────────────────────────────────────

class _CountryLoadingSkeleton extends StatefulWidget {
  const _CountryLoadingSkeleton();

  @override
  State<_CountryLoadingSkeleton> createState() =>
      _CountryLoadingSkeletonState();
}

class _CountryLoadingSkeletonState extends State<_CountryLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimCtrl;
  late final Animation<Color?> _shimAnim;

  @override
  void initState() {
    super.initState();
    _shimCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _shimAnim = ColorTween(
      begin: context.appColors.surface,
      end: context.appColors.surfaceElevated,
    ).animate(CurvedAnimation(parent: _shimCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimAnim,
      builder: (context, _) {
        final shimColor = _shimAnim.value ?? context.appColors.surface;
        return SingleChildScrollView(
          child: Column(
            children: [
              // Hero skeleton
              _ShimmerBox(
                height: 440,
                width: double.infinity,
                color: shimColor,
                radius: 0,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Section title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(
                        height: 18, width: 160, color: shimColor),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: List.generate(
                        3,
                        (i) => Padding(
                          padding:
                              const EdgeInsets.only(right: AppSpacing.md),
                          child: _ShimmerBox(
                            height: 200,
                            width: 150,
                            color: shimColor,
                            radius: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _ShimmerBox(height: 18, width: 200, color: shimColor),
                    const SizedBox(height: AppSpacing.lg),
                    _ShimmerBox(
                        height: 120, width: double.infinity, color: shimColor),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double height;
  final double width;
  final Color color;
  final double radius;

  const _ShimmerBox({
    required this.height,
    required this.width,
    required this.color,
    this.radius = AppSpacing.radiusCard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────

class _CountryErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _CountryErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌍', style: TextStyle(fontSize: 52)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Could not load country',
              style: AppTextStyles.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.captionMuted,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.appColors.textSecondary,
                    side: BorderSide(color: context.appColors.divider),
                  ),
                  child: const Text('Go Back'),
                ),
                const SizedBox(width: AppSpacing.md),
                FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


