// Premium place cards used in city discovery grids and nearby-places sections.
//
//  • TpPlaceCard      — large (grid) or compact (inline) format.
//  • TpPlaceCardCompact — horizontal card for the nearby-places list.
import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/features/trip_planner/data/models/explore_place.dart';
import 'package:flutter/material.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TpPlaceCard  (large vertical card)
// ─────────────────────────────────────────────────────────────────────────────

class TpPlaceCard extends StatelessWidget {
  final ExplorePlace place;
  final VoidCallback onTap;

  /// Large format for grid view vs. compact (smaller) format.
  final bool isLarge;

  /// Shows a floating "+" button to add the place to the active schedule.
  final bool showAddButton;
  final VoidCallback? onAdd;

  const TpPlaceCard({
    super.key,
    required this.place,
    required this.onTap,
    this.isLarge = true,
    this.showAddButton = false,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final double cardHeight = isLarge ? 220.0 : 150.0;
    const radius = BorderRadius.all(Radius.circular(20));

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: cardHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Gradient "hero image" ───────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [place.gradientStart, place.gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

              // ── Diagonal depth layer ────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      place.gradientStart.withOpacity(0.25),
                      Colors.transparent,
                      place.gradientEnd.withOpacity(0.35),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // ── Bottom text vignette ────────────────────────────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.75),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.35, 1.0],
                    ),
                  ),
                ),
              ),

              // ── Discovery points chip (top-left) ────────────────────────
              Positioned(
                top: 12,
                left: 12,
                child: _DiscoveryPointsChip(points: place.discoveryPoints),
              ),

              // ── Tier badge (top-right) ───────────────────────────────────
              Positioned(
                top: 12,
                right: 12,
                child: _TierBadge(tier: place.tier),
              ),

              // ── Bottom content ──────────────────────────────────────────
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: isLarge
                          ? AppTextStyles.title.copyWith(
                              shadows: _textShadow,
                              fontSize: 18,
                            )
                          : AppTextStyles.titleSmall.copyWith(
                              shadows: _textShadow,
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.shortDescription,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withOpacity(0.80),
                        shadows: _textShadow,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Rating
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF59E0B),
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          place.ratingDisplay,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${place.reviewDisplay})',
                          style: AppTextStyles.captionMuted.copyWith(
                            color: Colors.white.withOpacity(0.55),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Duration
                        const Icon(
                          Icons.schedule_rounded,
                          color: Colors.white60,
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          place.estimatedDuration,
                          style: AppTextStyles.captionMuted.copyWith(
                            color: Colors.white.withOpacity(0.60),
                          ),
                        ),
                        const Spacer(),
                        // Add button
                        if (showAddButton)
                          _AddButton(onTap: onAdd ?? onTap),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TpPlaceCardCompact  (horizontal card for nearby list)
// ─────────────────────────────────────────────────────────────────────────────

class TpPlaceCardCompact extends StatelessWidget {
  final ExplorePlace place;
  final VoidCallback onTap;
  final bool showAddButton;
  final VoidCallback? onAdd;

  const TpPlaceCardCompact({
    super.key,
    required this.place,
    required this.onTap,
    this.showAddButton = false,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: context.appColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appColors.divider),
        ),
        child: Row(
          children: [
            // Gradient thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [place.gradientStart, place.gradientEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        place.tier.emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            style: AppTextStyles.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _TierBadge(tier: place.tier, small: true),
                      ],
                    ),
                    Text(
                      place.shortDescription,
                      style: AppTextStyles.captionMuted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF59E0B),
                          size: 12,
                        ),
                        SizedBox(width: 3),
                        Text(
                          place.ratingDisplay,
                          style: AppTextStyles.caption.copyWith(
                            color: context.appColors.textPrimary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.schedule_rounded,
                          color: context.appColors.textMuted,
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          place.estimatedDuration,
                          style: AppTextStyles.captionMuted.copyWith(
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        if (showAddButton)
                          GestureDetector(
                            onTap: onAdd ?? onTap,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.4),
                                ),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────────────────────────────────────

final _textShadow = <Shadow>[
  Shadow(
    color: Colors.black.withOpacity(0.6),
    blurRadius: 6,
    offset: const Offset(0, 1),
  ),
];

class _TierBadge extends StatelessWidget {
  final DiscoveryTier tier;
  final bool small;

  const _TierBadge({required this.tier, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: tier.color.withOpacity(0.20),
        borderRadius: BorderRadius.circular(small ? 6 : 8),
        border: Border.all(color: tier.color.withOpacity(0.50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tier.emoji,
            style: TextStyle(fontSize: small ? 10 : 12),
          ),
          SizedBox(width: small ? 2 : 4),
          Text(
            tier.label,
            style: AppTextStyles.overline.copyWith(
              color: tier.color,
              fontSize: small ? 9 : 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoveryPointsChip extends StatelessWidget {
  final int points;

  const _DiscoveryPointsChip({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✨', style: TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            '+$points pts',
            style: AppTextStyles.overline.copyWith(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.45),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

