// lib/presentation/views/my_page/my_page_view.dart
//
// Personal showcase page:
//   • Hero header — avatar + archetype + stats
//   • Travel mode discovery bars (Bronze / Silver / Gold)
//   • Mini world map — visited cities highlighted
//   • Discovery DNA radar chart (bar-based)
//   • Hierarchical journey timeline (year → month → trip cards)
//   • Upcoming plans section

import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/core/map/country_borders.dart';
import 'package:explore_index/core/map/tile_cache_manager.dart';
import 'package:explore_index/core/router/app_routes.dart';
import 'package:explore_index/core/theme/theme_provider.dart';
import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/trip_plan.dart';
import 'package:explore_index/presentation/viewmodels/my_page_viewmodel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

class MyPageView extends ConsumerWidget {
  const MyPageView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myPageViewModelProvider);

    return Scaffold(
      backgroundColor: context.appColors.background,
      body: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) =>
            Center(child: Text(e.toString(), style: AppTextStyles.body)),
        data: (state) => _MyPageContent(state: state),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Content scaffold
// ---------------------------------------------------------------------------

class _MyPageContent extends ConsumerWidget {
  final MyPageState state;
  const _MyPageContent({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // ── SliverAppBar with hero header ─────────────────────────────────
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: context.appColors.background,
          elevation: 0,
          actions: [
            // ── Theme toggle ────────────────────────────────────────────────
            Consumer(builder: (ctx, r, _) {
              final isDark = r.watch(themeProvider) == ThemeMode.dark;
              return IconButton(
                tooltip: isDark ? 'Light Mode' : 'Dark Mode',
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: ctx.appColors.textSecondary,
                ),
                onPressed: () => r.read(themeProvider.notifier).toggle(),
              );
            }),
            IconButton(
              icon: Icon(Icons.refresh_outlined,
                  color: context.appColors.textSecondary),
              onPressed: () =>
                  ref.read(myPageViewModelProvider.notifier).refresh(),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _HeroHeader(state: state),
          ),
        ),

        // ── Stats row ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg,
                AppSpacing.lg, 0),
            child: _StatsRow(state: state),
          ),
        ),

        // ── Mode discovery bars ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xxl,
                AppSpacing.lg, 0),
            child: _ModeDiscoveryCard(state: state),
          ),
        ),

        // ── Mini world map ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xxl,
                AppSpacing.lg, 0),
            child: _MapSection(state: state),
          ),
        ),

        // ── Discovery DNA ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xxl,
                AppSpacing.lg, 0),
            child: _DnaSection(state: state),
          ),
        ),

        // ── Journey timeline ──────────────────────────────────────────────
        if (state.journeyTimeline.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                  AppSpacing.xxl, AppSpacing.lg, AppSpacing.md),
              child: Row(
                children: [
                  const _SectionTitle(
                      icon: Icons.route_outlined, label: 'Journey Timeline'),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.journal),
                    child: Text('View journal',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final entry = state.journeyTimeline[i];
                  return _JourneyCard(entry: entry);
                },
                childCount: state.journeyTimeline.length,
              ),
            ),
          ),
        ],

        // ── Upcoming plans ────────────────────────────────────────────────
        if (state.upcomingPlans.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                  AppSpacing.xxl, AppSpacing.lg, AppSpacing.md),
              child: Row(
                children: [
                  const _SectionTitle(
                      icon: Icons.upcoming_outlined,
                      label: 'Upcoming Plans'),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.plans),
                    child: Text('See all',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) =>
                    _UpcomingPlanTile(plan: state.upcomingPlans[i]),
                childCount: state.upcomingPlans.length,
              ),
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hero header
// ---------------------------------------------------------------------------

