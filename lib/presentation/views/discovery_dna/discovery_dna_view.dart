// lib/presentation/views/discovery_dna/discovery_dna_view.dart

import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/presentation/viewmodels/discovery_dna_viewmodel.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DiscoveryDnaView extends ConsumerWidget {
  const DiscoveryDnaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(discoveryDnaViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Discovery DNA', style: AppTextStyles.titleSmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () =>
                ref.read(discoveryDnaViewModelProvider.notifier).refresh(),
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
        data: (state) => ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
            vertical: AppSpacing.lg,
          ),
          children: [
            // ── Title ─────────────────────────────────────────────────────
            Text('Your Discovery DNA', style: AppTextStyles.display),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Based on the places you have explored.',
              style: AppTextStyles.captionMuted,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── No data message ───────────────────────────────────────────
            if (!state.hasData) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.explore_outlined,
                        color: AppColors.textMuted, size: 48),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Not enough data yet',
                      style: AppTextStyles.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Start verifying visits to see your Discovery DNA profile.',
                      style: AppTextStyles.captionMuted,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // ── Radar Chart ───────────────────────────────────────────
              Container(
                height: 320,
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  border: Border.all(color: AppColors.divider),
                ),
                child: RadarChart(
                  RadarChartData(
                    dataSets: [
                      RadarDataSet(
                        dataEntries: [
                          RadarEntry(value: state.dna.history),
                          RadarEntry(value: state.dna.food),
                          RadarEntry(value: state.dna.nature),
                          RadarEntry(value: state.dna.events),
                          RadarEntry(value: state.dna.nightlife),
                          RadarEntry(value: state.dna.localExp),
                          RadarEntry(value: state.dna.shopping),
                          RadarEntry(value: state.dna.museums),
                        ],
                        fillColor: AppColors.primary.withOpacity(0.3),
                        borderColor: AppColors.primary,
                        borderWidth: 2,
                        entryRadius: 4,
                      ),
                    ],
                    radarBackgroundColor: Colors.transparent,
                    borderData: FlBorderData(show: false),
                    radarBorderData:
                        const BorderSide(color: AppColors.divider),
                    tickBorderData:
                        const BorderSide(color: AppColors.divider),
                    gridBorderData:
                        const BorderSide(color: AppColors.divider),
                    titleTextStyle: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                    getTitle: (index, angle) {
                      const titles = [
                        'History', 'Food', 'Nature', 'Events',
                        'Nightlife', 'Local', 'Shopping', 'Museums',
                      ];
                      return RadarChartTitle(text: titles[index]);
                    },
                    tickCount: 4,
                    ticksTextStyle: const TextStyle(
                        color: AppColors.textMuted, fontSize: 9),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),

              // ── Axes breakdown ────────────────────────────────────────
              Text('Breakdown', style: AppTextStyles.titleSmall),
              const SizedBox(height: AppSpacing.lg),
              ...state.axes.map(
                (axis) => _AxisBar(axis: axis),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
            ],

            // ── Summary card ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
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
                        'Your DNA Summary',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(state.dna.summary, style: AppTextStyles.body),
                  if (state.topAxis != null && state.bottomAxis != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryTag(
                            label: 'Top Interest',
                            value: state.topAxis!.label,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _SummaryTag(
                            label: 'Least Explored',
                            value: state.bottomAxis!.label,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Axis Bar
// ---------------------------------------------------------------------------

class _AxisBar extends StatelessWidget {
  final DnaAxis axis;
  const _AxisBar({required this.axis});

  @override
  Widget build(BuildContext context) {
    final value = axis.value.clamp(0.0, 100.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              axis.label,
              style: AppTextStyles.captionMuted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 8,
                backgroundColor: AppColors.divider,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 36,
            child: Text(
              '${value.toStringAsFixed(0)}%',
              style: AppTextStyles.captionMuted,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary Tag
// ---------------------------------------------------------------------------

class _SummaryTag extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryTag({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.overline),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(color: color),
        ),
      ],
    );
  }
}
