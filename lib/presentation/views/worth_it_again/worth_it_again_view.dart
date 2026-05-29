// lib/presentation/views/worth_it_again/worth_it_again_view.dart

import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/data/models/category.dart';
import 'package:explore_index/presentation/viewmodels/worth_it_again_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

class WorthItAgainView extends ConsumerWidget {
  final String cityId;
  const WorthItAgainView({super.key, required this.cityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(worthItAgainViewModelProvider(cityId));

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.appColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Worth It Again?', style: AppTextStyles.titleSmall),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.appColors.textSecondary),
            onPressed: () => ref
                .read(worthItAgainViewModelProvider(cityId).notifier)
                .refresh(),
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
            // ── Title ─────────────────────────────────────────────────────
            Text(
              'Should you visit\n${state.city.name} again?',
              style: AppTextStyles.display,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── BIG YES/NO ────────────────────────────────────────────────
            Center(
              child: Text(
                state.worthIt ? 'YES' : 'NO',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 72,
                  fontWeight: FontWeight.w700,
                  color: state.worthIt ? AppColors.success : AppColors.danger,
                  height: 1,
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                state.reason,
                style: AppTextStyles.body.copyWith(color: context.appColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // ── Undiscovered percentage ───────────────────────────────────
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.appColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: Border.all(color: context.appColors.divider),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.explore_outlined,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'You still have ${(100 - state.discoveryPercent).clamp(0, 100).toStringAsFixed(0)}% undiscovered',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    child: LinearProgressIndicator(
                      value: state.discoveryPercent / 100,
                      minHeight: 8,
                      backgroundColor: context.appColors.divider,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${state.discoveryPercent.toStringAsFixed(0)}% discovered',
                      style: AppTextStyles.captionMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // ── Missing categories ────────────────────────────────────────
            if (state.missingCategories.isNotEmpty) ...[
              Text('Missing Categories', style: AppTextStyles.titleSmall),
              const SizedBox(height: AppSpacing.lg),
              ...state.missingCategories.map((cat) {
                final pct = state.missingCategoryPcts[cat] ?? 0.0;
                final progressColor = pct >= 50
                    ? AppColors.warning
                    : AppColors.danger;
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: context.appColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    border: Border.all(color: context.appColors.divider),
                  ),
                  child: Row(
                    children: [
                      Text(cat.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cat.displayName, style: AppTextStyles.bodyMedium),
                            const SizedBox(height: AppSpacing.xs),
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSmall),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                minHeight: 4,
                                backgroundColor: context.appColors.divider,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    progressColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: AppTextStyles.caption
                            .copyWith(color: progressColor),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.sectionGap),
            ],

            // ── AI-style insight ──────────────────────────────────────────
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.appColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: AppColors.primary, size: 16),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Explore Insight',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(state.insightParagraph, style: AppTextStyles.body),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // ── Create Second Trip Plan button ────────────────────────────
            if (state.tripPlanPlaces.isNotEmpty)
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                ),
                onPressed: () => _showTripPlanSheet(context, state),
                child: const Text(
                  'Create Second Trip Plan',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
        ),
      ),
    );
  }

  void _showTripPlanSheet(BuildContext context, WorthItAgainState state) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusHero),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Your Second Trip Plan', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Top ${state.tripPlanPlaces.length} places to visit next time:',
              style: AppTextStyles.captionMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            ...state.tripPlanPlaces.map(
              (place) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(place.name, style: AppTextStyles.bodyMedium),
                          Text(
                            place.category.displayName,
                            style: AppTextStyles.captionMuted,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+${place.discoveryBoost.toStringAsFixed(1)}%',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}


