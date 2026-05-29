// lib/presentation/views/dashboard/dashboard_view.dart

import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/core/router/app_routes.dart';
import 'package:explore_index/data/models/travel_mode.dart';
import 'package:explore_index/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:explore_index/presentation/views/mode_selector/mode_selector_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';
import 'package:intl/intl.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(dashboardViewModelProvider);

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        titleSpacing: AppSpacing.lg,
        title: asyncState.whenOrNull(
          data: (state) => Text(state.greeting, style: AppTextStyles.titleSmall),
        ) ??
            const Text('Explore Index', style: AppTextStyles.titleSmall),
        actions: [
          const ModeBadge(),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: asyncState.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) =>
            Center(child: Text(err.toString(), style: AppTextStyles.body)),
        data: (state) => RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: context.appColors.surfaceElevated,
          onRefresh: () =>
              ref.read(dashboardViewModelProvider.notifier).refresh(),
          child: CustomScrollView(
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
                      // ── Stats banner ──────────────────────────────────
                      _StatsBanner(state: state),
                      const SizedBox(height: AppSpacing.md),

                      // ── Plan a Trip button ────────────────────────────
                      _PlanATripButton(),
                      const SizedBox(height: AppSpacing.sectionGap),

                      // ── Next Trip card (shown only when a plan exists) ────
                      if (state.nextPlan != null) ...[
                        _UpcomingTripCard(nextPlan: state.nextPlan!),
                        const SizedBox(height: AppSpacing.sectionGap),
                      ],

                      // ── Journey Timeline header ───────────────────────
                      if (state.journeyTimeline.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.route_outlined,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: AppSpacing.xs),
                            Text('My Journey', style: AppTextStyles.titleSmall),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Timeline items ────────────────────────────────────────
              if (state.journeyTimeline.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageHorizontal),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _TimelineItem(
                        segment: state.journeyTimeline[i],
                        isFirst: i == 0,
                        isLast: i == state.journeyTimeline.length - 1,
                      ),
                      childCount: state.journeyTimeline.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxxl)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats banner — circular progress + 3 chips
// ---------------------------------------------------------------------------

class _StatsBanner extends StatelessWidget {
  final DashboardState state;
  const _StatsBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final pct = state.worldDiscovery.clamp(0.0, 100.0);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: pct / 100,
                    strokeWidth: 7,
                    backgroundColor: context.appColors.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: AppTextStyles.titleSmall
                          .copyWith(color: AppColors.primary),
                    ),
                    Text('explored', style: AppTextStyles.captionMuted),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          // Stats column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${state.travelMode.emoji} ${state.travelMode.shortName} Discovery',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                _InlineStatRow(
                  icon: Icons.flag_outlined,
                  label: '${state.countriesVisited} Countries',
                ),
                const SizedBox(height: AppSpacing.xs),
                _InlineStatRow(
                  icon: Icons.location_city_outlined,
                  label: '${state.citiesVisited} Cities',
                ),
                const SizedBox(height: AppSpacing.xs),
                _InlineStatRow(
                  icon: Icons.place_outlined,
                  label: '${state.placesVerified} Places',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineStatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InlineStatRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: context.appColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTextStyles.captionMuted),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Plan a Trip button
// ---------------------------------------------------------------------------

