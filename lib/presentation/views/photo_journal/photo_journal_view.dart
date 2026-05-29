// lib/presentation/views/photo_journal/photo_journal_view.dart

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/data/models/category.dart';
import 'package:explore_index/presentation/viewmodels/photo_journal_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

class PhotoJournalView extends ConsumerWidget {
  const PhotoJournalView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(photoJournalViewModelProvider);

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        titleSpacing: AppSpacing.lg,
        title: const Text('My Journal 📸', style: AppTextStyles.titleSmall),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined,
                color: context.appColors.textSecondary),
            onPressed: () =>
                ref.read(photoJournalViewModelProvider.notifier).refresh(),
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
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(err.toString(), style: AppTextStyles.body),
          ),
        ),
        data: (state) {
          if (state.isEmpty) {
            return _EmptyState(
              onRefresh: () =>
                  ref.read(photoJournalViewModelProvider.notifier).refresh(),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: context.appColors.surfaceElevated,
            onRefresh: () =>
                ref.read(photoJournalViewModelProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
              itemCount: _buildSectionedList(state).length,
              itemBuilder: (context, index) {
                final item = _buildSectionedList(state)[index];
                if (item is String) {
                  // Section header
                  return _MonthHeader(monthYear: item);
                } else {
                  return _JournalCard(entry: item as JournalEntry);
                }
              },
            ),
          );
        },
      ),
    );
  }

  /// Flattens the byMonth map into an alternating list of:
  /// [String (month header), JournalEntry, JournalEntry, ..., String, ...]
  List<Object> _buildSectionedList(PhotoJournalState state) {
    final result = <Object>[];
    for (final entry in state.byMonth.entries) {
      result.add(entry.key); // month header
      result.addAll(entry.value); // entries
    }
    return result;
  }
}

// ---------------------------------------------------------------------------
// Month header
// ---------------------------------------------------------------------------

class _MonthHeader extends StatelessWidget {
  final String monthYear;
  const _MonthHeader({required this.monthYear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.xxl,
        AppSpacing.pageHorizontal,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            monthYear,
            style: AppTextStyles.titleSmall.copyWith(
              color: context.appColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Journal card
// ---------------------------------------------------------------------------

class _JournalCard extends StatelessWidget {
  final JournalEntry entry;
  const _JournalCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: context.appColors.divider),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo area ────────────────────────────────────────────────
            _PhotoArea(entry: entry),

            // ── Metadata row ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: _MetadataRow(entry: entry),
            ),

            // ── Note snippet ──────────────────────────────────────────────
            if (entry.visit.note != null && entry.visit.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Text(
                  entry.visit.note!,
                  style: AppTextStyles.captionMuted,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Photo area with gradient overlay
// ---------------------------------------------------------------------------

class _PhotoArea extends StatelessWidget {
  final JournalEntry entry;
  const _PhotoArea({required this.entry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 280,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background photo
          if (entry.hasUserPhoto)
            Image.file(
              File(entry.userPhotoPath!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _NetworkFallback(entry: entry),
            )
          else
            _NetworkFallback(entry: entry),

          // Bottom gradient overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xxxl,
                AppSpacing.md,
                AppSpacing.md,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xCC000000),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Place name
                  Text(
                    entry.place.name,
                    style: AppTextStyles.title.copyWith(
                      color: Colors.white,
                      shadows: [
                        const Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // City + country flag
                  Row(
                    children: [
                      if (entry.country != null) ...[
                        Text(
                          _flagEmoji(entry.country!.countryCode),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      if (entry.city != null)
                        Flexible(
                          child: Text(
                            entry.country != null
                                ? '${entry.city!.name}, ${entry.country!.name}'
                                : entry.city!.name,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      const Spacer(),
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusChip),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          '${entry.place.category.icon} ${entry.place.category.displayName}',
                          style: AppTextStyles.overline.copyWith(
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // User photo badge (top-right corner)
          if (entry.hasUserPhoto)
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusChip),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt,
                        color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'My photo',
                      style: AppTextStyles.overline.copyWith(
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _flagEmoji(String code) {
    if (code.length != 2) return '';
    const base = 0x1F1E6 - 0x41;
    final chars = code.toUpperCase().codeUnits;
    return String.fromCharCodes([base + chars[0], base + chars[1]]);
  }
}

// ---------------------------------------------------------------------------
// Network fallback image
// ---------------------------------------------------------------------------

class _NetworkFallback extends StatelessWidget {
  final JournalEntry entry;
  const _NetworkFallback({required this.entry});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: entry.displayImageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => Container(
        color: context.appColors.surfaceElevated,
        alignment: Alignment.center,
        child: Text(
          entry.place.category.icon,
          style: TextStyle(fontSize: 48),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        color: context.appColors.surfaceElevated,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.place.category.icon,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(entry.place.name, style: AppTextStyles.captionMuted),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Metadata row (date, rating, verified badge)
// ---------------------------------------------------------------------------

class _MetadataRow extends StatelessWidget {
  final JournalEntry entry;
  const _MetadataRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final visit = entry.visit;
    final date = visit.visitedAt;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')} ${_monthAbbr(date.month)} ${date.year}';

    return Row(
      children: [
        // Date
        Icon(Icons.calendar_today_outlined,
            color: context.appColors.textMuted, size: 13),
        const SizedBox(width: AppSpacing.xs),
        Text(dateStr, style: AppTextStyles.captionMuted),
        const SizedBox(width: AppSpacing.md),
        // Star rating
        ..._starWidgets(visit.rating, context),
        const Spacer(),
        // Verified badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified, color: AppColors.success, size: 11),
              const SizedBox(width: 3),
              Text(
                'Verified',
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _starWidgets(int rating, BuildContext context) {
    return List.generate(5, (i) {
      return Icon(
        i < rating ? Icons.star : Icons.star_border,
        color: i < rating ? AppColors.warning : context.appColors.textMuted,
        size: 14,
      );
    });
  }

  String _monthAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: context.appColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: context.appColors.divider, width: 2),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.photo_library_outlined,
                color: context.appColors.textMuted,
                size: 48,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'No journal entries yet',
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Verify a visit to a place and it will appear here in your photo journal.',
              style: AppTextStyles.captionMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
              ),
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

