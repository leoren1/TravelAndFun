// TripMainView — the breathtaking entry point of the Trip Planner.
// Design: Interactive world map with country markers, draggable discovery sheet,
// and a pulsing AI auto-suggest button.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/features/trip_planner/data/models/explore_city.dart';
import 'package:explore_index/features/trip_planner/data/models/explore_country.dart';
import 'package:explore_index/features/trip_planner/presentation/providers/explore_providers.dart';
import 'package:explore_index/features/trip_planner/presentation/widgets/tp_cinematic_header.dart';
import 'package:explore_index/features/trip_planner/presentation/widgets/tp_glass_card.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry widget
// ─────────────────────────────────────────────────────────────────────────────

class TripMainView extends ConsumerWidget {
  const TripMainView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(tripMainProvider);

    return Scaffold(
      backgroundColor: context.appColors.background,
      body: asyncState.when(
        loading: () => const _TripMainLoading(),
        error: (e, _) => _TripMainError(
          message: e.toString(),
          onRetry: () => ref.invalidate(tripMainProvider),
        ),
        data: (state) => _TripMainBody(state: state),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main body — needs AnimationController → ConsumerStatefulWidget
// ─────────────────────────────────────────────────────────────────────────────

class _TripMainBody extends StatefulWidget {
  final TripMainState state;
  const _TripMainBody({required this.state});

  @override
  State<_TripMainBody> createState() => _TripMainBodyState();
}

class _TripMainBodyState extends State<_TripMainBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  final DraggableScrollableController _sheetCtrl =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _sheetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trendingCities = widget.state.trendingCities;
    final allCountries = widget.state.allCountries;

    return Stack(
      children: [
        // LAYER 1: Interactive world map with country markers
        Positioned.fill(
          child: _ExploreWorldMap(countries: allCountries),
        ),
        // LAYER 2: Draggable discovery sheet
        DraggableScrollableSheet(
          controller: _sheetCtrl,
          initialChildSize: 0.32,
          minChildSize: 0.32,
          maxChildSize: 0.92,
          snap: true,
          snapSizes: const [0.32, 0.92],
          builder: (context, scrollController) {
            return _DiscoverySheet(
              scrollController: scrollController,
              trendingCities: trendingCities,
              allCountries: allCountries,
            );
          },
        ),

        // LAYER 3: Top header
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  _GlassIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Explore the World',
                      style: AppTextStyles.display.copyWith(
                        fontSize: 22,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _ProfileAvatar(initial: 'E'),
                ],
              ),
            ),
          ),
        ),

