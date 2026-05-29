// lib/presentation/views/world_map/world_map_view.dart

import 'dart:async';

import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/core/map/country_borders.dart';
import 'package:explore_index/core/map/tile_cache_manager.dart';
import 'package:explore_index/core/router/app_routes.dart';
import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/country.dart';
import 'package:explore_index/presentation/viewmodels/world_map_viewmodel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

// ---------------------------------------------------------------------------
// Filter mode
// ---------------------------------------------------------------------------

enum MapFilterMode { countries, cities }

// ---------------------------------------------------------------------------
// Download region
// ---------------------------------------------------------------------------

const _kDownloadSW = LatLng(28.0, -12.0);
const _kDownloadNE = LatLng(58.0, 52.0);
const _kMinZoom = 2;
const _kMaxZoom = 7;

// ---------------------------------------------------------------------------
// Popup data (sealed-class pattern via abstract base)
// ---------------------------------------------------------------------------

abstract class _PopupData {}

class _CountryPopup extends _PopupData {
  final Country country;
  final List<City> visitedCities;
  final Map<String, List<String>> placesByCity; // cityId → [place names]

  _CountryPopup({
    required this.country,
    required this.visitedCities,
    required this.placesByCity,
  });
}

class _CityPopup extends _PopupData {
  final City city;
  final List<String> visitedPlaces;
  final double discoveryPct;

  _CityPopup({required this.city, required this.visitedPlaces, required this.discoveryPct});
}

// ---------------------------------------------------------------------------
// WorldMapView
// ---------------------------------------------------------------------------

class WorldMapView extends ConsumerStatefulWidget {
  const WorldMapView({super.key});

  @override
  ConsumerState<WorldMapView> createState() => _WorldMapViewState();
}

