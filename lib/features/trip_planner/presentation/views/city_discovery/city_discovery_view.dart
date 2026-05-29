// CityDiscoveryView — immersive city exploration page.
// "I WANT to explore THIS city."
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
import 'package:explore_index/features/trip_planner/presentation/widgets/tp_discovery_ring.dart';
import 'package:explore_index/features/trip_planner/presentation/widgets/tp_glass_card.dart';
import 'package:explore_index/features/trip_planner/presentation/widgets/tp_place_card.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main view
// ─────────────────────────────────────────────────────────────────────────────

class CityDiscoveryView extends ConsumerWidget {
  final String cityId;
  const CityDiscoveryView({super.key, required this.cityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoveryAsync = ref.watch(cityDiscoveryProvider(cityId));
    final selectedCategoryId = ref.watch(cityDiscoveryCategoryProvider(cityId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: context.appColors.background,
      // Planning bar lives in bottomNavigationBar so body can be a bare
      // CustomScrollView — exactly like CountryExplorationView (which renders
      // correctly). Stack-wrapping a CustomScrollView caused a black screen on
      // Impeller/OpenGLES; moving it here fixed that.
      bottomNavigationBar: discoveryAsync.maybeWhen(
        data: (state) => _CityPlanningBar(
          city: state.city,
          categories: state.categories,
        ),
        orElse: () => null,
      ),
      body: discoveryAsync.when(
        loading: () => const _LoadingState(),
        error: (e, _) => _ErrorState(message: e.toString()),
        data: (state) {
          // FIX: _CityHeroContent had TpDiscoveryRing (AnimationController +
          // CustomPainter + MaskFilter.blur) inside FlexibleSpaceBar.background.
          // On Impeller/OpenGLES that combination causes a black screen.
          // Solution: use _CityHeroContentNoRing in the hero — static ring instead.
          // TpDiscoveryRing is still used in _DiscoveryBanner (below the fold,
          // outside FlexibleSpaceBar, animate:false — confirmed safe).
          return CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              // ── Hero ──────────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 420,
                pinned: true,
                floating: false,
                backgroundColor: context.appColors.background,
                elevation: 0,
                leading: _GlassBackButton(),
                title: Text(state.city.name, style: AppTextStyles.titleSmall),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: _CityHeroContentNoRing(city: state.city),
                ),
              ),

              // ── Discovery banner ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _DiscoveryBanner(city: state.city),
                ),
              ),

              // ── Category tabs ─────────────────────────────────────────────
              // NOTE: SliverPersistentHeader(pinned: true) combined with a
              // pinned SliverAppBar causes Impeller/OpenGLES to clear the
              // FlexibleSpaceBar.background, making the hero completely black.
              // Using SliverToBoxAdapter instead avoids two pinned compositing
              // layers in the same CustomScrollView.
              SliverToBoxAdapter(
                child: _CategoryTabsRow(
                  categories: state.categories,
                  selectedCategoryId: selectedCategoryId,
                  placesByCategory: state.placesByCategory,
                  onSelect: (id) => ref
                      .read(cityDiscoveryCategoryProvider(cityId).notifier)
                      .state = id,
                ),
              ),

              // ── Places grid / list ────────────────────────────────────────
              _PlacesSection(
                state: state,
                selectedCategoryId: selectedCategoryId,
                onAddToSchedule: (place) =>
                    _showAddToScheduleBottomSheet(context, ref, place, state),
              ),

              // ── Nearby cities ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _NearbyCitiesSection(
                  currentCityId: cityId,
                  countryName: state.city.countryName,
                  countryId: state.city.countryId,
                  ref: ref,
                ),
              ),

