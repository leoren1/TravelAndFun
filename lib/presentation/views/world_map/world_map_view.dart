// lib/presentation/views/world_map/world_map_view.dart

import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/core/router/app_routes.dart';
import 'package:explore_index/presentation/viewmodels/world_map_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

class WorldMapView extends ConsumerWidget {
  const WorldMapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(worldMapViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: AppSpacing.lg,
        title: const Text('Your Travel Map', style: AppTextStyles.titleSmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () => ref.read(worldMapViewModelProvider.notifier).refresh(),
          ),
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
        data: (state) => CustomScrollView(
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
                    // Interactive world map showing visited countries and cities
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                      child: SizedBox(
                        height: 260,
                        child: _WorldMap(summaries: state.countries),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
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
                            value: '${state.worldDiscovery.toStringAsFixed(1)}%',
                            label: 'World Discovery',
                            icon: Icons.public_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    Text('Countries', style: AppTextStyles.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _CountryRow(summary: state.countries[index]),
                  childCount: state.countries.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
          ],
        ),
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
  const _MapStatCard({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.divider),
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
      onTap: () => context.push(
        AppRoutes.countryDetailPath(summary.country.id),
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _flagEmoji(summary.country.countryCode),
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(summary.country.name, style: AppTextStyles.bodyMedium),
                    Text(
                      '${summary.citiesVisited} of ${summary.country.cityIds.length} cities visited',
                      style: AppTextStyles.captionMuted,
                    ),
                  ],
                ),
              ),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: AppTextStyles.bodyMedium.copyWith(color: progressColor),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                  ),
                  child: Text(
                    'Explore →',
                    style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                  ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 5,
              backgroundColor: AppColors.divider,
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
// Interactive World Map
// ---------------------------------------------------------------------------

class _WorldMap extends StatelessWidget {
  final List<CountryDiscoverySummary> summaries;
  const _WorldMap({required this.summaries});

  static const _cityCoords = <String, LatLng>{
    'istanbul': LatLng(41.0082, 28.9784),
    'izmir': LatLng(38.4192, 27.1287),
    'antalya': LatLng(36.8841, 30.7056),
    'roma': LatLng(41.9028, 12.4964),
    'paris': LatLng(48.8566, 2.3522),
  };

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    for (final summary in summaries) {
      for (final cityId in summary.country.cityIds) {
        final coord = _cityCoords[cityId];
        if (coord == null) continue;
        final pct = summary.discoveryPercent;
        final color = pct >= 60
            ? const Color(0xFF22C55E)
            : pct >= 30
                ? const Color(0xFFF59E0B)
                : const Color(0xFF7B5BFF);
        markers.add(Marker(
          point: coord,
          width: 36,
          height: 36,
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ));
      }
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(38.0, 20.0),
        initialZoom: 3.2,
        minZoom: 1.0,
        maxZoom: 12.0,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.exploreindex.explore_index',
          maxZoom: 19,
        ),
        MarkerLayer(markers: _buildMarkers()),
      ],
    );
  }
}
