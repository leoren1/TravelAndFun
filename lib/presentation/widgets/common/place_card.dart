import 'package:cached_network_image/cached_network_image.dart';
import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:flutter/material.dart';

class PlaceCard extends StatelessWidget {
  final Place place;
  final bool isVerified;
  final int? userRating;
  final VoidCallback? onTap;

  const PlaceCard({
    super.key,
    required this.place,
    required this.isVerified,
    this.userRating,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              child: CachedNetworkImage(
                imageUrl: place.image,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: AppColors.surfaceElevated,
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.description,
                    style: AppTextStyles.captionMuted,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _VerificationBadge(isVerified: isVerified),
                      if (userRating != null) ...[
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < userRating! ? Icons.star : Icons.star_border,
                              size: 12,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _TagChip(tags: place.tags),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${place.discoveryBoost.toStringAsFixed(0)}%',
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.success),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  final bool isVerified;
  const _VerificationBadge({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isVerified
            ? AppColors.success.withOpacity(0.15)
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isVerified
              ? AppColors.success.withOpacity(0.5)
              : AppColors.divider,
        ),
      ),
      child: Text(
        isVerified ? 'Verified' : 'Not Verified',
        style: AppTextStyles.captionMuted.copyWith(
          color: isVerified ? AppColors.success : AppColors.textMuted,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final List<PlaceTag> tags;
  const _TagChip({required this.tags});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final tag = tags.first;
    final (label, color) = switch (tag) {
      PlaceTag.mustVisit => ('Must Visit', AppColors.primary),
      PlaceTag.hidden => ('Hidden', AppColors.warning),
      PlaceTag.local => ('Local', AppColors.success),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
