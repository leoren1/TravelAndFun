// lib/presentation/views/trip_planner/trip_planner_view.dart
//
// Full-screen map-based trip planner:
//   1. World map with country polygons + city pins
//   2. Tap a city → DraggableScrollableSheet slides up
//      • city header + current discovery %
//      • place list grouped by category, toggle per place
//      • live projected discovery preview
//      • date picker + Save Plan button

import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/core/map/country_borders.dart';
import 'package:explore_index/core/map/tile_cache_manager.dart';
import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/travel_mode.dart';
import 'package:explore_index/presentation/viewmodels/trip_planner_viewmodel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

// ---------------------------------------------------------------------------
// Root view
// ---------------------------------------------------------------------------

class TripPlannerView extends ConsumerWidget {
  const TripPlannerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tripPlannerProvider);

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        titleSpacing: AppSpacing.lg,
        title: Text('Plan a Trip', style: AppTextStyles.titleSmall),
        leading: IconButton(
          icon: Icon(Icons.close, color: context.appColors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) =>
            Center(child: Text(e.toString(), style: AppTextStyles.body)),
        data: (state) => _PlannerBody(state: state),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body — map + sheet
// ---------------------------------------------------------------------------

class _PlannerBody extends ConsumerStatefulWidget {
  final TripPlannerState state;
  const _PlannerBody({required this.state});

  @override
  ConsumerState<_PlannerBody> createState() => _PlannerBodyState();
}

class _PlannerBodyState extends ConsumerState<_PlannerBody> {
  final DraggableScrollableController _sheetCtrl =
      DraggableScrollableController();

  void _openSheet() {
    if (_sheetCtrl.isAttached) {
      _sheetCtrl.animateTo(0.55,
          duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
    }
  }

  void _closeSheet() {
    if (_sheetCtrl.isAttached) {
      _sheetCtrl.animateTo(0,
          duration: const Duration(milliseconds: 280), curve: Curves.easeIn);
    }
    ref.read(tripPlannerProvider.notifier).clearCity();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripPlannerProvider).valueOrNull ?? widget.state;
    final citySelected = state.selectedCity != null;

    return Stack(
      children: [
        // ── Full-screen map ───────────────────────────────────────────────
        _PlannerMap(
          state: state,
          onCityTap: (city) {
            ref.read(tripPlannerProvider.notifier).selectCity(city);
            _openSheet();
          },
        ),

        // ── Instruction overlay (no city selected) ───────────────────────
        if (!citySelected)
          Positioned(
            bottom: 24,
            left: AppSpacing.pageHorizontal,
            right: AppSpacing.pageHorizontal,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: context.appColors.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: Border.all(color: context.appColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_outlined,
                      color: AppColors.primary, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Tap any city pin to start planning your trip',
                      style: AppTextStyles.caption
                          .copyWith(color: context.appColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── City planning sheet ───────────────────────────────────────────
        if (citySelected)
          DraggableScrollableSheet(
            controller: _sheetCtrl,
            initialChildSize: 0.55,
            minChildSize: 0.12,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: const [0.12, 0.55, 0.92],
            builder: (context, scrollController) {
              return _CityPlanSheet(
                state: state,
                scrollController: scrollController,
                onClose: _closeSheet,
              );
            },
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Map
// ---------------------------------------------------------------------------

class _PlannerMap extends ConsumerStatefulWidget {
  final TripPlannerState state;
  final ValueChanged<City> onCityTap;

  const _PlannerMap({required this.state, required this.onCityTap});

  @override
  ConsumerState<_PlannerMap> createState() => _PlannerMapState();
}

class _PlannerMapState extends ConsumerState<_PlannerMap> {
  List<Polygon<String>> _polygons = [];
  double _zoom = 2.8;

  @override
  void initState() {
    super.initState();
    _loadPolygons();
  }

  Future<void> _loadPolygons() async {
    final borders = await CountryBordersService.load();
    final polys = borders.map((cp) {
      final outer = cp.rings.isNotEmpty ? cp.rings[0] : <LatLng>[];
      final holes = cp.rings.length > 1 ? cp.rings.sublist(1) : null;
      return Polygon<String>(
        points: outer,
        holePointsList: holes,
        color: const Color(0x1A7B5BFF),
        borderColor: const Color(0xFF444444),
        borderStrokeWidth: 0.6,
        hitValue: cp.iso,
      );
    }).toList();
    if (mounted) setState(() => _polygons = polys);
  }

  List<Marker> _buildMarkers() {
    final state = widget.state;
    final selectedId = state.selectedCity?.id;
    final markers = <Marker>[];

    for (final city in state.cities) {
      final isSelected = city.id == selectedId;
      markers.add(Marker(
        point: LatLng(city.latitude, city.longitude),
        width: 48,
        height: 48,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onCityTap(city),
          child: _PlannerCityPin(
            tier: city.tier,
            isSelected: isSelected,
            showLabel: _zoom >= 5.5,
            label: city.name,
          ),
        ),
      ));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(38.0, 20.0),
        initialZoom: 2.8,
        minZoom: 1.5,
        maxZoom: 14,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0F1B2D)
            : const Color(0xFFD4EAF8),
        onMapEvent: (e) {
          final z = e.camera.zoom;
          if ((z >= 5.5) != (_zoom >= 5.5)) {
            setState(() => _zoom = z);
          } else {
            _zoom = z;
          }
        },
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
        MarkerLayer(markers: _buildMarkers()),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// City pin — colour-coded by tier
// ---------------------------------------------------------------------------

class _PlannerCityPin extends StatelessWidget {
  final CityTier tier;
  final bool isSelected;
  final bool showLabel;
  final String label;

  const _PlannerCityPin({
    required this.tier,
    required this.isSelected,
    required this.showLabel,
    required this.label,
  });

  Color get _tierColor => switch (tier) {
        CityTier.bronze => const Color(0xFFCD7F32),
        CityTier.silver => const Color(0xFFC0C0C0),
        CityTier.gold => const Color(0xFFFFD700),
      };

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : _tierColor;
    final size = isSelected ? 16.0 : 10.0;
    final ringSize = isSelected ? 44.0 : 30.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: ringSize,
          height: ringSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: isSelected ? 0.25 : 0.1),
            border: Border.all(
                color: color.withValues(alpha: isSelected ? 1 : 0.5),
                width: isSelected ? 2 : 1.2),
          ),
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)]
                    : null,
              ),
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 8,
                color: color,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// City plan sheet
// ---------------------------------------------------------------------------

class _CityPlanSheet extends ConsumerStatefulWidget {
  final TripPlannerState state;
  final ScrollController scrollController;
  final VoidCallback onClose;

  const _CityPlanSheet({
    required this.state,
    required this.scrollController,
    required this.onClose,
  });

  @override
  ConsumerState<_CityPlanSheet> createState() => _CityPlanSheetState();
}

class _CityPlanSheetState extends ConsumerState<_CityPlanSheet> {
  DateTime? _plannedDate;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripPlannerProvider).valueOrNull ?? widget.state;
    final city = state.selectedCity;
    if (city == null) return const SizedBox.shrink();

    final country = state.selectedCountry;
    final places = state.cityModePlaces;
    final byCategory = _groupByCategory(places);

    // Projected discovery bar
    final current = state.currentDiscovery;
    final projected = state.projectedDiscovery;
    final gain = (projected - current).clamp(0.0, 100.0);

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusHero)),
      ),
      child: Column(
        children: [
          // ── Drag handle ───────────────────────────────────────────────
          const _DragHandle(),

          // ── Scrollable content ────────────────────────────────────────
          Expanded(
            child: CustomScrollView(
              controller: widget.scrollController,
              slivers: [
                // City header
                SliverToBoxAdapter(
                  child: _CityHeader(
                    city: city,
                    country: country,
                    currentDiscovery: current,
                    onClose: widget.onClose,
                    mode: state.mode,
                  ),
                ),

                // Discovery preview
                SliverToBoxAdapter(
                  child: _DiscoveryPreview(
                    current: current,
                    projected: projected,
                    gain: gain,
                    selectedCount: state.selectedPlaceIds.length,
                  ),
                ),

                // Place groups
                ...byCategory.entries.map((entry) => SliverToBoxAdapter(
                      child: _CategoryGroup(
                        category: entry.key,
                        places: entry.value,
                        selectedIds: state.selectedPlaceIds,
                        onToggle: (id) =>
                            ref.read(tripPlannerProvider.notifier).togglePlace(id),
                      ),
                    )),

                // Date + save
                SliverToBoxAdapter(
                  child: _SaveSection(
                    plannedDate: _plannedDate,
                    canSave: state.selectedPlaceIds.isNotEmpty,
                    onDatePick: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 2)),
                        builder: (ctx, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: ColorScheme.dark(
                              primary: AppColors.primary,
                              surface: context.appColors.surfaceElevated,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setState(() => _plannedDate = picked);
                      }
                    },
                    onSave: () async {
                      final date = _plannedDate ??
                          DateTime.now().add(const Duration(days: 7));
                      await ref
                          .read(tripPlannerProvider.notifier)
                          .savePlan(date);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Trip plan saved! 🗺️'),
                            backgroundColor: AppColors.success,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        widget.onClose();
                      }
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<Place>> _groupByCategory(List<Place> places) {
    final map = <String, List<Place>>{};
    for (final p in places) {
      final cat = _categoryLabel(p);
      map.putIfAbsent(cat, () => []).add(p);
    }
    return map;
  }

  String _categoryLabel(Place p) {
    if (p.tags.any((t) => t.name == 'historicalPlace' || t.name == 'mustVisit')) {
      return '🏛️ Historical';
    }
    if (p.tags.any((t) => t.name == 'restaurant' || t.name == 'streetFood')) {
      return '🍽️ Food & Dining';
    }
    if (p.tags.any((t) => t.name == 'nature' || t.name == 'viewpoint')) {
      return '🌿 Nature & Views';
    }
    if (p.tags.any((t) => t.name == 'museum' || t.name == 'gallery')) {
      return '🎨 Museums & Art';
    }
    if (p.tags.any((t) => t.name == 'nightlife' || t.name == 'bar')) {
      return '🌙 Nightlife';
    }
    if (p.tags.any((t) => t.name == 'market' || t.name == 'shopping')) {
      return '🛍️ Shopping';
    }
    if (p.tags.any((t) => t.name == 'hidden' || t.name == 'local')) {
      return '🧭 Local Secrets';
    }
    return '📍 Points of Interest';
  }
}

// ---------------------------------------------------------------------------
// Drag handle
// ---------------------------------------------------------------------------

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: context.appColors.divider,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// City header
// ---------------------------------------------------------------------------

class _CityHeader extends StatelessWidget {
  final City city;
  final dynamic country;
  final double currentDiscovery;
  final VoidCallback onClose;
  final TravelMode mode;

  const _CityHeader({
    required this.city,
    required this.country,
    required this.currentDiscovery,
    required this.onClose,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final flag = country != null ? _flagEmoji(country.countryCode as String) : '🌍';
    final pct = currentDiscovery.clamp(0.0, 100.0);
    final modeColor = mode.color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(city.name, style: AppTextStyles.titleSmall),
                if (country != null)
                  Text(country.name as String,
                      style: AppTextStyles.captionMuted),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: modeColor.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusChip),
                      ),
                      child: Text(
                        '${mode.emoji} ${pct.toStringAsFixed(0)}% explored',
                        style: AppTextStyles.caption
                            .copyWith(color: modeColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close,
                color: context.appColors.textSecondary, size: 20),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }

  static String _flagEmoji(String code) {
    if (code.length != 2) return '🌍';
    const base = 0x1F1E6 - 0x41;
    final chars = code.toUpperCase().codeUnits;
    return String.fromCharCodes([base + chars[0], base + chars[1]]);
  }
}

// ---------------------------------------------------------------------------
// Discovery preview bar
// ---------------------------------------------------------------------------

class _DiscoveryPreview extends StatelessWidget {
  final double current;
  final double projected;
  final double gain;
  final int selectedCount;

  const _DiscoveryPreview({
    required this.current,
    required this.projected,
    required this.gain,
    required this.selectedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.explore_outlined,
                  color: AppColors.primary, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text('Discovery Preview', style: AppTextStyles.bodyMedium),
              const Spacer(),
              if (selectedCount > 0)
                Text(
                  '+${gain.toStringAsFixed(0)}% if you visit',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.success),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Stack(
            children: [
              // Background
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: context.appColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Current discovery
              FractionallySizedBox(
                widthFactor: (current / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Projected gain
              if (gain > 0)
                FractionallySizedBox(
                  widthFactor: (projected / 100).clamp(0.0, 1.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: gain / projected.clamp(1.0, 100.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.6),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              _LegendDot(color: AppColors.primary, label: 'Current ${current.toStringAsFixed(0)}%'),
              const SizedBox(width: AppSpacing.md),
              if (gain > 0)
                _LegendDot(
                  color: AppColors.success,
                  label: 'After plan ${projected.toStringAsFixed(0)}%',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption.copyWith(color: context.appColors.textMuted)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Category group
// ---------------------------------------------------------------------------

class _CategoryGroup extends StatefulWidget {
  final String category;
  final List<Place> places;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  const _CategoryGroup({
    required this.category,
    required this.places,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  State<_CategoryGroup> createState() => _CategoryGroupState();
}

class _CategoryGroupState extends State<_CategoryGroup> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg)
          .copyWith(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Text(widget.category,
                      style: AppTextStyles.bodyMedium),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusChip),
                    ),
                    child: Text('${widget.places.length}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.primary)),
                  ),
                  Spacer(),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: context.appColors.textMuted,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // Place list
          if (_expanded)
            ...widget.places.map((p) => _PlaceTile(
                  place: p,
                  isSelected: widget.selectedIds.contains(p.id),
                  onToggle: () => widget.onToggle(p.id),
                )),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Place tile
// ---------------------------------------------------------------------------

class _PlaceTile extends StatelessWidget {
  final Place place;
  final bool isSelected;
  final VoidCallback onToggle;

  const _PlaceTile({
    required this.place,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final tierColor = switch (place.tier) {
      PlaceTier.bronze => const Color(0xFFCD7F32),
      PlaceTier.silver => const Color(0xFFC0C0C0),
      PlaceTier.gold => const Color(0xFFFFD700),
    };

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : context.appColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.appColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Tier indicator
            Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                color: tierColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name,
                      style: AppTextStyles.body.copyWith(
                        color: isSelected
                            ? context.appColors.textPrimary
                            : context.appColors.textSecondary,
                      )),
                  if (place.description.isNotEmpty)
                    Text(
                      place.description,
                      style: AppTextStyles.captionMuted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : context.appColors.textMuted,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check,
                      color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Save section
// ---------------------------------------------------------------------------

class _SaveSection extends StatelessWidget {
  final DateTime? plannedDate;
  final bool canSave;
  final VoidCallback onDatePick;
  final VoidCallback onSave;

  const _SaveSection({
    required this.plannedDate,
    required this.canSave,
    required this.onDatePick,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = plannedDate != null
        ? '${plannedDate!.day} ${_monthName(plannedDate!.month)} ${plannedDate!.year}'
        : 'Set travel date';

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg,
          AppSpacing.lg, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(color: context.appColors.divider),
          const SizedBox(height: AppSpacing.md),
          // Date picker button
          OutlinedButton.icon(
            onPressed: onDatePick,
            icon: Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(dateLabel),
            style: OutlinedButton.styleFrom(
              foregroundColor: plannedDate != null
                  ? AppColors.primary
                  : context.appColors.textSecondary,
              side: BorderSide(
                color: plannedDate != null
                    ? AppColors.primary
                    : context.appColors.divider,
              ),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Save button
          FilledButton.icon(
            onPressed: canSave ? onSave : null,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: Text(
                canSave ? 'Save Trip Plan' : 'Select places first'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
          ),
          if (!canSave) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tap places above to add them to your trip',
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.captionMuted.copyWith(fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  static String _monthName(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}