class _PlanATripButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.tripPlanner),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.22),
              AppColors.success.withValues(alpha: 0.14),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_location_alt_outlined,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plan a Trip', style: AppTextStyles.bodyMedium),
                  Text(
                    'Pick a city, choose places & set a date',
                    style: AppTextStyles.captionMuted,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Upcoming Trip Card
// ---------------------------------------------------------------------------

class _UpcomingTripCard extends StatelessWidget {
  final UpcomingPlan nextPlan;
  const _UpcomingTripCard({required this.nextPlan});

  static String _flagEmoji(String code) {
    if (code.length != 2) return '✈️';
    const base = 0x1F1E6 - 0x41;
    final chars = code.toUpperCase().codeUnits;
    return String.fromCharCodes([base + chars[0], base + chars[1]]);
  }

  @override
  Widget build(BuildContext context) {
    final plan = nextPlan.plan;
    final days = nextPlan.daysUntil;
    final flag = _flagEmoji(nextPlan.countryCode);
    final dateStr = DateFormat('d MMM yyyy').format(plan.plannedDate);
    final gain = plan.discoveryGain;

    final daysLabel = days == 0
        ? 'Today!'
        : days == 1
            ? 'Tomorrow'
            : days < 0
                ? '${days.abs()}d overdue'
                : 'In $days days';
    final daysColor = days <= 1
        ? AppColors.success
        : days <= 7
            ? AppColors.warning
            : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.14),
            AppColors.primaryDeep.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.md, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✈️', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        'NEXT TRIP',
                        style: AppTextStyles.overline
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Days-until chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: daysColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                  ),
                  child: Text(
                    daysLabel,
                    style: AppTextStyles.overline.copyWith(color: daysColor),
                  ),
                ),
              ],
            ),
          ),

          // ── City / Country ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(flag, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.cityName, style: AppTextStyles.title),
                      if (nextPlan.countryName.isNotEmpty)
                        Text(nextPlan.countryName,
                            style: AppTextStyles.captionMuted),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Info chips ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: dateStr,
                ),
                _InfoChip(
                  icon: Icons.place_outlined,
                  label: '${plan.placeIds.length} places',
                ),
                if (gain > 0)
                  _InfoChip(
                    icon: Icons.trending_up_rounded,
                    label: '+${gain.toStringAsFixed(0)}% discovery',
                    color: AppColors.success,
                  ),
              ],
            ),
          ),

          // ── View Plan button ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                ),
                onPressed: () => context.push(AppRoutes.plans),
                child: const Text('View Plan →',
                    style: AppTextStyles.bodyMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.appColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.captionMuted.copyWith(color: c)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline Item
// ---------------------------------------------------------------------------

class _TimelineItem extends StatelessWidget {
  final TripSegment segment;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.segment,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final pct = segment.discoveryPct.clamp(0.0, 100.0);
    final dotColor = pct >= 70
        ? AppColors.success
        : pct >= 40
            ? AppColors.warning
            : AppColors.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline spine ──────────────────────────────────────────
          SizedBox(
            width: 28,
            child: Column(
              children: [
                // Line above dot
                if (!isFirst)
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Container(width: 2, color: context.appColors.divider),
                    ),
                  ),
                // Dot
                Container(
                  width: 14,
                  height: 14,
                  margin: EdgeInsets.symmetric(
                      vertical: isFirst || isLast ? 0 : 0),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                // Line below dot
                if (!isLast)
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Container(width: 2, color: context.appColors.divider),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // ── Trip card ───────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _TripCard(segment: segment, dotColor: dotColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripSegment segment;
  final Color dotColor;
  const _TripCard({required this.segment, required this.dotColor});

  @override
  Widget build(BuildContext context) {
    final pct = segment.discoveryPct.clamp(0.0, 100.0);
    final countryCode = segment.country?.countryCode ?? '';
    final flagEmoji = _flagEmoji(countryCode);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.cityDashboardPath(segment.city.id)),
      child: Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: context.appColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: Row(
              children: [
                if (flagEmoji.isNotEmpty)
                  Text(flagEmoji,
                      style: const TextStyle(fontSize: 18)),
                if (flagEmoji.isNotEmpty) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(segment.city.name,
                          style: AppTextStyles.bodyMedium),
                      if (segment.country != null)
                        Text(segment.country!.name,
                            style: AppTextStyles.captionMuted),
                    ],
                  ),
                ),
                // Date badge
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceElevated,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusChip),
                  ),
                  child: Text(segment.dateLabel,
                      style: AppTextStyles.captionMuted),
                ),
              ],
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Row(
              children: [
                _MiniStat(
                  icon: Icons.place_outlined,
                  label: '${segment.visitCount} places',
                ),
                const SizedBox(width: AppSpacing.lg),
                _MiniStat(
                  icon: Icons.star_rounded,
                  label: segment.avgRating.toStringAsFixed(1),
                  color: AppColors.warning,
                ),
                const Spacer(),
                Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: AppTextStyles.caption.copyWith(color: dotColor),
                ),
              ],
            ),
          ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs,
                AppSpacing.lg, AppSpacing.md),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 4,
                backgroundColor: context.appColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(dotColor),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  static String _flagEmoji(String code) {
    if (code.length != 2) return '';
    const base = 0x1F1E6 - 0x41;
    final chars = code.toUpperCase().codeUnits;
    return String.fromCharCodes([base + chars[0], base + chars[1]]);
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MiniStat({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? context.appColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: effectiveColor),
        const SizedBox(width: 3),
        Text(label,
            style: AppTextStyles.captionMuted.copyWith(color: effectiveColor)),
      ],
    );
  }
}