        // LAYER 4: Auto Suggest FAB
        Positioned(
          bottom: 108 + MediaQuery.of(context).viewInsets.bottom,
          right: AppSpacing.xl,
          child: _AutoSuggestButton(pulseCtrl: _pulseCtrl),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Interactive world map — OSM tiles with tappable country markers.
// Tap anywhere to enter the nearest country; glowing dots show available ones.
// ─────────────────────────────────────────────────────────────────────────────

class _ExploreWorldMap extends StatelessWidget {
  final List<ExploreCountry> countries;
  const _ExploreWorldMap({required this.countries});

  /// Returns the country whose centroid is closest to [tap].
  ExploreCountry? _nearest(LatLng tap) {
    if (countries.isEmpty) return null;
    ExploreCountry nearest = countries.first;
    double minSq = double.infinity;
    for (final c in countries) {
      final dlat = tap.latitude - c.lat;
      final dlng = tap.longitude - c.lng;
      final sq = dlat * dlat + dlng * dlng;
      if (sq < minSq) {
        minSq = sq;
        nearest = c;
      }
    }
    return nearest;
  }

  @override
  Widget build(BuildContext context) {
    // Build circle layers for available countries (outer glow + inner dot)
    final outerCircles = countries
        .map((c) => CircleMarker(
              point: LatLng(c.lat, c.lng),
              radius: 18,
              color: AppColors.primary.withOpacity(0.12),
              borderColor: AppColors.primary.withOpacity(0.35),
              borderStrokeWidth: 1.5,
              useRadiusInMeter: false,
            ))
        .toList();

    final innerCircles = countries
        .map((c) => CircleMarker(
              point: LatLng(c.lat, c.lng),
              radius: 7,
              color: AppColors.primary.withOpacity(0.85),
              borderColor: Colors.white.withOpacity(0.9),
              borderStrokeWidth: 1.5,
              useRadiusInMeter: false,
            ))
        .toList();

    return FlutterMap(
      options: MapOptions(
        // Centre on meridian, low zoom → full world visible above the sheet
        initialCenter: const LatLng(20, 10),
        initialZoom: 1.5,
        minZoom: 1.2,
        maxZoom: 9.0,
        onTap: (_, latLng) {
          final c = _nearest(latLng);
          if (c != null) context.push('/trip-planner/country/${c.id}');
        },
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom |
              InteractiveFlag.doubleTapZoom |
              InteractiveFlag.drag,
        ),
      ),
      children: [
        // OSM tiles — confirmed working on physical Android device.
        // CachedTileProvider + RepaintBoundary required for Android Impeller:
        // without RepaintBoundary tiles load but remain invisible on Impeller/GLES.
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.exploreindex.explore_index',
          tileProvider: _CachedTileProvider(),
          tileBuilder: (context, tileWidget, tile) =>
              RepaintBoundary(child: tileWidget),
        ),
        // Outer glow circles for available countries
        CircleLayer(circles: outerCircles),
        // Inner solid dots for available countries
        CircleLayer(circles: innerCircles),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CachedNetworkImage tile provider — required for Android/Impeller tile rendering.
// ─────────────────────────────────────────────────────────────────────────────
class _CachedTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedNetworkImageProvider(getTileUrl(coordinates, options));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auto Suggest pulsing button
// ─────────────────────────────────────────────────────────────────────────────

class _AutoSuggestButton extends StatelessWidget {
  final AnimationController pulseCtrl;
  const _AutoSuggestButton({required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    final scaleAnim = Tween<double>(begin: 0.97, end: 1.00).animate(
      CurvedAnimation(parent: pulseCtrl, curve: Curves.easeInOut),
    );

    return AnimatedBuilder(
      animation: scaleAnim,
      builder: (context, child) => Transform.scale(
        scale: scaleAnim.value,
        child: child,
      ),
      child: GestureDetector(
        onTap: () => context.push('/trip-planner/auto-suggest'),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.50),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Auto Suggest',
                style: AppTextStyles.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'AI ✦',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withOpacity(0.80),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Draggable discovery sheet
// ─────────────────────────────────────────────────────────────────────────────

class _DiscoverySheet extends StatelessWidget {
  final ScrollController scrollController;
  final List<ExploreCity> trendingCities;
  final List<ExploreCountry> allCountries;

  const _DiscoverySheet({
    required this.scrollController,
    required this.trendingCities,
    required this.allCountries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusHero),
        ),
        border: Border(
          top: BorderSide(
            color: context.appColors.divider,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          // Drag handle
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
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                // Trending Now
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.pageHorizontal,
                      right: AppSpacing.pageHorizontal,
                      top: AppSpacing.md,
                    ),
                    child: _SectionHeader(
                      title: '✈️ Trending Now',
                      subtitle: 'Most explored this month',
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 172,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageHorizontal,
                      ),
                      itemCount: trendingCities.length,
                      itemBuilder: (context, index) {
                        return _TrendingCityCard(
                          city: trendingCities[index],
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),

                // Choose Your Destination
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageHorizontal,
                    ),
                    child: _SectionHeader(
                      title: '🌍 Choose Your Destination',
                      subtitle:
                          '${allCountries.length} countries, endless stories',
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pageHorizontal,
                  ),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: allCountries.length,
                    itemBuilder: (context, index) {
                      return _CountryGridCard(
                        country: allCountries[index],
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),

                // Curated Journeys
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageHorizontal,
                    ),
                    child: _SectionHeader(
                      title: '✨ Curated Journeys',
                      subtitle: 'Expertly crafted itineraries',
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageHorizontal,
                    ),
                    child: Column(
                      children: _journeys
                          .map((j) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md),
                                child: _JourneySuggestionCard(journey: j),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),

                // Friends Exploring
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageHorizontal,
                    ),
                    child: _SectionHeader(
                      title: '👥 Friends Exploring',
                      subtitle: 'See what they discovered',
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageHorizontal,
                    ),
                    child: Column(
                      children: _friends
                          .map((f) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md),
                                child: _FriendActivityTile(friend: f),
                              ))
                          .toList(),
                    ),
                  ),
                ),

                const SliverPadding(
                  padding: EdgeInsets.only(bottom: 120),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trending city card
// ─────────────────────────────────────────────────────────────────────────────

class _TrendingCityCard extends StatelessWidget {
  final ExploreCity city;
  const _TrendingCityCard({required this.city});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/trip-planner/city/${city.id}'),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          boxShadow: [
            BoxShadow(
              color: city.gradientStart.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Gradient background
            TpCinematicHeader(
              gradientStart: city.gradientStart,
              gradientEnd: city.gradientEnd,
              height: 172,
            ),

            // Trending badge
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.90),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '🔥 Trending',
                  style: AppTextStyles.overline.copyWith(color: Colors.white),
                ),
              ),
            ),

            // City info bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      city.countryName,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withOpacity(0.70),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.warning, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          city.travelScore.toStringAsFixed(0),
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
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
// Country grid card (larger format in 2-column grid)
// ─────────────────────────────────────────────────────────────────────────────

class _CountryGridCard extends StatelessWidget {
  final ExploreCountry country;
  const _CountryGridCard({required this.country});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/trip-planner/country/${country.id}'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          gradient: LinearGradient(
            colors: [country.gradientStart, country.gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: country.gradientStart.withOpacity(0.28),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Vignette
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusCard),
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.55),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    country.flagEmoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                  const Spacer(),
                  Text(
                    country.name,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    country.tagline,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withOpacity(0.75),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _SmallChip(
                        '${country.cityCount} cities',
                        AppColors.primary.withOpacity(0.80),
                      ),
                      const SizedBox(width: 6),
                      _SmallChip(
                        '${country.totalPlaces} places',
                        Colors.white.withOpacity(0.15),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Journey suggestion card
// ─────────────────────────────────────────────────────────────────────────────

class _JourneyData {
  final String title;
  final String emoji;
  final String description;
  final String duration;
  final String places;
  final List<Color> gradient;

  const _JourneyData({
    required this.title,
    required this.emoji,
    required this.description,
    required this.duration,
    required this.places,
    required this.gradient,
  });
}

const _journeys = [
  _JourneyData(
    title: 'Paris in 3 Days',
    emoji: '🗼',
    description: 'Eiffel Tower, Louvre, Montmartre & hidden bistros',
    duration: '3 days',
    places: '12 places',
    gradient: [Color(0xFF1565C0), Color(0xFF42A5F5)],
  ),
  _JourneyData(
    title: 'Ancient Rome Walk',
    emoji: '🏛️',
    description: 'Colosseum to Vatican in one epic city journey',
    duration: '5 days',
    places: '18 places',
    gradient: [Color(0xFF6D4C41), Color(0xFFFF8A65)],
  ),
  _JourneyData(
    title: 'Kyoto Temples Trail',
    emoji: '⛩️',
    description: 'Golden Pavilion, Fushimi Inari & bamboo groves',
    duration: '4 days',
    places: '15 places',
    gradient: [Color(0xFF558B2F), Color(0xFFAED581)],
  ),
];

class _JourneySuggestionCard extends StatelessWidget {
  final _JourneyData journey;
  const _JourneySuggestionCard({required this.journey});

  @override
  Widget build(BuildContext context) {
    return TpGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: Row(
        children: [
          // Emoji icon with gradient container
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: journey.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                journey.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  journey.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  journey.description,
                  style: AppTextStyles.caption.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _SmallChip(journey.duration, AppColors.primary.withOpacity(0.25)),
                    SizedBox(width: 6),
                    _SmallChip(journey.places, context.appColors.surfaceElevated),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Friend activity tile
// ─────────────────────────────────────────────────────────────────────────────

class _FriendData {
  final String name;
  final String action;
  final String timeAgo;
  final String placeEmoji;
  final Color avatarColor;

  const _FriendData({
    required this.name,
    required this.action,
    required this.timeAgo,
    required this.placeEmoji,
    required this.avatarColor,
  });
}

const _friends = [
  _FriendData(
    name: 'Yuki T.',
    action: 'just explored Fushimi Inari Taisha',
    timeAgo: '3 hours ago',
    placeEmoji: '⛩️',
    avatarColor: Color(0xFF558B2F),
  ),
  _FriendData(
    name: 'Marco B.',
    action: 'added Colosseum to schedule',
    timeAgo: 'Yesterday',
    placeEmoji: '🏛️',
    avatarColor: Color(0xFF6D4C41),
  ),
  _FriendData(
    name: 'Sophie L.',
    action: 'discovered Le Marais hidden gem',
    timeAgo: '2 days ago',
    placeEmoji: '💎',
    avatarColor: Color(0xFF1565C0),
  ),
];

class _FriendActivityTile extends StatelessWidget {
  final _FriendData friend;
  const _FriendActivityTile({required this.friend});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: friend.avatarColor,
            child: Text(
              friend.name[0],
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.appColors.textPrimary,
                  ),
                ),
                Text(
                  friend.action,
                  style: AppTextStyles.caption.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
                Text(
                  friend.timeAgo,
                  style: AppTextStyles.captionMuted,
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Text(
              friend.placeEmoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header widget
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.titleSmall),
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
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SmallChip extends StatelessWidget {
  final String label;
  final Color bg;
  const _SmallChip(this.label, this.bg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.overline.copyWith(color: Colors.white),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TpGlassCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      onTap: onTap,
      child: Icon(icon, color: context.appColors.textPrimary, size: 18),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String initial;
  const _ProfileAvatar({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading state
// ─────────────────────────────────────────────────────────────────────────────

class _TripMainLoading extends StatelessWidget {
  const _TripMainLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: AppSpacing.lg),
          Text(
            'Loading destinations…',
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────

class _TripMainError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _TripMainError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✈️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Could not load destinations',
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
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(160, 44),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

