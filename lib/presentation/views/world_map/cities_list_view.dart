// lib/presentation/views/world_map/cities_list_view.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/core/router/app_routes.dart';
import 'package:explore_index/presentation/viewmodels/world_map_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

/// Cities tab — shows all cities derived from worldMapViewModelProvider,
/// each tapping to CityDashboard.
class CitiesListView extends ConsumerWidget {
  const CitiesListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(worldMapViewModelProvider);

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        titleSpacing: AppSpacing.lg,
        title: Text('Cities', style: AppTextStyles.titleSmall),
        actions: [
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
        error: (err, _) => Center(
          child: Text(err.toString(), style: AppTextStyles.body),
        ),
        data: (state) {
          // Flatten all cities from all country summaries, preserving order.
          final allCities = state.countries
              .expand((summary) => summary.country.cityIds.map(
                    (cityId) => _CityEntry(
                      cityId: cityId,
                      countryName: summary.country.name,
                      countryCode: summary.country.countryCode,
                      // heroImage is not available in Country, so we pass
                      // the country hero as fallback; real city images come
                      // from CityRepository but we only have WorldMapState here.
                      heroImage: summary.country.heroImage,
                    ),
                  ))
              .toList();

          if (allCities.isEmpty) {
            return Center(
              child: Text('No cities found.', style: AppTextStyles.captionMuted),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
              vertical: AppSpacing.lg,
            ),
            itemCount: allCities.length,
            itemBuilder: (context, index) =>
                _CityListTile(entry: allCities[index]),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal data holder (avoids needing full City from WorldMapState)
// ---------------------------------------------------------------------------

class _CityEntry {
  final String cityId;
  final String countryName;
  final String countryCode;
  final String heroImage;
  const _CityEntry({
    required this.cityId,
    required this.countryName,
    required this.countryCode,
    required this.heroImage,
  });
}

// ---------------------------------------------------------------------------
// City List Tile
// ---------------------------------------------------------------------------

class _CityListTile extends StatelessWidget {
  final _CityEntry entry;
  const _CityListTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.cityDashboardPath(entry.cityId)),
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
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              child: CachedNetworkImage(
                imageUrl: entry.heroImage,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 52,
                  height: 52,
                  color: context.appColors.surfaceElevated,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 52,
                  height: 52,
                  color: context.appColors.surfaceElevated,
                  alignment: Alignment.center,
                  child: Icon(Icons.location_city_outlined,
                      color: context.appColors.textMuted, size: 24),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.cityId,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text(
                        _flagEmoji(entry.countryCode),
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(entry.countryName, style: AppTextStyles.captionMuted),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.appColors.textMuted, size: 18),
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


