// lib/presentation/views/category_detail/category_detail_view.dart

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
      backgroundColor: AppColors.background,
      body: asyncState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
          ),
          backgroundColor: AppColors.background,
          body: Center(child: Text(err.toString(), style: AppTextStyles.body)),
        ),
        data: (state) {
          final filtered = _applyFilter(state.entries, _activeFilter);
          final heroImages = state.entries
              .where((e) => e.place.image.isNotEmpty)
              .take(5)
              .map((e) => e.place.image)
              .toList();

          return CustomScrollView(
            slivers: [
              // ── Hero image carousel ───────────────────────────────────
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: AppColors.background,
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
                        color: AppColors.background.withOpacity(0.75),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: heroImages.isNotEmpty
                      ? _HeroCarousel(images: heroImages)
                      : Container(
                          color: AppColors.surfaceElevated,
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
                      const SizedBox(height: AppSpacing.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                        child: LinearProgressIndicator(
                          value: state.discoveryPercent / 100,
                          minHeight: 6,
                          backgroundColor: AppColors.divider,
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
                            ? null
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
          );
        },
      ),
    );
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
            placeholder: (_, __) => Container(color: AppColors.surfaceElevated),
            errorWidget: (_, __, ___) => Container(
              color: AppColors.surfaceElevated,
              child: const Icon(Icons.image_not_supported_outlined,
                  color: AppColors.textMuted, size: 48),
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
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _current == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _current == i
                        ? AppColors.primary
                        : AppColors.textMuted,
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
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusCard),
                bottomLeft: Radius.circular(AppSpacing.radiusCard),
              ),
              child: CachedNetworkImage(
                imageUrl: place.image,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 88,
                  height: 88,
                  color: AppColors.surfaceElevated,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 88,
                  height: 88,
                  color: AppColors.surfaceElevated,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: AppColors.textMuted, size: 28),
                ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
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