              // ── Bottom padding ────────────────────────────────────────────
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }

  void _showAddToScheduleBottomSheet(
    BuildContext context,
    WidgetRef ref,
    ExplorePlace place,
    CityDiscoveryState state,
  ) {
    final category = state.categories.firstWhere(
      (c) => c.id == place.categoryId,
      orElse: () => const ExploreCategory(
        id: 'unknown',
        label: 'Other',
        emoji: '📍',
        accentHex: '7B5BFF',
        description: '',
      ),
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleAddSheet(
        place: place,
        city: state.city,
        category: category,
        onConfirm: (date, time) => _addToSchedule(ref, place, state, category, date, time),
      ),
    );
  }

  void _addToSchedule(
    WidgetRef ref,
    ExplorePlace place,
    CityDiscoveryState state,
    ExploreCategory category,
    DateTime date,
    TimeOfDay time,
  ) {
    final scheduleNotifier = ref.read(scheduleProvider.notifier);
    final scheduleState = ref.read(scheduleProvider);

    // Auto-create an itinerary if none exists
    if (scheduleState.activeItinerary == null) {
      final newItinerary = Itinerary(
        id: const Uuid().v4(),
        title: '${state.city.name} Trip',
        countryId: state.city.countryId,
        countryName: state.city.countryName,
        countryFlag: state.city.flagEmoji,
        cityIds: [state.city.id],
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
      cityName: state.city.name,
      countryName: state.city.countryName,
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
// Provider for selected category (city-scoped)
// ─────────────────────────────────────────────────────────────────────────────

final cityDiscoveryCategoryProvider =
    StateProvider.autoDispose.family<String?, String>((ref, cityId) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Hero content
// ─────────────────────────────────────────────────────────────────────────────

class _CityHeroContent extends StatelessWidget {
  final ExploreCity city;
  const _CityHeroContent({required this.city});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Stack(
      fit: StackFit.expand,
      children: [
        TpCinematicHeader(
          gradientStart: city.gradientStart,
          gradientEnd: city.gradientEnd,
          height: 420,
          addOverlay: true,
          overlayOpacity: 0.70,
        ),

        // Weather + travel score badges (plain containers — no BackdropFilter in hero)
        Positioned(
          top: 60 + topPad,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.40),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Text(
                  city.currentWeather,
                  style: AppTextStyles.caption.copyWith(color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.40),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${city.travelScore.toInt()} Travel Score',
                      style: AppTextStyles.caption.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Main city info
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Flag + region
              Row(
                children: [
                  Text(city.flagEmoji, style: const TextStyle(fontSize: 24)),
                  SizedBox(width: 8),
                  Text(
                    city.region,
                    style: AppTextStyles.caption.copyWith(color: context.appColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // City name
              Text(
                city.name,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),

              // Tagline
              Text(
                city.tagline,
                style: AppTextStyles.body.copyWith(
                  color: Colors.white.withOpacity(0.85),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // Discovery progress row
              Row(
                children: [
                  TpDiscoveryRing(
                    percent: city.discoveryPercent,
                    size: 44,
                    strokeWidth: 4,
                    animate: true,
                    animationDuration: const Duration(milliseconds: 1500),
                    child: Text(
                      '${city.discoveryPercent.toInt()}%',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${city.discoveredPlaces} of ${city.totalPlaces} places explored',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withOpacity(0.80),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Best season: ${city.bestSeason}',
                          style: AppTextStyles.captionMuted.copyWith(
                            color: Colors.white.withOpacity(0.60),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIAGNOSTIC: Hero content WITHOUT TpDiscoveryRing
// Identical to _CityHeroContent but replaces TpDiscoveryRing with plain Text.
// Purpose: confirm if TpDiscoveryRing (StatefulWidget + AnimationController +
// CustomPainter) inside FlexibleSpaceBar.background is the cause of the black
// screen on Impeller/OpenGLES emulator.
// ─────────────────────────────────────────────────────────────────────────────

class _CityHeroContentNoRing extends StatelessWidget {
  final ExploreCity city;
  const _CityHeroContentNoRing({required this.city});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Stack(
      fit: StackFit.expand,
      children: [
        TpCinematicHeader(
          gradientStart: city.gradientStart,
          gradientEnd: city.gradientEnd,
          height: 420,
          addOverlay: true,
          overlayOpacity: 0.70,
        ),

        // Weather + travel score badges
        Positioned(
          top: 60 + topPad,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.40),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Text(
                  city.currentWeather,
                  style: AppTextStyles.caption.copyWith(color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.40),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${city.travelScore.toInt()} Travel Score',
                      style: AppTextStyles.caption.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Main city info
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(city.flagEmoji, style: const TextStyle(fontSize: 24)),
                  SizedBox(width: 8),
                  Text(
                    city.region,
                    style: AppTextStyles.caption.copyWith(color: context.appColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                city.name,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                city.tagline,
                style: AppTextStyles.body.copyWith(
                  color: Colors.white.withOpacity(0.85),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              // NO TpDiscoveryRing — plain text to isolate the black-screen cause
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      border: Border.all(color: Colors.white.withOpacity(0.30), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '${city.discoveryPercent.toInt()}%',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${city.discoveredPlaces} of ${city.totalPlaces} places explored',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withOpacity(0.80),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Best season: ${city.bestSeason}',
                          style: AppTextStyles.captionMuted.copyWith(
                            color: Colors.white.withOpacity(0.60),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category tabs persistent header delegate
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryTabsDelegate extends SliverPersistentHeaderDelegate {
  final List<ExploreCategory> categories;
  final String? selectedCategoryId;
  final Map<String, List<ExplorePlace>> placesByCategory;
  final void Function(String?) onSelect;

  const _CategoryTabsDelegate({
    required this.categories,
    required this.selectedCategoryId,
    required this.placesByCategory,
    required this.onSelect,
  });

  @override
  double get minExtent => 72;
  @override
  double get maxExtent => 72;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.background.withOpacity(0.97),
        border: Border(
          bottom: BorderSide(color: context.appColors.divider, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _CategoryTab(
              label: 'All',
              isSelected: selectedCategoryId == null,
              onTap: () => onSelect(null),
            ),
            ...categories.map((cat) {
              final count = placesByCategory[cat.id]?.length ?? 0;
              return _CategoryTab(
                label: '${cat.emoji} ${cat.label}',
                isSelected: selectedCategoryId == cat.id,
                onTap: () => onSelect(cat.id),
                count: count,
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_CategoryTabsDelegate old) =>
      old.selectedCategoryId != selectedCategoryId ||
      old.categories != categories;
}

// ─────────────────────────────────────────────────────────────────────────────
// Category tabs as a plain non-sticky row
// (SliverPersistentHeader + pinned SliverAppBar = Impeller compositing bug)
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryTabsRow extends StatelessWidget {
  final List<ExploreCategory> categories;
  final String? selectedCategoryId;
  final Map<String, List<ExplorePlace>> placesByCategory;
  final void Function(String?) onSelect;

  const _CategoryTabsRow({
    required this.categories,
    required this.selectedCategoryId,
    required this.placesByCategory,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: context.appColors.background,  // fully opaque — avoids compositing layer
        border: Border(
          bottom: BorderSide(color: context.appColors.divider, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _CategoryTab(
              label: 'All',
              isSelected: selectedCategoryId == null,
              onTap: () => onSelect(null),
            ),
            ...categories.map((cat) {
              final count = placesByCategory[cat.id]?.length ?? 0;
              return _CategoryTab(
                label: '${cat.emoji} ${cat.label}',
                isSelected: selectedCategoryId == cat.id,
                onTap: () => onSelect(cat.id),
                count: count,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;

  const _CategoryTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary, width: 1),
              )
            : BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.primary : context.appColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.25)
                      : context.appColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.overline.copyWith(
                    color: isSelected ? AppColors.primary : context.appColors.textMuted,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Discovery psychology banner
// ─────────────────────────────────────────────────────────────────────────────

class _DiscoveryBanner extends StatelessWidget {
  final ExploreCity city;
  const _DiscoveryBanner({required this.city});

  @override
  Widget build(BuildContext context) {
    final remaining = city.totalPlaces - city.discoveredPlaces;
    // NOTE: TpGlassCard (BackdropFilter) is intentionally NOT used here.
    // On Impeller/OpenGLES, BackdropFilter in a CustomScrollView sliver renders
    // at the wrong paint coordinates and produces a white area overlapping the
    // hero gradient. Plain Container avoids that compositing path entirely.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔍 $remaining places await discovery',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep exploring to unlock hidden gems',
                  style: AppTextStyles.captionMuted,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          TpDiscoveryRing(
            percent: city.discoveryPercent,
            size: 44,
            strokeWidth: 4,
            animate: false,
            child: Text(
              '${city.discoveryPercent.toInt()}%',
              style: TextStyle(
                fontSize: 9,
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Places section (grid / list based on selected category)
// ─────────────────────────────────────────────────────────────────────────────

class _PlacesSection extends StatelessWidget {
  final CityDiscoveryState state;
  final String? selectedCategoryId;
  final void Function(ExplorePlace) onAddToSchedule;

  const _PlacesSection({
    required this.state,
    required this.selectedCategoryId,
    required this.onAddToSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final places = state.visiblePlaces;

    if (places.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Text('🏙️', style: TextStyle(fontSize: 48)),
              SizedBox(height: 16),
              Text(
                'No places found in this category',
                style: AppTextStyles.bodyMedium.copyWith(color: context.appColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (selectedCategoryId == null) {
      // All-categories 2-column grid
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => TpPlaceCard(
              place: places[index],
              onTap: () => context.push('/trip-planner/place/${places[index].id}'),
              isLarge: true,
              showAddButton: true,
              onAdd: () => onAddToSchedule(places[index]),
            ),
            childCount: places.length,
          ),
        ),
      );
    } else {
      // Single category list
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TpPlaceCard(
                place: places[index],
                onTap: () => context.push('/trip-planner/place/${places[index].id}'),
                isLarge: true,
                showAddButton: true,
                onAdd: () => onAddToSchedule(places[index]),
              ),
            ),
            childCount: places.length,
          ),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nearby cities section
// ─────────────────────────────────────────────────────────────────────────────

class _NearbyCitiesSection extends StatelessWidget {
  final String currentCityId;
  final String countryName;
  final String countryId;
  final WidgetRef ref;

  const _NearbyCitiesSection({
    required this.currentCityId,
    required this.countryName,
    required this.countryId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final countryAsync = ref.watch(countryExplorationProvider(countryId));

    return countryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (countryState) {
        final otherCities = countryState.cities
            .where((c) => c.id != currentCityId)
            .take(5)
            .toList();
        if (otherCities.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader('📍 More in $countryName'),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: otherCities.length,
                  itemBuilder: (context, i) {
                    final city = otherCities[i];
                    return GestureDetector(
                      onTap: () => context.push('/trip-planner/city/${city.id}'),
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [city.gradientStart, city.gradientEnd],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Dark vignette
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.55),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    city.flagEmoji,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    city.name,
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
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
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// City planning bar (floating bottom)
// ─────────────────────────────────────────────────────────────────────────────

class _CityPlanningBar extends StatelessWidget {
  final ExploreCity city;
  final List<ExploreCategory> categories;

  const _CityPlanningBar({required this.city, required this.categories});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPad),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(color: context.appColors.divider, width: 1),
        ),
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
                Text(
                  'Plan your ${city.name} trip',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${categories.length} categories to explore',
                  style: AppTextStyles.captionMuted,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.push('/trip-planner/auto-suggest'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Auto Plan',
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass back button
// ─────────────────────────────────────────────────────────────────────────────

class _GlassBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.20)
                  : Colors.white.withOpacity(0.40),
            ),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.titleSmall);
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
              'Oops! Could not load city.',
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
// Shared schedule add sheet
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

          // Place info
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.place.gradientStart, widget.place.gradientEnd],
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
          Text('Select visit date', style: AppTextStyles.bodyMedium),
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
          Text('Start time', style: AppTextStyles.bodyMedium),
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


