// lib/presentation/views/profile/profile_view.dart

import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/core/router/app_routes.dart';
import 'package:explore_index/presentation/viewmodels/profile_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(profileViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: AppSpacing.lg,
        title: const Text('Profile', style: AppTextStyles.titleSmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
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

            // ── Badges grid ───────────────────────────────────────────────
            Text('Badges', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.lg),
            _BadgesGrid(state: state),
            const SizedBox(height: AppSpacing.sectionGap),

            // ── Your Stats ────────────────────────────────────────────────
            Text('Your Stats', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.lg),
            _StatsList(state: state),
            const SizedBox(height: AppSpacing.sectionGap),

            // ── Discovery DNA button ──────────────────────────────────────
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.surfaceElevated,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
              onPressed: () => context.push(AppRoutes.discoveryDna),
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
              backgroundColor: AppColors.surfaceElevated,
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
                  color: AppColors.textPrimary,
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
              const Icon(Icons.workspace_premium, color: AppColors.warning, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Level ${profile.level} — ${profile.levelTitle}',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            child: LinearProgressIndicator(
              value: profile.xpProgress,
              minHeight: 8,
              backgroundColor: AppColors.divider,
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
                color: isLocked ? AppColors.surfaceElevated : AppColors.primary.withOpacity(0.15),
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            entry.badge.name,
            style: AppTextStyles.overline.copyWith(
              color: isLocked ? AppColors.textMuted : AppColors.textSecondary,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _StatsListItem(
            icon: Icons.flag_outlined,
            label: 'Countries Visited',
            value: '${stats.countriesVisited}',
          ),
          const Divider(height: 1, color: AppColors.divider),
          _StatsListItem(
            icon: Icons.location_city_outlined,
            label: 'Cities Visited',
            value: '${stats.citiesVisited}',
          ),
          const Divider(height: 1, color: AppColors.divider),
          _StatsListItem(
            icon: Icons.place_outlined,
            label: 'Unique Places',
            value: '${stats.uniquePlacesVisited}',
          ),
          const Divider(height: 1, color: AppColors.divider),
          _StatsListItem(
            icon: Icons.check_circle_outline,
            label: 'Total Visits',
            value: '${stats.totalVisits}',
          ),
          const Divider(height: 1, color: AppColors.divider),
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
