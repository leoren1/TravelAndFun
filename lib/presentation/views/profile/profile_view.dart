// lib/presentation/views/profile/profile_view.dart

import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/core/router/app_routes.dart';
import 'package:explore_index/core/theme/theme_provider.dart';
import 'package:explore_index/data/models/travel_mode.dart';
import 'package:explore_index/presentation/viewmodels/profile_viewmodel.dart';
import 'package:explore_index/presentation/views/mode_selector/mode_selector_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(profileViewModelProvider);

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        titleSpacing: AppSpacing.lg,
        title: const Text('Profile', style: AppTextStyles.titleSmall),
        actions: [
          // ── Theme toggle ──────────────────────────────────────────────────
          Consumer(builder: (ctx, r, _) {
            final isDark = r.watch(themeProvider) == ThemeMode.dark;
            return IconButton(
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: ctx.appColors.textSecondary,
              ),
              onPressed: () => r.read(themeProvider.notifier).toggle(),
            );
          }),
          IconButton(
            icon: Icon(Icons.refresh, color: context.appColors.textSecondary),
            onPressed: () => ref.read(profileViewModelProvider.notifier).refresh(),
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
            // ── Avatar + name + title ─────────────────────────────────────
            _AvatarSection(state: state),
            const SizedBox(height: AppSpacing.sectionGap),

            // ── Level card ────────────────────────────────────────────────
            _LevelCard(state: state),
            const SizedBox(height: AppSpacing.sectionGap),

            // ── Mode discovery stats ──────────────────────────────────────
            _ModeDiscoveryCard(state: state),
            const SizedBox(height: AppSpacing.sectionGap),

            // ── Badges grid ───────────────────────────────────────────────
            Text('Badges', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.lg),
            _BadgesGrid(state: state),
            const SizedBox(height: AppSpacing.sectionGap),

            // ── Your Stats ────────────────────────────────────────────────
            Text('Your Stats', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.lg),
            _StatsList(state: state),
            SizedBox(height: AppSpacing.sectionGap),

            // ── Discovery DNA button ──────────────────────────────────────
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: context.appColors.surfaceElevated,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
              onPressed: () => context.go(AppRoutes.dna),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text(
                'Discovery DNA →',
                style: AppTextStyles.bodyMedium,
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
// Avatar Section
// ---------------------------------------------------------------------------

class _AvatarSection extends StatelessWidget {
  final ProfileState state;
  const _AvatarSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: context.appColors.surfaceElevated,
              backgroundImage: profile.avatarPath.isNotEmpty
                  ? AssetImage(profile.avatarPath)
                  : null,
              child: profile.avatarPath.isEmpty
                  ? Text(
                      profile.name.isNotEmpty
                          ? profile.name[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.display,
                    )
                  : null,
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${profile.level}',
                style: AppTextStyles.overline.copyWith(
                  color: context.appColors.textPrimary,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(profile.name, style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.xs),
        Text(profile.title, style: AppTextStyles.captionMuted),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Level Card
// ---------------------------------------------------------------------------

class _LevelCard extends StatelessWidget {
  final ProfileState state;
  const _LevelCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
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
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: AppColors.warning, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Level ${profile.level} — ${profile.levelTitle}',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            child: LinearProgressIndicator(
              value: profile.xpProgress,
              minHeight: 8,
              backgroundColor: context.appColors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${profile.xp} XP', style: AppTextStyles.captionMuted),
              Text('${profile.xpForNextLevel} XP', style: AppTextStyles.captionMuted),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Badges Grid
// ---------------------------------------------------------------------------

class _BadgesGrid extends StatelessWidget {
  final ProfileState state;
  const _BadgesGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.badges.isEmpty) {
      return Text('No badges yet.', style: AppTextStyles.captionMuted);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.85,
      ),
      itemCount: state.badges.length,
      itemBuilder: (context, index) {
        final entry = state.badges[index];
        return _BadgeCell(entry: entry);
      },
    );
  }
}

class _BadgeCell extends StatelessWidget {
  final BadgeEntry entry;
  const _BadgeCell({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isLocked = !entry.isUnlocked;

    return Tooltip(
      message: entry.badge.description,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipPath(
            clipper: _HexClipper(),
            child: ColorFiltered(
              colorFilter: isLocked
                  ? const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0, 0, 0, 0.5, 0,
                    ])
                  : const ColorFilter.mode(
                      Colors.transparent,
                      BlendMode.color,
                    ),
              child: Container(
                width: 56,
                height: 56,
                color: isLocked ? context.appColors.surfaceElevated : AppColors.primary.withOpacity(0.15),
                alignment: Alignment.center,
                child: Text(
                  entry.badge.icon,
                  style: TextStyle(
                    fontSize: 24,
                    color: isLocked ? null : null,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            entry.badge.name,
            style: AppTextStyles.overline.copyWith(
              color: isLocked ? context.appColors.textMuted : context.appColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Clips child into a hexagon shape.
class _HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.75)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.75)
      ..lineTo(0, h * 0.25)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ---------------------------------------------------------------------------
// Mode Discovery Card
// ---------------------------------------------------------------------------

class _ModeDiscoveryCard extends StatelessWidget {
  final ProfileState state;
  const _ModeDiscoveryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final md = state.modeDiscovery;
    final current = state.currentMode;

    return GestureDetector(
      onTap: () => showModeSelectorSheet(context),
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
            Row(
              children: [
                const Icon(Icons.tune_outlined,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text('World Discovery by Mode',
                    style: AppTextStyles.bodyMedium),
                Spacer(),
                Icon(Icons.chevron_right,
                    color: context.appColors.textMuted, size: 18),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _ModeBar(
              mode: TravelMode.bronze,
              pct: md.bronze,
              isActive: current == TravelMode.bronze,
            ),
            const SizedBox(height: AppSpacing.md),
            _ModeBar(
              mode: TravelMode.silver,
              pct: md.silver,
              isActive: current == TravelMode.silver,
            ),
            const SizedBox(height: AppSpacing.md),
            _ModeBar(
              mode: TravelMode.gold,
              pct: md.gold,
              isActive: current == TravelMode.gold,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeBar extends StatelessWidget {
  final TravelMode mode;
  final double pct;
  final bool isActive;

  const _ModeBar({
    required this.mode,
    required this.pct,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = mode.color;
    final clamped = pct.clamp(0.0, 100.0);

    return Row(
      children: [
        Text(mode.emoji, style: const TextStyle(fontSize: 16)),
        SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 52,
          child: Text(
            mode.shortName,
            style: AppTextStyles.caption.copyWith(
              color: isActive ? color : context.appColors.textSecondary,
              fontWeight:
                  isActive ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(AppSpacing.radiusSmall),
            child: LinearProgressIndicator(
              value: clamped / 100,
              minHeight: isActive ? 8 : 5,
              backgroundColor: context.appColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                isActive ? color : color.withOpacity(0.5),
              ),
            ),
          ),
        ),
        SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 44,
          child: Text(
            '${clamped.toStringAsFixed(1)}%',
            style: AppTextStyles.caption.copyWith(
              color: isActive ? color : context.appColors.textMuted,
              fontWeight:
                  isActive ? FontWeight.w700 : FontWeight.w400,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stats List
// ---------------------------------------------------------------------------

class _StatsList extends StatelessWidget {
  final ProfileState state;
  const _StatsList({required this.state});

  @override
  Widget build(BuildContext context) {
    final stats = state.stats;
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Column(
        children: [
          _StatsListItem(
            icon: Icons.flag_outlined,
            label: 'Countries Visited',
            value: '${stats.countriesVisited}',
          ),
          Divider(height: 1, color: context.appColors.divider),
          _StatsListItem(
            icon: Icons.location_city_outlined,
            label: 'Cities Visited',
            value: '${stats.citiesVisited}',
          ),
          Divider(height: 1, color: context.appColors.divider),
          _StatsListItem(
            icon: Icons.place_outlined,
            label: 'Unique Places',
            value: '${stats.uniquePlacesVisited}',
          ),
          Divider(height: 1, color: context.appColors.divider),
          _StatsListItem(
            icon: Icons.check_circle_outline,
            label: 'Total Visits',
            value: '${stats.totalVisits}',
          ),
          Divider(height: 1, color: context.appColors.divider),
          _StatsListItem(
            icon: Icons.star_border,
            label: 'Average Rating',
            value: stats.averageRating.toStringAsFixed(1),
          ),
        ],
      ),
    );
  }
}

class _StatsListItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatsListItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: AppTextStyles.body)),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}


