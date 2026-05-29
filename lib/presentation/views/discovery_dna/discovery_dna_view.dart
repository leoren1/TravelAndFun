// lib/presentation/views/discovery_dna/discovery_dna_view.dart

import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/presentation/viewmodels/discovery_dna_viewmodel.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

// ---------------------------------------------------------------------------
// Dimension colour palette  (one accent per DNA axis)
// ---------------------------------------------------------------------------

Color _dimColor(String label) => switch (label) {
      'History'   => const Color(0xFFF59E0B), // amber
      'Food'      => const Color(0xFFEA580C), // deep orange
      'Nature'    => const Color(0xFF22C55E), // green
      'Events'    => const Color(0xFF3B82F6), // blue
      'Nightlife' => const Color(0xFF8B5CF6), // violet
      'Local Exp' => const Color(0xFF14B8A6), // teal
      'Shopping'  => const Color(0xFFEC4899), // pink
      'Museums'   => const Color(0xFF06B6D4), // cyan
      _           => AppColors.primary,
    };

// ---------------------------------------------------------------------------
// Personality type derived from top DNA axis
// ---------------------------------------------------------------------------

String _personalityTitle(String topLabel, double topValue) {
  if (topValue < 5) return 'The Explorer';
  return switch (topLabel) {
    'History'   => 'The Historian',
    'Food'      => 'The Gastronaut',
    'Nature'    => 'The Earth Walker',
    'Events'    => 'The Pulse Chaser',
    'Nightlife' => 'The Night Wanderer',
    'Local Exp' => 'The Urban Scout',
    'Shopping'  => 'The Market Diver',
    'Museums'   => 'The Curator Soul',
    _           => 'The Free Spirit',
  };
}

String _personalityTagline(String topLabel) => switch (topLabel) {
      'History'   => 'Ancient walls speak to you first.',
      'Food'      => 'Every meal is a new destination.',
      'Nature'    => 'You prefer horizons over hotel lobbies.',
      'Events'    => 'You\'re always where the energy is.',
      'Nightlife' => 'The city reveals itself after dark.',
      'Local Exp' => 'You find doors others walk past.',
      'Shopping'  => 'Every bazaar tells its own story.',
      'Museums'   => 'The world is one large exhibit.',
      _           => 'No itinerary can hold you.',
    };

// ---------------------------------------------------------------------------
// Root view
// ---------------------------------------------------------------------------

