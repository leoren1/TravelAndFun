// lib/presentation/views/city_dashboard/city_dashboard_view.dart

import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/core/router/app_routes.dart';
import 'package:explore_index/data/models/category.dart';
import 'package:explore_index/presentation/viewmodels/city_dashboard_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

class CityDashboardView extends ConsumerWidget {
  final String cityId;
  const CityDashboardView({super.key, required this.cityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(cityDashboardViewModelProvider(cityId));

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.appColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: asyncState.whenOrNull(
          data: (s) => Text(s.city.name, style: AppTextStyles.titleSmall),
        ) ??
            Text('City', style: AppTextStyles.titleSmall),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.appColors.textSecondary),
            onPressed: () =>
                ref.read(cityDashboardViewModelProvider(cityId).notifier).refresh(),
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
        data: (state) => SafeArea(
          top: false,
          bottom: true,
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHorizontal,
              vertical: AppSpacing.lg,
            ),
            children: [
            // ── Large circular progress ───────────────────────────────────
            _CityDiscoveryHero(
              cityName: state.city.name,
              discoveryPercent: state.discoveryPercent,
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // ── Worth visiting again card ─────────────────────────────────
            _WorthVisitingCard(
              cityId: cityId,
              worthVisitingAgain: state.worthVisitingAgain,
              reason: state.worthReason,
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // ── Events shortcut ───────────────────────────────────────────
            _EventsShortcutCard(cityId: cityId),
            const SizedBox(height: AppSpacing.sectionGap),

            // ── Categories ────────────────────────────────────────────────
            Text('Categories', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.lg),
            ...state.categoryProgress.map(
              (cp) => _CategoryProgressTile(
                cityId: cityId,
                progress: cp,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// City Discovery Hero
// ---------------------------------------------------------------------------

class _CityDiscoveryHero extends StatelessWidget {
  final String cityName;
  final double discoveryPercent;
  const _CityDiscoveryHero({
    required this.cityName,
    required this.discoveryPercent,
  });

  @override
  Widget build(BuildContext context) {
    final pct = discoveryPercent.clamp(0.0, 100.0);
    final progressColor = pct >= 50
        ? AppColors.success
        : pct >= 25
            ? AppColors.warning
            : AppColors.danger;

    return Container(
      padding: EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: pct / 100,
                    strokeWidth: 12,
                    backgroundColor: context.appColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
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
                    Text('discovered', style: AppTextStyles.captionMuted),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(cityName, style: AppTextStyles.title),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Worth Visiting Card
// ---------------------------------------------------------------------------

class _WorthVisitingCard extends StatelessWidget {
  final String cityId;
  final bool worthVisitingAgain;
  final String reason;
  const _WorthVisitingCard({
    required this.cityId,
    required this.worthVisitingAgain,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.worthAgainPath(cityId)),
      child: Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Worth visiting again?', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _YesNoChip(value: true, selected: worthVisitingAgain),
              const SizedBox(width: AppSpacing.sm),
              _YesNoChip(value: false, selected: !worthVisitingAgain),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push(AppRoutes.worthAgainPath(cityId)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                  ),
                  child: Text(
                    'Details →',
                    style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(reason, style: AppTextStyles.captionMuted),
          ],
        ],
      ),
      ),
    );
  }
}

class _YesNoChip extends StatelessWidget {
  final bool value;
  final bool selected;
  const _YesNoChip({required this.value, required this.selected});

  @override
  Widget build(BuildContext context) {
    final color = value ? AppColors.success : AppColors.danger;
    final label = value ? 'YES' : 'NO';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.15) : context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
        border: Border.all(
          color: selected ? color : context.appColors.divider,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: selected ? color : context.appColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Events Shortcut Card
// ---------------------------------------------------------------------------

class _EventsShortcutCard extends StatelessWidget {
  final String cityId;
  const _EventsShortcutCard({required this.cityId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.eventsPath(cityId)),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: context.appColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_outlined, color: AppColors.primary, size: 24),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Local Events', style: AppTextStyles.bodyMedium),
                  Text('See what\'s happening in this city', style: AppTextStyles.captionMuted),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.appColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category Progress Tile
// ---------------------------------------------------------------------------

class _CategoryProgressTile extends StatelessWidget {
  final String cityId;
  final CategoryProgress progress;
  const _CategoryProgressTile({required this.cityId, required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = progress.percentage.clamp(0.0, 100.0);
    final progressColor = pct >= 50
        ? AppColors.success
        : pct >= 25
            ? AppColors.warning
            : AppColors.danger;

    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.categoryDetailPath(cityId, progress.type.jsonKey),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: context.appColors.divider),
        ),
        child: Row(
          children: [
            Text(
              progress.type.icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          progress.type.displayName,
                          style: AppTextStyles.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${progress.completed}/${progress.total}',
                        style: AppTextStyles.captionMuted,
                      ),
                    ],
                  ),
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
              style: AppTextStyles.caption.copyWith(color: progressColor),
            ),
            SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right, color: context.appColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }
}


