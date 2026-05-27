// lib/presentation/views/dashboard/dashboard_view.dart

import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/core/router/app_routes.dart';
import 'package:explore_index/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(dashboardViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: AppSpacing.lg,
        title: asyncState.whenOrNull(
          data: (state) => Text(
            state.greeting,
            style: AppTextStyles.titleSmall,
          ),
        ) ??
            const Text('Explore Index', style: AppTextStyles.titleSmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
            onPressed: () {},
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
        data: (state) => RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceElevated,
          onRefresh: () => ref.read(dashboardViewModelProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
              vertical: AppSpacing.lg,
            ),
            children: [
              // ── World Discovery Score Card ──────────────────────────────
              _WorldDiscoveryCard(state: state),
              const SizedBox(height: AppSpacing.sectionGap),

              // ── Next City Worth Revisiting ──────────────────────────────
              if (state.nextCityToRevisit != null) ...[
                _NextCityCard(state: state),
                const SizedBox(height: AppSpacing.sectionGap),
              ],

              // ── Recent Discoveries ──────────────────────────────────────
              if (state.recentDiscoveries.isNotEmpty) ...[
                Text('Recent Discoveries', style: AppTextStyles.titleSmall),
                const SizedBox(height: AppSpacing.lg),
                ...state.recentDiscoveries.map(
                  (d) => _RecentDiscoveryTile(discovery: d),
                ),
              ],
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// World Discovery Score Card
// ---------------------------------------------------------------------------

class _WorldDiscoveryCard extends StatelessWidget {
  final DashboardState state;
  const _WorldDiscoveryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final pct = state.worldDiscovery.clamp(0.0, 100.0);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text('World Discovery', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: pct / 100,
                    strokeWidth: 10,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: AppTextStyles.display,
                    ),
                    Text('explored', style: AppTextStyles.captionMuted),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatChip(
                value: '${state.countriesVisited}',
                label: 'Countries',
                icon: Icons.flag_outlined,
              ),
              _StatChip(
                value: '${state.citiesVisited}',
                label: 'Cities',
                icon: Icons.location_city_outlined,
              ),
              _StatChip(
                value: '${state.placesVerified}',
                label: 'Places',
                icon: Icons.place_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatChip({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTextStyles.titleSmall),
        Text(label, style: AppTextStyles.captionMuted),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Next City Worth Revisiting Card
// ---------------------------------------------------------------------------

class _NextCityCard extends ConsumerWidget {
  final DashboardState state;
  const _NextCityCard({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = state.nextCityToRevisit!;
    final pct = state.nextCityDiscovery.clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                ),
                child: Text(
                  'NEXT VISIT',
                  style: AppTextStyles.overline.copyWith(color: AppColors.primary),
                ),
              ),
              const Spacer(),
              Text(
                '${pct.toStringAsFixed(0)}% discovered',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(city.name, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 6,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (state.nextCityRemaining.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Still to explore:', style: AppTextStyles.captionMuted),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: state.nextCityRemaining
                  .map(
                    (cat) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                      ),
                      child: Text(cat, style: AppTextStyles.captionMuted),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
              ),
              onPressed: () => context.push(AppRoutes.cityDashboardPath(city.id)),
              child: const Text('Continue Discovery →', style: AppTextStyles.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent Discovery Tile
// ---------------------------------------------------------------------------

class _RecentDiscoveryTile extends StatelessWidget {
  final RecentDiscovery discovery;
  const _RecentDiscoveryTile({required this.discovery});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(discovery.cityName, style: AppTextStyles.bodyMedium),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
            ),
            child: Text(
              '+${discovery.boost.toStringAsFixed(1)}%',
              style: AppTextStyles.caption.copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}