class DiscoveryDnaView extends ConsumerWidget {
  const DiscoveryDnaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(discoveryDnaViewModelProvider);

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        titleSpacing: AppSpacing.lg,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.insights, color: Colors.white, size: 15),
            ),
            const SizedBox(width: 10),
            Text('Discovery DNA', style: AppTextStyles.titleSmall),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.appColors.textSecondary),
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
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Text(err.toString(), style: AppTextStyles.body),
          ),
        ),
        data: (state) => _Body(state: state),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _Body extends StatelessWidget {
  final DiscoveryDnaState state;
  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal, AppSpacing.lg,
          AppSpacing.pageHorizontal, AppSpacing.xxxl),
      children: [
        // ── Hero card (personality + fingerprint) ───────────────────
        _PersonalityCard(state: state),
        const SizedBox(height: AppSpacing.sectionGap),

        if (state.hasData) ...[
          // ── Radar chart ─────────────────────────────────────────
          _SectionHeader(label: 'DNA Radar'),
          const SizedBox(height: AppSpacing.lg),
          _RadarCard(state: state),
          const SizedBox(height: AppSpacing.sectionGap),
        ],

        // ── Badges & Tiers ────────────────────────────────────────
        Row(
          children: [
            _SectionHeader(label: 'Badges & Tiers'),
            const SizedBox(width: AppSpacing.sm),
            if (state.totalTiers > 0)
              _EarnedPill(
                  earned: state.earnedCount, total: state.totalTiers),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '🥉 20%  ·  🥈 40%  ·  🥇 65%  ·  💎 85%',
          style: AppTextStyles.overline,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (state.dimensionBlocks.isEmpty)
          _EmptyHint(message: 'Verify visits to unlock tiers.')
        else
          ...state.dimensionBlocks
              .map((b) => _DimensionCard(block: b)),

        // ── Where to explore next ─────────────────────────────────
        if (state.hasData && state.targets.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sectionGap),
          _SectionHeader(label: 'Where to Explore Next'),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Boost your weakest dimensions here.',
            style: AppTextStyles.captionMuted,
          ),
          const SizedBox(height: AppSpacing.lg),
          ...state.targets.map((t) => _TargetCard(target: t)),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Personality / fingerprint hero card
// ---------------------------------------------------------------------------

class _PersonalityCard extends StatelessWidget {
  final DiscoveryDnaState state;
  const _PersonalityCard({required this.state});

  @override
  Widget build(BuildContext context) {
    if (!state.hasData) return const _EmptyDnaCard();

    final topLabel = state.topAxis?.label ?? '';
    final topValue = state.topAxis?.value ?? 0.0;
    final topColor = _dimColor(topLabel);
    final title    = _personalityTitle(topLabel, topValue);
    final tagline  = _personalityTagline(topLabel);

    // Overall DNA score (0–100, average of all axes)
    final overallScore = state.axes.isEmpty
        ? 0
        : (state.axes.fold<double>(0, (s, a) => s + a.value) /
                state.axes.length)
            .round();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            topColor.withOpacity(0.14),
            context.appColors.surfaceElevated,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: topColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Identity header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: topColor,
                          letterSpacing: 0.6,
                          fontFamily: 'Inter',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '"$tagline"',
                        style: AppTextStyles.body.copyWith(
                          color: context.appColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Overall score badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$overallScore',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: topColor,
                        fontFamily: 'Inter',
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'avg score',
                      style: AppTextStyles.overline,
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 16),
          Divider(height: 1, color: context.appColors.divider),

          // ── DNA Fingerprint bars ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              children: state.axes.map((axis) {
                final color = _dimColor(axis.label);
                final value = axis.value.clamp(0.0, 100.0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        child: Text(
                          axis.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'Inter',
                            color: context.appColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: value / 100,
                            minHeight: 7,
                            backgroundColor: context.appColors.divider,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${value.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Bottom earned tiers strip ────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: topColor.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppSpacing.radiusCard),
                bottomRight: Radius.circular(AppSpacing.radiusCard),
              ),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.workspace_premium,
                    color: topColor, size: 14),
                const SizedBox(width: 6),
                Text(
                  '${state.earnedCount} of ${state.totalTiers} tiers earned',
                  style: AppTextStyles.caption.copyWith(color: topColor),
                ),
                const Spacer(),
                if (state.bottomAxis != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusChip),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_upward,
                            color: AppColors.warning, size: 10),
                        const SizedBox(width: 3),
                        Text(
                          'Grow ${state.bottomAxis!.label}',
                          style: AppTextStyles.overline
                              .copyWith(color: AppColors.warning),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Radar chart
// ---------------------------------------------------------------------------

class _RadarCard extends StatelessWidget {
  final DiscoveryDnaState state;
  const _RadarCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: context.appColors.divider),
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
              fillColor: AppColors.primary.withOpacity(0.22),
              borderColor: AppColors.primary,
              borderWidth: 2,
              entryRadius: 4,
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData:
              BorderSide(color: context.appColors.divider, width: 0.8),
          tickBorderData:
              BorderSide(color: context.appColors.divider, width: 0.5),
          gridBorderData:
              BorderSide(color: context.appColors.divider, width: 0.5),
          titleTextStyle: TextStyle(
              color: context.appColors.textSecondary,
              fontSize: 10,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600),
          getTitle: (index, angle) {
            const titles = [
              'History', 'Food', 'Nature', 'Events',
              'Nightlife', 'Local', 'Shopping', 'Museums',
            ];
            return RadarChartTitle(text: titles[index]);
          },
          tickCount: 4,
          ticksTextStyle: TextStyle(
              color: context.appColors.textMuted, fontSize: 8),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact dimension tier card
// ---------------------------------------------------------------------------

class _DimensionCard extends StatelessWidget {
  final DnaDimensionBlock block;
  const _DimensionCard({required this.block});

  @override
  Widget build(BuildContext context) {
    final color = _dimColor(block.dimensionLabel);
    final next  = block.nextTier;

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appColors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Colored left accent bar
              Container(width: 4, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon circle
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(block.dimensionIcon,
                        style: const TextStyle(fontSize: 19)),
                  ),
                ),
                const SizedBox(width: 10),

                // Name + medal row
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(block.dimensionLabel,
                          style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 4),
                      Row(
                        children: block.tiers.map((t) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Opacity(
                              opacity: t.isEarned ? 1.0 : 0.2,
                              child: Text(t.tierIcon,
                                  style: const TextStyle(fontSize: 14)),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // Current % + tier label
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${block.currentPct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: color,
                        fontFamily: 'Inter',
                        height: 1.1,
                      ),
                    ),
                    Text(
                      block.currentTierLabel,
                      style: AppTextStyles.overline.copyWith(color: color),
                    ),
                  ],
                ),
              ],
            ),

            // ── Next tier progress ──────────────────────────────────
            if (next != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(next.tierIcon,
                      style: const TextStyle(fontSize: 12)),
                  SizedBox(width: 5),
                  Text(next.tierLabel,
                      style: AppTextStyles.overline
                          .copyWith(color: context.appColors.textSecondary)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      next.badgeName,
                      style: AppTextStyles.captionMuted,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '−${next.remaining.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: next.progressFraction,
                  minHeight: 5,
                  backgroundColor: context.appColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ] else ...[
              // All tiers mastered
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.workspace_premium,
                      color: color, size: 13),
                  const SizedBox(width: 5),
                  Text(
                    'All tiers mastered!',
                    style: AppTextStyles.overline.copyWith(color: color),
                  ),
                ],
              ),
            ],
          ],
        ),        // closes Column
                ),  // closes Padding
              ),  // closes Expanded
            ],    // closes Row.children
          ),      // closes Row
        ),        // closes IntrinsicHeight
      ),          // closes ClipRRect
    );            // closes Container
  }
}

