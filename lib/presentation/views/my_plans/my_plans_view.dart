// lib/presentation/views/my_plans/my_plans_view.dart

import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/core/router/app_routes.dart';
import 'package:explore_index/data/models/trip_plan.dart';
import 'package:explore_index/presentation/viewmodels/my_plans_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

class MyPlansView extends ConsumerWidget {
  const MyPlansView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myPlansViewModelProvider);

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        titleSpacing: AppSpacing.lg,
        title: const Text('My Plans', style: AppTextStyles.titleSmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined,
                color: AppColors.primary),
            tooltip: 'Plan new trip',
            onPressed: () => context.push(AppRoutes.tripPlanner),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) =>
            Center(child: Text(e.toString(), style: AppTextStyles.body)),
        data: (state) {
          if (state.isEmpty) return _EmptyPlans(context: context);
          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: context.appColors.surfaceElevated,
            onRefresh: () =>
                ref.read(myPlansViewModelProvider.notifier).refresh(),
            child: CustomScrollView(
              slivers: [
                // ── Upcoming ─────────────────────────────────────────────
                if (state.upcoming.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: _SectionHeader(
                        icon: Icons.upcoming_outlined,
                        label: 'Upcoming Trips',
                        color: AppColors.primary),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageHorizontal),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _PlanCard(
                          detail: state.upcoming[i],
                          onComplete: () => ref
                              .read(myPlansViewModelProvider.notifier)
                              .completePlan(state.upcoming[i].plan.id),
                          onDelete: () => ref
                              .read(myPlansViewModelProvider.notifier)
                              .deletePlan(state.upcoming[i].plan.id),
                        ),
                        childCount: state.upcoming.length,
                      ),
                    ),
                  ),
                ],

                // ── Past ─────────────────────────────────────────────────
                if (state.past.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                        icon: Icons.history_outlined,
                        label: 'Past Trips',
                        color: context.appColors.textSecondary),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageHorizontal),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _PlanCard(
                          detail: state.past[i],
                          isPast: true,
                          onDelete: () => ref
                              .read(myPlansViewModelProvider.notifier)
                              .deletePlan(state.past[i].plan.id),
                        ),
                        childCount: state.past.length,
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        },
      ),

      // FAB
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push(AppRoutes.tripPlanner),
        icon: const Icon(Icons.map_outlined),
        label: const Text('New Plan'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyPlans extends StatelessWidget {
  final BuildContext context;
  const _EmptyPlans({required this.context});

  @override
  Widget build(BuildContext _) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.map_outlined,
                  color: AppColors.primary, size: 44),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text('No trips planned yet',
                style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Start exploring the world map and plan\nyour next adventure.',
              style: AppTextStyles.captionMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.tripPlanner),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Plan My First Trip'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl, vertical: AppSpacing.md),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xxl,
          AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(label,
              style: AppTextStyles.titleSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Plan card
// ---------------------------------------------------------------------------

class _PlanCard extends StatelessWidget {
  final TripPlanDetail detail;
  final bool isPast;
  final VoidCallback? onComplete;
  final VoidCallback onDelete;

  const _PlanCard({
    required this.detail,
    this.isPast = false,
    this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final plan = detail.plan;
    final city = detail.city;
    final country = detail.country;
    final places = detail.places;

    final flag = country != null ? _flagEmoji(country.countryCode) : '🌍';
    final gain = plan.discoveryGain;
    final isCompleted = plan.status == TripPlanStatus.completed;

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: isCompleted
              ? AppColors.success.withValues(alpha: 0.3)
              : context.appColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Flag + city info
                Text(flag, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              city?.name ?? plan.cityName,
                              style: AppTextStyles.titleSmall,
                            ),
                          ),
                          if (isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusChip),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: AppColors.success, size: 12),
                                  const SizedBox(width: 3),
                                  Text('Done',
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.success)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (country != null)
                        Text(country.name,
                            style: AppTextStyles.captionMuted),
                      const SizedBox(height: AppSpacing.xs),
                      // Date
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 12,
                              color: context.appColors.textMuted),
                          SizedBox(width: 4),
                          Text(
                            _formatDate(plan.plannedDate),
                            style: AppTextStyles.caption.copyWith(
                                color: context.appColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Discovery gain ───────────────────────────────────────────────
          if (gain > 0)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg),
              child: Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: context.appColors.surfaceElevated,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '+${gain.toStringAsFixed(0)}% discovery gain',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.success),
                    ),
                    const Spacer(),
                    Text(
                      '${plan.currentDiscovery.toStringAsFixed(0)}% → ${plan.projectedDiscovery.toStringAsFixed(0)}%',
                      style: AppTextStyles.captionMuted,
                    ),
                  ],
                ),
              ),
            ),

          // ── Places chips ─────────────────────────────────────────────────
          if (places.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: places.take(5).map((p) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        AppColors.primary.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusChip),
                  ),
                  child: Text(
                    p.name,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.primary),
                  ),
                )).toList()
                  ..addAll(places.length > 5
                      ? [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.appColors.divider,
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusChip),
                            ),
                            child: Text(
                              '+${places.length - 5} more',
                              style: AppTextStyles.captionMuted,
                            ),
                          )
                        ]
                      : []),
              ),
            ),

          // ── Actions ───────────────────────────────────────────────────────
          if (!isPast)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Complete
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Mark Done'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(
                            color: AppColors.success, width: 1),
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Delete
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.danger, size: 20),
                    style: IconButton.styleFrom(
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSmall)),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline,
                      color: context.appColors.textMuted, size: 18),
                  style: IconButton.styleFrom(
                    side: BorderSide(color: context.appColors.divider),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSmall)),
                  ),
                ),
              ),
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

  static String _formatDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}