class _WorldMapViewState extends ConsumerState<WorldMapView>
    with TickerProviderStateMixin {
  MapFilterMode _filterMode = MapFilterMode.countries;

  // ---- Popup animation ---------------------------------------------------
  _PopupData? _popupData;
  late final AnimationController _popupCtrl;
  late final Animation<Offset> _popupSlide;

  @override
  void initState() {
    super.initState();
    _popupCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _popupSlide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _popupCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _popupCtrl.dispose();
    super.dispose();
  }

  void _showPopup(_PopupData data) {
    setState(() => _popupData = data);
    _popupCtrl.forward(from: 0);
  }

  void _dismissPopup() {
    _popupCtrl.reverse().then((_) {
      if (mounted) setState(() => _popupData = null);
    });
  }

  // ---- Tap handlers -------------------------------------------------------

  void _handleCountryTap(String iso, WorldMapState state) {
    final summary = state.countries
        .where((s) => s.country.countryCode.toLowerCase() == iso)
        .firstOrNull;
    if (summary == null) return;

    final visitedCities = state.cities
        .where((c) =>
            c.countryId == summary.country.id &&
            state.visitedCityIds.contains(c.id))
        .toList();

    final placesByCity = <String, List<String>>{};
    for (final city in visitedCities) {
      final places = state.cityVisitedPlaces[city.id] ?? [];
      if (places.isNotEmpty) placesByCity[city.id] = places;
    }

    _showPopup(_CountryPopup(
      country: summary.country,
      visitedCities: visitedCities,
      placesByCity: placesByCity,
    ));
  }

  void _handleCityTap(String cityId, WorldMapState state) {
    final city = state.cities.where((c) => c.id == cityId).firstOrNull;
    if (city == null) return;
    final places = state.cityVisitedPlaces[cityId] ?? [];
    final pct = state.cityDiscoveryPcts[cityId] ?? 0.0;
    _showPopup(_CityPopup(city: city, visitedPlaces: places, discoveryPct: pct));
  }

  // ---- Download sheet -----------------------------------------------------

  void _showDownloadSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusCard)),
      ),
      builder: (_) => const _DownloadSheet(),
    );
  }

  // ---- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(worldMapViewModelProvider);

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        titleSpacing: AppSpacing.lg,
        title: const Text('Your Travel Map', style: AppTextStyles.titleSmall),
        actions: [
          if (!kIsWeb)
            IconButton(
              icon: Icon(Icons.download_outlined,
                  color: context.appColors.textSecondary),
              tooltip: 'Download for offline use',
              onPressed: _showDownloadSheet,
            ),
          IconButton(
            icon: Icon(Icons.refresh, color: context.appColors.textSecondary),
            onPressed: () =>
                ref.read(worldMapViewModelProvider.notifier).refresh(),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: asyncState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) =>
            Center(child: Text(err.toString(), style: AppTextStyles.body)),
        data: (state) => Stack(
          children: [
            // ── Main scrollable content ─────────────────────────────────────
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageHorizontal,
                      vertical: AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Map
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusCard),
                          child: SizedBox(
                            height: 280,
                            child: _WorldMap(
                              summaries: state.countries,
                              visitedCityIds: state.visitedCityIds,
                              cities: state.cities,
                              cityVisitedPlaces: state.cityVisitedPlaces,
                              filterMode: _filterMode,
                              onCountryTap: (iso) =>
                                  _handleCountryTap(iso, state),
                              onCityTap: (cityId) =>
                                  _handleCityTap(cityId, state),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Filter chips
                        _FilterRow(
                          selected: _filterMode,
                          onChanged: (m) => setState(() => _filterMode = m),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Stat cards
                        Row(
                          children: [
                            Expanded(
                              child: _MapStatCard(
                                value: '${state.totalCountriesVisited}',
                                label: 'Countries Explored',
                                icon: Icons.flag_outlined,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: _MapStatCard(
                                value:
                                    '${state.worldDiscovery.toStringAsFixed(1)}%',
                                label: 'World Discovery',
                                icon: Icons.public_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sectionGap),
                        const Text('Countries',
                            style: AppTextStyles.titleSmall),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageHorizontal),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _CountryRow(summary: state.countries[index]),
                      childCount: state.countries.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxxl)),
              ],
            ),

            // ── Tap-to-dismiss barrier when popup is visible ────────────────
            if (_popupData != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _dismissPopup,
                  behavior: HitTestBehavior.translucent,
                  child: const SizedBox.expand(),
                ),
              ),

            // ── Sliding popup ───────────────────────────────────────────────
            if (_popupData != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SlideTransition(
                  position: _popupSlide,
                  child: _MapInfoPopup(
                    data: _popupData!,
                    onDismiss: _dismissPopup,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Row
// ---------------------------------------------------------------------------

class _FilterRow extends StatelessWidget {
  final MapFilterMode selected;
  final ValueChanged<MapFilterMode> onChanged;

  const _FilterRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChip(
          icon: Icons.flag_outlined,
          label: 'Countries',
          active: selected == MapFilterMode.countries,
          onTap: () => onChanged(MapFilterMode.countries),
        ),
        const SizedBox(width: AppSpacing.sm),
        _FilterChip(
          icon: Icons.location_city_outlined,
          label: 'Cities',
          active: selected == MapFilterMode.cities,
          onTap: () => onChanged(MapFilterMode.cities),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : context.appColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
          border: Border.all(
            color: active ? AppColors.primary : context.appColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? Colors.white : context.appColors.textSecondary,
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: active ? Colors.white : context.appColors.textSecondary,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Download Sheet
// ---------------------------------------------------------------------------

class _DownloadSheet extends StatefulWidget {
  const _DownloadSheet();

  @override
  State<_DownloadSheet> createState() => _DownloadSheetState();
}

class _DownloadSheetState extends State<_DownloadSheet> {
  _DownloadStatus _status = _DownloadStatus.idle;
  StreamSubscription<DownloadProgress>? _sub;
  DownloadProgress _progress =
      const DownloadProgress(done: 0, total: 0, failed: 0);
  int _cacheBytes = 0;

  final int _totalEstimate = TileCacheManager.estimateTileCount(
    southWest: _kDownloadSW,
    northEast: _kDownloadNE,
    minZoom: _kMinZoom,
    maxZoom: _kMaxZoom,
  );

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    final size = await TileCacheManager.instance.cacheSize();
    if (mounted) setState(() => _cacheBytes = size);
  }

  void _startDownload() {
    setState(() {
      _status = _DownloadStatus.downloading;
      _progress = DownloadProgress(done: 0, total: _totalEstimate, failed: 0);
    });
    _sub = TileCacheManager.instance
        .downloadRegion(
          southWest: _kDownloadSW,
          northEast: _kDownloadNE,
          minZoom: _kMinZoom,
          maxZoom: _kMaxZoom,
        )
        .listen(
          (p) {
            if (mounted) setState(() => _progress = p);
          },
          onDone: () {
            if (mounted) {
              setState(() => _status = _DownloadStatus.done);
              _loadCacheSize();
            }
          },
          onError: (_) {
            if (mounted) setState(() => _status = _DownloadStatus.error);
          },
        );
  }

  void _cancelDownload() {
    TileCacheManager.instance.cancelDownload();
    _sub?.cancel();
    if (mounted) setState(() => _status = _DownloadStatus.idle);
  }

  Future<void> _clearCache() async {
    await TileCacheManager.instance.clearCache();
    await _loadCacheSize();
    if (mounted) setState(() => _status = _DownloadStatus.idle);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String _sizeLabel(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.pageHorizontal,
        right: AppSpacing.pageHorizontal,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.appColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text('Offline Map', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Download tiles for Europe, Turkey & Mediterranean '
            '(zoom 2–7) so the map works without internet.',
            style: AppTextStyles.captionMuted,
          ),
          const SizedBox(height: AppSpacing.lg),
          _InfoRow(
              icon: Icons.grid_4x4_outlined,
              label: 'Tiles to download',
              value: '$_totalEstimate'),
          _InfoRow(
              icon: Icons.storage_outlined,
              label: 'Est. size',
              value: '~${_sizeLabel(_totalEstimate * 28 * 1024)}'),
          if (_cacheBytes > 0)
            _InfoRow(
                icon: Icons.offline_bolt_outlined,
                label: 'Cached',
                value: _sizeLabel(_cacheBytes)),
          const SizedBox(height: AppSpacing.xl),
          if (_status == _DownloadStatus.downloading) ...[
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSmall),
                    child: LinearProgressIndicator(
                      value: _progress.fraction,
                      minHeight: 8,
                      backgroundColor: context.appColors.divider,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${(_progress.fraction * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${_progress.done} / ${_progress.total} tiles'
              '${_progress.failed > 0 ? ' (${_progress.failed} failed)' : ''}',
              style: AppTextStyles.captionMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (_status == _DownloadStatus.done) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppColors.success, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Download complete — map works offline!',
                      style:
                          AppTextStyles.body.copyWith(color: AppColors.success)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (_status == _DownloadStatus.error) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_outlined,
                      color: AppColors.warning, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                      child: Text('Download failed. Check your internet.')),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Row(
            children: [
              if (_status != _DownloadStatus.downloading)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _startDownload,
                    icon: const Icon(Icons.download_outlined),
                    label: Text(_status == _DownloadStatus.done
                        ? 'Re-download'
                        : 'Download'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                    ),
                  ),
                ),
              if (_status == _DownloadStatus.downloading)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _cancelDownload,
                    icon: Icon(Icons.cancel_outlined),
                    label: Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.appColors.textSecondary,
                      side: BorderSide(color: context.appColors.divider),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                    ),
                  ),
                ),
              if (_cacheBytes > 0 &&
                  _status != _DownloadStatus.downloading) ...[
                const SizedBox(width: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: _clearCache,
                  icon: Icon(Icons.delete_outline, size: 18),
                  label: Text('Clear'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.appColors.textSecondary,
                    side: BorderSide(color: context.appColors.divider),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                        horizontal: AppSpacing.lg),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

enum _DownloadStatus { idle, downloading, done, error }

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.appColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTextStyles.captionMuted),
          const Spacer(),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Map Stat Card
// ---------------------------------------------------------------------------

class _MapStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _MapStatCard(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTextStyles.titleSmall),
                Text(label, style: AppTextStyles.captionMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Country Row
// ---------------------------------------------------------------------------

class _CountryRow extends StatelessWidget {
  final CountryDiscoverySummary summary;

  const _CountryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final pct = summary.discoveryPercent.clamp(0.0, 100.0);
    final progressColor = pct >= 70
        ? AppColors.success
        : pct >= 40
            ? AppColors.warning
            : AppColors.primary;

    return GestureDetector(
      onTap: () =>
          context.push(AppRoutes.countryDetailPath(summary.country.id)),
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: context.appColors.divider),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(_flagEmoji(summary.country.countryCode),
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(summary.country.name,
                          style: AppTextStyles.bodyMedium),
                      Text(
                        '${summary.citiesVisited} of '
                        '${summary.country.cityIds.length} cities visited',
                        style: AppTextStyles.captionMuted,
                      ),
                    ],
                  ),
                ),
                Text('${pct.toStringAsFixed(0)}%',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: progressColor)),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusChip),
                  ),
                  child: Text('Explore →',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primary)),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 5,
                backgroundColor: context.appColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _flagEmoji(String code) {
    if (code.length != 2) return '🌍';
    const base = 0x1F1E6 - 0x41;
    final chars = code.toUpperCase().codeUnits;
    return String.fromCharCodes([base + chars[0], base + chars[1]]);
  }
}

// ---------------------------------------------------------------------------
// Interactive World Map — GeoJSON borders + city markers + tap popups
// ---------------------------------------------------------------------------

class _WorldMap extends StatefulWidget {
  final List<CountryDiscoverySummary> summaries;
  final Set<String> visitedCityIds;
  final List<City> cities;
  final Map<String, List<String>> cityVisitedPlaces;
  final MapFilterMode filterMode;
  final ValueChanged<String>? onCountryTap;
  final ValueChanged<String>? onCityTap;

  const _WorldMap({
    required this.summaries,
    required this.visitedCityIds,
    required this.cities,
    required this.cityVisitedPlaces,
    required this.filterMode,
    this.onCountryTap,
    this.onCityTap,
  });

  @override
  State<_WorldMap> createState() => _WorldMapState();
}

class _WorldMapState extends State<_WorldMap> {
  // Two polygon variants: unlabelled (low zoom) and labelled (high zoom).
  List<Polygon<String>> _polygons        = []; // countries mode, no labels
  List<Polygon<String>> _polygonsLabeled = []; // countries mode, with labels
  List<Polygon<String>> _polygonsSubtle  = []; // cities mode, border-only

  // Hit notifier — updated by PolygonLayer before onTap fires.
  final _hitNotifier = ValueNotifier<LayerHitResult<String>?>(null);

  late final MapController _mapController;
  double _currentZoom = 3.2;

  static const _visitedGreen  = Color(0xFF22C55E);
  static const _unvisitedGrey = Color(0xFF6B7280);

  // Label zoom thresholds
  static const _countryLabelZoom = 4.5;
  static const _cityLabelZoom    = 6.5;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadPolygons();
  }

  @override
  void dispose() {
    _hitNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_WorldMap old) {
    super.didUpdateWidget(old);
    if (old.summaries != widget.summaries) _loadPolygons();
  }

  Future<void> _loadPolygons() async {
    final borders = await CountryBordersService.load();

    final visitedIsos = <String>{
      for (final s in widget.summaries)
        if (s.discoveryPercent > 0) s.country.countryCode.toLowerCase(),
    };

    final noLabel = CountryBordersService.buildPolygons(
      countries: borders,
      visitedIsos: visitedIsos,
      showLabels: false,
    );
    final withLabel = CountryBordersService.buildPolygons(
      countries: borders,
      visitedIsos: visitedIsos,
      showLabels: true,
    );

    // Subtle border-only polygons for cities mode (still have hitValues)
    final subtle = borders.map((cp) {
      final outer = cp.rings.isNotEmpty ? cp.rings[0] : <LatLng>[];
      final holes  = cp.rings.length > 1 ? cp.rings.sublist(1) : null;
      return Polygon<String>(
        points: outer,
        holePointsList: holes,
        color: const Color(0x00000000),
        borderColor: const Color(0xFF444444),
        borderStrokeWidth: 0.5,
        hitValue: cp.iso,
      );
    }).toList();

    if (mounted) {
      setState(() {
        _polygons        = noLabel;
        _polygonsLabeled = withLabel;
        _polygonsSubtle  = subtle;
      });
    }
  }

  // ---- City markers -------------------------------------------------------

  List<Marker> _buildCityMarkers() {
    final showLabel = _currentZoom >= _cityLabelZoom;
    final markers   = <Marker>[];

    for (final city in widget.cities) {
      final visited = widget.visitedCityIds.contains(city.id);
      markers.add(Marker(
        point: LatLng(city.latitude, city.longitude),
        width:  showLabel ? 84.0 : 44.0,
        height: showLabel ? 58.0 : 44.0,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onCityTap?.call(city.id),
          child: _CityMarker(
            label: showLabel ? city.name : null,
            color: visited ? _visitedGreen : _unvisitedGrey,
            pulse: visited,
          ),
        ),
      ));
    }
    return markers;
  }

  // ---- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isCountries = widget.filterMode == MapFilterMode.countries;
    final showLabels  = _currentZoom >= _countryLabelZoom;

    final polygons = isCountries
        ? (showLabels ? _polygonsLabeled : _polygons)
        : _polygonsSubtle;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(38.0, 20.0),
        initialZoom: 3.2,
        minZoom: 1.0,
        maxZoom: 14.0,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0F1B2D)
            : const Color(0xFFD4EAF8),
        interactionOptions:
            const InteractionOptions(flags: InteractiveFlag.all),
        onMapEvent: (event) {
          final z = event.camera.zoom;
          // Only rebuild when zoom crosses a label-threshold boundary
          final wasCountryLabel = _currentZoom >= _countryLabelZoom;
          final wasCityLabel    = _currentZoom >= _cityLabelZoom;
          final isCountryLabel  = z >= _countryLabelZoom;
          final isCityLabel     = z >= _cityLabelZoom;
          if (wasCountryLabel != isCountryLabel ||
              wasCityLabel != isCityLabel) {
            setState(() => _currentZoom = z);
          } else {
            _currentZoom = z; // update without rebuild
          }
        },
        onTap: (tapPosition, latLng) {
          final hit = _hitNotifier.value;
          if (hit != null && hit.hitValues.isNotEmpty) {
            widget.onCountryTap?.call(hit.hitValues.first);
          }
        },
      ),
      children: [
        // Base tile layer
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

        // Country / border polygons with hit detection
        if (polygons.isNotEmpty)
          PolygonLayer<String>(
            polygons: polygons,
            hitNotifier: _hitNotifier,
          ),

        // City markers (cities mode only)
        if (!isCountries)
          MarkerLayer(markers: _buildCityMarkers()),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// City Marker — pulsing ring + inner dot + optional name label
// ---------------------------------------------------------------------------

class _CityMarker extends StatefulWidget {
  final Color color;
  final bool pulse;
  final String? label;

  const _CityMarker({required this.color, this.pulse = true, this.label});

  @override
  State<_CityMarker> createState() => _CityMarkerState();
}

class _CityMarkerState extends State<_CityMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2));
    if (widget.pulse) _ctrl.repeat(reverse: true);
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, __) {
        final s = widget.pulse ? _scale.value : 1.0;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.15 * s),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withValues(
                      alpha: widget.pulse ? 0.6 * s : 0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                    boxShadow: widget.pulse
                        ? [
                            BoxShadow(
                              color: widget.color.withValues(alpha: 0.6),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
            if (widget.label != null) ...[
              const SizedBox(height: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  widget.label!,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Map Info Popup — slides in from the top
// ---------------------------------------------------------------------------

class _MapInfoPopup extends StatelessWidget {
  final _PopupData data;
  final VoidCallback onDismiss;

  const _MapInfoPopup({required this.data, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        // Prevent taps inside the popup from propagating to the dismiss barrier
        onTap: () {},
        child: Container(
          margin: EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(color: context.appColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Divider(height: 1, thickness: 1, color: context.appColors.divider),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.38,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
                  child: _buildContent(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Header -------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    final Widget leading;
    final String title;

    if (data is _CountryPopup) {
      final cp = data as _CountryPopup;
      leading = Text(
        _flagEmoji(cp.country.countryCode),
        style: const TextStyle(fontSize: 26),
      );
      title = cp.country.name;
    } else {
      final cp = data as _CityPopup;
      leading = const Icon(Icons.location_city_outlined,
          color: AppColors.primary, size: 26);
      title = cp.city.name;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
      child: Row(
        children: [
          leading,
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(title, style: AppTextStyles.titleSmall)),
          IconButton(
            icon: Icon(Icons.close,
                color: context.appColors.textSecondary, size: 20),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  // ---- Content ------------------------------------------------------------

  Widget _buildContent(BuildContext context) {
    if (data is _CountryPopup) {
      return _buildCountryContent(data as _CountryPopup, context);
    } else {
      return _buildCityContent(data as _CityPopup, context);
    }
  }

  Widget _buildCountryContent(_CountryPopup cp, BuildContext context) {
    if (cp.visitedCities.isEmpty) {
      return const Text('No cities visited yet.',
          style: AppTextStyles.captionMuted);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Visited cities chips
        _sectionHeader(Icons.location_city_outlined, 'Visited Cities', context),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: cp.visitedCities
              .map((city) => _chip(city.name))
              .toList(),
        ),

        // Places per city
        if (cp.placesByCity.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _sectionHeader(Icons.place_outlined, 'Places Visited', context),
          const SizedBox(height: AppSpacing.sm),
          ...cp.visitedCities
              .where((c) => cp.placesByCity.containsKey(c.id))
              .map((city) => _cityPlacesSection(
                    cityName: city.name,
                    places: cp.placesByCity[city.id]!,
                  )),
        ],
      ],
    );
  }

  Widget _buildCityContent(_CityPopup cp, BuildContext context) {
    final pct = cp.discoveryPct.clamp(0.0, 100.0);
    final progressColor = pct >= 70
        ? AppColors.success
        : pct >= 40
            ? AppColors.warning
            : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Discovery progress bar
        Row(
          children: [
            Text(
              '${pct.toStringAsFixed(0)}% discovered',
              style: AppTextStyles.bodyMedium.copyWith(color: progressColor),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 5,
            backgroundColor: context.appColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
        if (cp.visitedPlaces.isEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          const Text('No visited places yet.', style: AppTextStyles.captionMuted),
        ] else ...[
          const SizedBox(height: AppSpacing.md),
          _sectionHeader(Icons.place_outlined, 'Places Visited', context),
          const SizedBox(height: AppSpacing.sm),
          ...cp.visitedPlaces.map(_bulletRow),
        ],
      ],
    );
  }

  // ---- Helpers ------------------------------------------------------------

  static Widget _sectionHeader(IconData icon, String text, BuildContext context) => Row(
        children: [
          Icon(icon, size: 13, color: context.appColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(text, style: AppTextStyles.bodyMedium),
        ],
      );

  static Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
        ),
        child: Text(label,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.primary)),
      );

  static Widget _bulletRow(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ',
                style: TextStyle(color: AppColors.primary, fontSize: 12)),
            Expanded(
                child: Text(text, style: AppTextStyles.caption)),
          ],
        ),
      );

  static Widget _cityPlacesSection(
      {required String cityName, required List<String> places}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cityName,
            style: AppTextStyles.captionMuted
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...places.map(_bulletRow),
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