// ---------------------------------------------------------------------------
// Target card
// ---------------------------------------------------------------------------

class _TargetCard extends StatelessWidget {
  final DnaTarget target;
  const _TargetCard({required this.target});

  @override
  Widget build(BuildContext context) {
    final color = _dimColor(target.categoryLabel);

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border(
          left:   BorderSide(color: color, width: 3),
          right:  BorderSide(color: context.appColors.divider),
          top:    BorderSide(color: context.appColors.divider),
          bottom: BorderSide(color: context.appColors.divider),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(target.categoryIcon,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(target.categoryLabel,
                        style: AppTextStyles.bodyMedium),
                    Text('in ${target.city.name}',
                        style: AppTextStyles.captionMuted),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusChip),
                ),
                child: Text(
                  '${target.currentPct.toStringAsFixed(0)}%',
                  style: AppTextStyles.overline.copyWith(color: color),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: target.currentPct / 100,
              minHeight: 4,
              backgroundColor: context.appColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Suggested places:',
              style: AppTextStyles.overline),
          const SizedBox(height: AppSpacing.xs),
          ...target.suggestedPlaceNames.map(
            (name) => Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ',
                      style: TextStyle(
                          color: color, fontSize: 12)),
                  Expanded(
                    child: Text(name,
                        style: AppTextStyles.caption
                            .copyWith(
                                color: context.appColors.textSecondary)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small utility widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.titleSmall);
  }
}

class _EarnedPill extends StatelessWidget {
  final int earned;
  final int total;
  const _EarnedPill({required this.earned, required this.total});

  @override
  Widget build(BuildContext context) {
    final hasAny = earned > 0;
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: hasAny
            ? AppColors.success.withOpacity(0.15)
            : context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
      ),
      child: Text(
        '$earned / $total',
        style: AppTextStyles.overline.copyWith(
          color: hasAny ? AppColors.success : context.appColors.textMuted,
        ),
      ),
    );
  }
}

class _EmptyDnaCard extends StatelessWidget {
  const _EmptyDnaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Column(
        children: [
          Icon(Icons.explore_outlined,
              color: context.appColors.textMuted, size: 48),
          const SizedBox(height: AppSpacing.md),
          const Text('Not enough data yet',
              style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Verify some visits to reveal your travel DNA.',
            style: AppTextStyles.captionMuted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String message;
  const _EmptyHint({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Text(message, style: AppTextStyles.captionMuted),
    );
  }
}


