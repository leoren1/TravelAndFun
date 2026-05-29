// lib/presentation/views/country_detail/country_detail_view.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/core/router/app_routes.dart';
import 'package:explore_index/data/providers.dart';
import 'package:explore_index/presentation/viewmodels/country_detail_viewmodel.dart';
import 'package:explore_index/presentation/views/country_detail/country_brands_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

class CountryDetailView extends ConsumerWidget {
  final String countryId;
  const CountryDetailView({super.key, required this.countryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(countryDetailViewModelProvider(countryId));

    return Scaffold(
      backgroundColor: context.appColors.background,
      body: asyncState.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Scaffold(
          appBar: AppBar(
            backgroundColor: context.appColors.background,
            elevation: 0,
            leading: _BackButton(),
          ),
          backgroundColor: context.appColors.background,
          body: Center(child: Text(err.toString(), style: AppTextStyles.body)),
        ),
        data: (state) => SafeArea(
          top: false,
          bottom: true,
          child: CustomScrollView(
            slivers: [
            // ── Hero image with overlaid back button ──────────────────────
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: context.appColors.background,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: _BackButton(),
              flexibleSpace: FlexibleSpaceBar(
                background: CachedNetworkImage(
                  imageUrl: state.country.heroImage,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: context.appColors.surfaceElevated),
                  errorWidget: (_, __, ___) => Container(
                    color: context.appColors.surfaceElevated,
                    alignment: Alignment.center,
                    child: Icon(Icons.image_not_supported_outlined,
                        color: context.appColors.textMuted, size: 48),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal,
                  vertical: AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Country name + discovery ──────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(state.country.name, style: AppTextStyles.display),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                state.country.countryCode,
                                style: AppTextStyles.captionMuted,
                              ),
                            ],
                          ),
                        ),
                        _CircularDiscovery(
                          percent: state.countryDiscovery,
                          size: 72,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // ── 2x2 Stat grid ─────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _StatGridCell(
                            value: '${state.cities.where((c) => c.discoveryPercent > 0).length}',
                            label: 'Cities Explored',
                            icon: Icons.location_city_outlined,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _StatGridCell(
                            value: '${state.totalActivities}',
                            label: 'Total Activities',
                            icon: Icons.star_border,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _StatGridCell(
                            value: '${state.verifiedPhotos}',
                            label: 'Verified Photos',
                            icon: Icons.photo_camera_outlined,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _StatGridCell(
                            value: state.averageRating.toStringAsFixed(1),
                            label: 'Avg. Rating',
                            icon: Icons.star_half,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Brands button ─────────────────────────────────────
                    _BrandsButton(
                      countryId: state.country.id,
                      countryName: state.country.name,
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),

                    // ── Cities list ───────────────────────────────────────
                    Text('Cities', style: AppTextStyles.titleSmall),
                    const SizedBox(height: AppSpacing.lg),
                    ...state.cities.map((cs) => _CityRow(summary: cs)),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: context.appColors.background.withOpacity(0.75),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back, color: context.appColors.textPrimary, size: 20),
        ),
      ),
    );
  }
}

class _CircularDiscovery extends StatelessWidget {
  final double percent;
  final double size;
  const _CircularDiscovery({required this.percent, required this.size});

  @override
  Widget build(BuildContext context) {
    final pct = percent.clamp(0.0, 100.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: pct / 100,
              strokeWidth: 6,
              backgroundColor: context.appColors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '${pct.toStringAsFixed(0)}%',
            style: AppTextStyles.caption.copyWith(
              fontSize: 13,
              color: context.appColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGridCell extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatGridCell({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
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
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTextStyles.titleSmall),
          Text(label, style: AppTextStyles.captionMuted),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Brands button — opens country brands bottom sheet
// ---------------------------------------------------------------------------

class _BrandsButton extends ConsumerWidget {
  final String countryId;
  final String countryName;

  const _BrandsButton({
    required this.countryId,
    required this.countryName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo    = ref.read(brandRepositoryProvider);
    final brands  = repo.getBrandsByCountry(countryId);
    final count   = brands.length;

    // Don't render the button if there are no brands for this country.
    if (count == 0) return const SizedBox.shrink();

    // Pick a couple of unique industry emojis for visual flavour.
    final emojis = brands.map((b) => b.industryEmoji).toSet().take(4).join('  ');

    return GestureDetector(
      onTap: () => showCountryBrandsSheet(
        context,
        ref,
        countryId: countryId,
        countryName: countryName,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: context.appColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.storefront_outlined,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Markalar', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 2),
                  Text(
                    '$count marka  ·  $emojis',
                    style: AppTextStyles.captionMuted,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: context.appColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CityRow extends StatelessWidget {
  final CitySummary summary;
  const _CityRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final pct = summary.discoveryPercent.clamp(0.0, 100.0);
    final progressColor = pct >= 50 ? AppColors.success : pct >= 25 ? AppColors.warning : AppColors.danger;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.cityDashboardPath(summary.city.id)),
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
                imageUrl: summary.city.heroImage,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 56,
                  height: 56,
                  color: context.appColors.surfaceElevated,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: context.appColors.surfaceElevated,
                  child: Icon(Icons.image_not_supported_outlined,
                      color: context.appColors.textMuted, size: 24),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(summary.city.name, style: AppTextStyles.bodyMedium),
                  SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 4,
                      backgroundColor: context.appColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '${pct.toStringAsFixed(0)}%',
              style: AppTextStyles.bodyMedium.copyWith(color: progressColor),
            ),
            SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right, color: context.appColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}