class _HeroHeader extends StatelessWidget {
  final MyPageState state;
  const _HeroHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final arch = state.archetype;
    final profile = state.profile;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1026)
                : context.appColors.surfaceElevated,
            context.appColors.background,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.xl),
            // Avatar — tap to open profile
            GestureDetector(
              onTap: () => context.push(AppRoutes.profile),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.success],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    arch.emoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Name
            Text(
              profile.name,
              style: AppTextStyles.titleSmall
                  .copyWith(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Archetype title
            Text(
              arch.title,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Tagline
            Text(
              arch.tagline,
              style: AppTextStyles.captionMuted
                  .copyWith(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),

            // Badges row (first 5)
            if (state.unlockedBadges.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: state.unlockedBadges.take(5).map((b) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Tooltip(
                      message: b.name,
                      child: Text(b.icon,
                          style: const TextStyle(fontSize: 22)),
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

// ---------------------------------------------------------------------------
// Stats row
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  final MyPageState state;
  const _StatsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _StatCard(
                value: '${state.totalCountriesVisited}',
                label: 'Countries')),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: _StatCard(
                value: '${state.totalCitiesVisited}', label: 'Cities')),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: _StatCard(
                value: '${state.totalPlacesVerified}', label: 'Places')),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: _StatCard(
                value: state.averageRating.toStringAsFixed(1),
                label: 'Avg ★')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.titleSmall
                  .copyWith(color: AppColors.primary)),
          SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: context.appColors.textMuted),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mode discovery card
// ---------------------------------------------------------------------------

class _ModeDiscoveryCard extends StatelessWidget {
  final MyPageState state;
  const _ModeDiscoveryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final md = state.modeDiscovery;
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.public_outlined,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: AppSpacing.xs),
              const Text('World Discovery by Mode',
                  style: AppTextStyles.bodyMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _ModeBar(
              emoji: '🥉',
              label: 'Bronze — Famous Landmarks',
              value: md.bronze,
              color: const Color(0xFFCD7F32)),
          const SizedBox(height: AppSpacing.sm),
          _ModeBar(
              emoji: '🥈',
              label: 'Silver — Regional Cities',
              value: md.silver,
              color: const Color(0xFFC0C0C0)),
          const SizedBox(height: AppSpacing.sm),
          _ModeBar(
              emoji: '🥇',
              label: 'Gold — Hidden Gems',
              value: md.gold,
              color: const Color(0xFFFFD700)),
        ],
      ),
    );
  }
}

