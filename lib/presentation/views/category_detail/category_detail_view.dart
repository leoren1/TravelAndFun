// lib/presentation/views/category_detail/category_detail_view.dart

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/core/router/app_routes.dart';
import 'package:explore_index/data/models/category.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/presentation/viewmodels/category_detail_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

// Filter options for place list.
enum _PlaceFilter { all, mustVisit, hidden, local, completed }

class CategoryDetailView extends ConsumerStatefulWidget {
  final String cityId;
  final String categoryName;
  const CategoryDetailView({
    super.key,
    required this.cityId,
    required this.categoryName,
  });

  @override
  ConsumerState<CategoryDetailView> createState() => _CategoryDetailViewState();
}

class _CategoryDetailViewState extends ConsumerState<CategoryDetailView> {
  _PlaceFilter _activeFilter = _PlaceFilter.all;

  List<PlaceDiscoveryEntry> _applyFilter(
    List<PlaceDiscoveryEntry> entries,
    _PlaceFilter filter,
  ) {
    return switch (filter) {
      _PlaceFilter.all => entries,
      _PlaceFilter.mustVisit =>
        entries.where((e) => e.place.tags.contains(PlaceTag.mustVisit)).toList(),
      _PlaceFilter.hidden =>
        entries.where((e) => e.place.tags.contains(PlaceTag.hidden)).toList(),
      _PlaceFilter.local =>
        entries.where((e) => e.place.tags.contains(PlaceTag.local)).toList(),
      _PlaceFilter.completed => entries.where((e) => e.isVerified).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final params = CategoryDetailParams(
      cityId: widget.cityId,
      categoryName: widget.categoryName,
    );
    final asyncState = ref.watch(categoryDetailViewModelProvider(params));

    return Scaffold(
      backgroundColor: context.appColors.background,
      body: asyncState.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Scaffold(
          appBar: AppBar(
            backgroundColor: context.appColors.background,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: context.appColors.textPrimary),
              onPressed: () => context.pop(),
            ),
          ),
          backgroundColor: context.appColors.background,
          body: Center(child: Text(err.toString(), style: AppTextStyles.body)),
        ),
        data: (state) {
          final filtered = _applyFilter(state.entries, _activeFilter);
          final heroImages = state.entries
              .where((e) => e.place.image.isNotEmpty)
              .take(5)
              .map((e) => e.place.image)
              .toList();

          return SafeArea(
            top: false,
            bottom: true,
            child: CustomScrollView(
              slivers: [
              // ── Hero image carousel ───────────────────────────────────
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: context.appColors.background,
                elevation: 0,
                automaticallyImplyLeading: false,
                leading: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: context.appColors.background.withOpacity(0.75),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: context.appColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: heroImages.isNotEmpty
                      ? _HeroCarousel(images: heroImages)
                      : Container(
                          color: context.appColors.surfaceElevated,
                          alignment: Alignment.center,
                          child: Text(
                            state.category.icon,
                            style: const TextStyle(fontSize: 64),
                          ),
                        ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pageHorizontal,
                    vertical: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title + completion ────────────────────────────
                      Row(
                        children: [
                          Text(
                            state.category.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              state.category.displayName,
                              style: AppTextStyles.title,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${state.verifiedCount}/${state.totalCount} completed '
                        '· ${state.discoveryPercent.toStringAsFixed(0)}%',
                        style: AppTextStyles.captionMuted,
                      ),
                      SizedBox(height: AppSpacing.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                        child: LinearProgressIndicator(
                          value: state.discoveryPercent / 100,
                          minHeight: 6,
                          backgroundColor: context.appColors.divider,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // ── Filter chips ──────────────────────────────────
                      _FilterChipGroup(
                        selected: _activeFilter,
                        onSelected: (f) => setState(() => _activeFilter = f),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),

              // ── Place list ────────────────────────────────────────────
              if (filtered.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: Center(
                      child: Text(
                        'No places match this filter.',
                        style: AppTextStyles.captionMuted,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pageHorizontal,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _PlaceCard(
                        entry: filtered[index],
                        onTap: filtered[index].isVerified
                            ? () => _showVisitDetailSheet(context, filtered[index])
                            : () => context.push(
                                  AppRoutes.verifyVisitPath(filtered[index].place.id),
                                ),
                      ),
                      childCount: filtered.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
            ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Verified-place detail bottom sheet
  // ---------------------------------------------------------------------------

  void _showVisitDetailSheet(BuildContext context, PlaceDiscoveryEntry entry) {
    final visit = entry.latestVisit;
    final place = entry.place;
    final hasUserPhoto = visit != null &&
        visit.photoPath.isNotEmpty &&
        !visit.photoPath.startsWith('/demo/');

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusCard)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollController) => SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: EdgeInsets.only(top: AppSpacing.md),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.appColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Photo
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: hasUserPhoto
                      ? Image.file(
                          File(visit!.photoPath),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _stockImage(place.image),
                        )
                      : _stockImage(place.image),
                ),

                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Place name + verified badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(place.name, style: AppTextStyles.title),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusChip),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified,
                                    color: AppColors.success, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: AppTextStyles.overline.copyWith(
                                      color: AppColors.success),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (place.description.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(place.description, style: AppTextStyles.captionMuted),
                      ],

                      if (visit != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        const Divider(),
                        const SizedBox(height: AppSpacing.md),

                        // Visit metadata
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                color: context.appColors.textMuted, size: 14),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              _formatDate(visit.visitedAt),
                              style: AppTextStyles.captionMuted,
                            ),
                            const Spacer(),
                            // Stars
                            ...List.generate(
                              5,
                              (i) => Icon(
                                i < visit.rating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: i < visit.rating
                                    ? AppColors.warning
                                    : context.appColors.textMuted,
                                size: 16,
                              ),
                            ),
                          ],
                        ),

                        if (visit.note != null && visit.note!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: context.appColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSmall),
                            ),
                            child: Text(
                              '"${visit.note!}"',
                              style: AppTextStyles.body.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],

                        if (hasUserPhoto) ...[
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              const Icon(Icons.camera_alt,
                                  color: AppColors.primary, size: 14),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'Your verified photo',
                                style: AppTextStyles.captionMuted.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stockImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (_, __) =>
          Container(color: context.appColors.surfaceElevated),
      errorWidget: (_, __, ___) => Container(
        color: context.appColors.surfaceElevated,
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported_outlined,
            color: context.appColors.textMuted, size: 48),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
}

// ---------------------------------------------------------------------------
// Hero Carousel
// ---------------------------------------------------------------------------

class _HeroCarousel extends StatefulWidget {
  final List<String> images;
  const _HeroCarousel({required this.images});

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (context, index) => CachedNetworkImage(
            imageUrl: widget.images[index],
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: context.appColors.surfaceElevated),
            errorWidget: (_, __, ___) => Container(
              color: context.appColors.surfaceElevated,
              child: Icon(Icons.image_not_supported_outlined,
                  color: context.appColors.textMuted, size: 48),
            ),
          ),
        ),
        if (widget.images.length > 1)
          Positioned(
            bottom: AppSpacing.md,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: 3),
                  width: _current == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _current == i
                        ? AppColors.primary
                        : context.appColors.textMuted,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Chip Group
// ---------------------------------------------------------------------------

class _FilterChipGroup extends StatelessWidget {
  final _PlaceFilter selected;
  final ValueChanged<_PlaceFilter> onSelected;
  const _FilterChipGroup({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const filters = [
      (_PlaceFilter.all, 'All'),
      (_PlaceFilter.mustVisit, 'Must Visit'),
      (_PlaceFilter.hidden, 'Hidden'),
      (_PlaceFilter.local, 'Local'),
      (_PlaceFilter.completed, 'Completed'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((entry) {
          final (filter, label) = entry;
          final isSelected = selected == filter;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => onSelected(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : context.appColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : context.appColors.divider,
                  ),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected
                        ? context.appColors.textPrimary
                        : context.appColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Place Card
// ---------------------------------------------------------------------------

class _PlaceCard extends StatelessWidget {
  final PlaceDiscoveryEntry entry;
  final VoidCallback? onTap;
  const _PlaceCard({required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final place = entry.place;
    final hasUserPhoto = entry.isVerified &&
        entry.latestVisit?.photoPath != null &&
        entry.latestVisit!.photoPath.isNotEmpty &&
        !entry.latestVisit!.photoPath.startsWith('/demo/');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: context.appColors.divider),
        ),
        child: Row(
          children: [
            // Image — shows user's real photo if available, else place stock image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusCard),
                bottomLeft: Radius.circular(AppSpacing.radiusCard),
              ),
              child: Stack(
                children: [
                  if (hasUserPhoto)
                    Image.file(
                      File(entry.latestVisit!.photoPath),
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => CachedNetworkImage(
                        imageUrl: place.image,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 88,
                          height: 88,
                          color: context.appColors.surfaceElevated,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 88,
                          height: 88,
                          color: context.appColors.surfaceElevated,
                          alignment: Alignment.center,
                          child: Icon(Icons.image_not_supported_outlined,
                              color: context.appColors.textMuted, size: 28),
                        ),
                      ),
                    )
                  else
                    CachedNetworkImage(
                      imageUrl: place.image,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 88,
                        height: 88,
                        color: context.appColors.surfaceElevated,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 88,
                        height: 88,
                        color: context.appColors.surfaceElevated,
                        alignment: Alignment.center,
                        child: Icon(Icons.image_not_supported_outlined,
                            color: context.appColors.textMuted, size: 28),
                      ),
                    ),
                  // Camera icon badge for user photos
                  if (hasUserPhoto)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.camera_alt,
                          color: context.appColors.textPrimary,
                          size: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        if (entry.isVerified)
                          const Icon(Icons.check_circle,
                              color: AppColors.success, size: 16)
                        else if (onTap != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusChip),
                            ),
                            child: Text(
                              'Verify',
                              style: AppTextStyles.overline
                                  .copyWith(color: AppColors.primary),
                            ),
                          ),
                      ],
                    ),
                    if (place.description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        place.description,
                        style: AppTextStyles.captionMuted,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    // Tags
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: place.tags.map((tag) {
                        final label = switch (tag) {
                          PlaceTag.mustVisit => '⭐ Must Visit',
                          PlaceTag.hidden => '💎 Hidden',
                          PlaceTag.local => '🏠 Local',
                        };
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.appColors.surfaceElevated,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusChip),
                          ),
                          child: Text(label, style: AppTextStyles.overline),
                        );
                      }).toList(),
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