class _ModeBar extends StatelessWidget {
  final String emoji;
  final String label;
  final double value;
  final Color color;
  const _ModeBar(
      {required this.emoji,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = value.clamp(0.0, 100.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(label, style: AppTextStyles.caption)),
            Text('${pct.toStringAsFixed(1)}%',
                style: AppTextStyles.caption.copyWith(color: color)),
          ],
        ),
        SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 6,
            backgroundColor: context.appColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mini world map
// ---------------------------------------------------------------------------

class _MapSection extends StatelessWidget {
  final MyPageState state;
  const _MapSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
            icon: Icons.map_outlined, label: 'Your World Map'),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          child: SizedBox(
            height: 220,
            child: _MiniMap(
              allCities: state.allCities,
              visitedCityIds: state.visitedCityIds,
              cityDiscoveryPcts: state.cityDiscoveryPcts,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniMap extends StatefulWidget {
  final List<City> allCities;
  final Set<String> visitedCityIds;
  final Map<String, double> cityDiscoveryPcts;

  const _MiniMap({
    required this.allCities,
    required this.visitedCityIds,
    required this.cityDiscoveryPcts,
  });

  @override
  State<_MiniMap> createState() => _MiniMapState();
}

class _MiniMapState extends State<_MiniMap> {
  List<Polygon<String>> _polygons = [];

  @override
  void initState() {
    super.initState();
    _loadPolygons();
  }

  Future<void> _loadPolygons() async {
    final borders = await CountryBordersService.load();
    final visitedCountryCodes = <String>{};
    for (final c in widget.allCities) {
      if (widget.visitedCityIds.contains(c.id)) {
        // We can't easily get the country code here without country list,
        // so just colour all polygons subtle
      }
    }

    final polys = borders.map((cp) {
      final outer = cp.rings.isNotEmpty ? cp.rings[0] : <LatLng>[];
      final holes = cp.rings.length > 1 ? cp.rings.sublist(1) : null;
      return Polygon<String>(
        points: outer,
        holePointsList: holes,
        color: const Color(0x1A7B5BFF),
        borderColor: const Color(0xFF333344),
        borderStrokeWidth: 0.5,
        hitValue: cp.iso,
      );
    }).toList();

    if (mounted) setState(() => _polygons = polys);
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(20.0, 10.0),
        initialZoom: 1.8,
        minZoom: 1.5,
        maxZoom: 6,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0F1B2D)
            : const Color(0xFFD4EAF8),
        interactionOptions:
            const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.exploreindex.explore_index',
          maxZoom: 19,
          maxNativeZoom: 19,
          tileProvider:
              kIsWeb ? NetworkTileProvider() : OfflineTileProvider(),
          errorTileCallback: (tile, error, stackTrace) {},
        ),
        if (_polygons.isNotEmpty)
          PolygonLayer<String>(polygons: _polygons),
        MarkerLayer(
          markers: widget.allCities.map((city) {
            final visited = widget.visitedCityIds.contains(city.id);
            final pct = widget.cityDiscoveryPcts[city.id] ?? 0;
            return Marker(
              point: LatLng(city.latitude, city.longitude),
              width: 14,
              height: 14,
              child: Container(
                decoration: BoxDecoration(
                  color: visited
                      ? (pct >= 70
                          ? AppColors.success
                          : AppColors.primary)
                      : context.appColors.textMuted.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: visited
                        ? context.appColors.surface.withValues(alpha: 0.8)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// DNA section
// ---------------------------------------------------------------------------

class _DnaSection extends StatelessWidget {
  final MyPageState state;
  const _DnaSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final arch = state.archetype;

    // Use computed DNA scores from viewmodel (same data source as /dna page).
    final entries = state.dnaScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(arch.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(arch.title, style: AppTextStyles.bodyMedium),
                    Text(
                      arch.tagline,
                      style: AppTextStyles.captionMuted
                          .copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          Divider(color: context.appColors.divider, height: 1),
          const SizedBox(height: AppSpacing.md),
          ...entries.map((e) => _DnaBar(
                label: e.key,
                value: e.value,
                isTop: e.key == arch.topCategory,
              )),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () => context.push(AppRoutes.dna),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('View full DNA analysis',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.primary)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios,
                    size: 10, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DnaBar extends StatelessWidget {
  final String label;
  final double value;
  final bool isTop;
  const _DnaBar(
      {required this.label, required this.value, required this.isTop});

  static const _emojis = {
    'History': '🏛️',
    'Food': '🍽️',
    'Nature': '🌿',
    'Events': '🎭',
    'Nightlife': '🌙',
    'Local Exp': '🧭',
    'Shopping': '🛍️',
    'Museums': '🎨',
  };

  @override
  Widget build(BuildContext context) {
    final pct = value.clamp(0.0, 100.0);
    final color = isTop ? AppColors.primary : context.appColors.textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(_emojis[label] ?? '✨',
              style: const TextStyle(fontSize: 14)),
          SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isTop ? context.appColors.textPrimary : context.appColors.textSecondary,
                fontWeight:
                    isTop ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 6,
                backgroundColor: context.appColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 38,
            child: Text(
              '${pct.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style:
                  AppTextStyles.caption.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Journey card — photo album style
// ---------------------------------------------------------------------------

class _JourneyCard extends StatelessWidget {
  final JourneyEntry entry;
  const _JourneyCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final flag = entry.country != null
        ? _flagEmoji(entry.country!.countryCode)
        : '🌍';
    final pct = entry.discoveryPct.clamp(0.0, 100.0);
    final pctColor = pct >= 70
        ? AppColors.success
        : pct >= 40
            ? AppColors.warning
            : AppColors.primary;

    // Photos from place images (Unsplash URLs)
    final photos = entry.places
        .where((p) => p.image.isNotEmpty)
        .map((p) => p.image)
        .toList();

    return GestureDetector(
      onTap: () => context.push(AppRoutes.cityDashboardPath(entry.city.id)),
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.xl),
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: context.appColors.divider),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo strip ────────────────────────────────────────────
            if (photos.isNotEmpty)
              SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  itemCount: photos.length,
                  itemBuilder: (context, i) {
                    return Container(
                      width: 110,
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                            child: Image.network(
                              photos[i],
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, progress) =>
                                  progress == null
                                      ? child
                                      : Container(
                                          color: context.appColors.surfaceElevated,
                                          child: const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                              errorBuilder: (_, __, ___) => Container(
                                color: context.appColors.surfaceElevated,
                                child: Icon(
                                  Icons.image_outlined,
                                  color: context.appColors.textMuted,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                          // Place name overlay at bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.75),
                                    Colors.transparent,
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(AppSpacing.radiusSmall),
                                  bottomRight: Radius.circular(AppSpacing.radiusSmall),
                                ),
                              ),
                              child: Text(
                                entry.places[i].name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            else
              // Fallback gradient when no photos
              Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.25),
                      AppColors.success.withValues(alpha: 0.15),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(flag, style: const TextStyle(fontSize: 32)),
                ),
              ),

            // ── Info section ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // City + date row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(flag, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.city.name,
                                style: AppTextStyles.bodyMedium),
                            if (entry.country != null)
                              Text(entry.country!.name,
                                  style: AppTextStyles.captionMuted),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatDate(entry.tripDate),
                            style: AppTextStyles.caption
                                .copyWith(color: context.appColors.textMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${pct.toStringAsFixed(0)}% explored',
                            style: AppTextStyles.caption
                                .copyWith(color: pctColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Discovery progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 4,
                      backgroundColor: context.appColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(pctColor),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Stats chips
                  Row(
                    children: [
                      _Chip('${entry.placeCount} places',
                          Icons.place_outlined),
                      const SizedBox(width: AppSpacing.xs),
                      _Chip('${entry.avgRating.toStringAsFixed(1)} ★',
                          Icons.star_outline,
                          color: AppColors.warning),
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

  static String _flagEmoji(String code) {
    if (code.length != 2) return '🌍';
    const base = 0x1F1E6 - 0x41;
    final chars = code.toUpperCase().codeUnits;
    return String.fromCharCodes([base + chars[0], base + chars[1]]);
  }

  static String _formatDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month]} ${d.year}';
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  _Chip(this.label, this.icon, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.appColors.textMuted;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: c),
          const SizedBox(width: 3),
          Text(label,
              style: AppTextStyles.caption.copyWith(color: c)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Upcoming plan tile
// ---------------------------------------------------------------------------

class _UpcomingPlanTile extends StatelessWidget {
  final TripPlan plan;
  const _UpcomingPlanTile({required this.plan});

  @override
  Widget build(BuildContext context) {
    final daysUntil =
        plan.plannedDate.difference(DateTime.now()).inDays;
    final gain = plan.discoveryGain;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.plans),
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: context.appColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$daysUntil',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.primary),
                  ),
                  Text(
                    'days',
                    style:
                        AppTextStyles.caption.copyWith(
                            color: context.appColors.textMuted,
                            fontSize: 9),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.cityName,
                      style: AppTextStyles.bodyMedium),
                  Text(
                    _formatDate(plan.plannedDate),
                    style: AppTextStyles.captionMuted,
                  ),
                ],
              ),
            ),
            if (gain > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusChip),
                ),
                child: Text(
                  '+${gain.toStringAsFixed(0)}%',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.success),
                ),
              ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right,
                color: context.appColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}

// ---------------------------------------------------------------------------
// Section title
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTextStyles.titleSmall),
      ],
    );
  }
}


