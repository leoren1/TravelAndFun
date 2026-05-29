// lib/presentation/views/country_detail/country_brands_sheet.dart
//
// Modal bottom sheet that lists all brands originating from a country.
// Opens when the user taps the "Brands" button on CountryDetailView.

import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/data/models/brand.dart';
import 'package:explore_index/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

// ── Industry accent colour ───────────────────────────────────────────────────

Color _industryColor(String industry) => switch (industry) {
      'Automotive'         => const Color(0xFF3B82F6), // blue
      'Fashion & Luxury'   => const Color(0xFFEC4899), // pink
      'Jewelry & Luxury'   => const Color(0xFFD97706), // amber
      'Food & Beverage'    => const Color(0xFFEA580C), // deep orange
      'Technology'         => const Color(0xFF8B5CF6), // violet
      'Aviation'           => const Color(0xFF06B6D4), // cyan
      'Finance'            => const Color(0xFF22C55E), // green
      'Energy'             => const Color(0xFFF59E0B), // yellow
      'Retail'             => const Color(0xFF14B8A6), // teal
      'Electronics'        => const Color(0xFF6366F1), // indigo
      'Beauty & Cosmetics' => const Color(0xFFEF4444), // rose
      'Conglomerate'       => const Color(0xFF64748B), // slate
      'Infrastructure'     => const Color(0xFF0EA5E9), // sky
      _                    => AppColors.primary,
    };

// ── Entry point ──────────────────────────────────────────────────────────────

/// Shows the brands bottom sheet. Call from country detail view.
void showCountryBrandsSheet(
  BuildContext context,
  WidgetRef ref, {
  required String countryId,
  required String countryName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: _CountryBrandsSheet(
        countryId: countryId,
        countryName: countryName,
      ),
    ),
  );
}

// ── Sheet widget ─────────────────────────────────────────────────────────────

class _CountryBrandsSheet extends ConsumerStatefulWidget {
  final String countryId;
  final String countryName;

  const _CountryBrandsSheet({
    required this.countryId,
    required this.countryName,
  });

  @override
  ConsumerState<_CountryBrandsSheet> createState() =>
      _CountryBrandsSheetState();
}

class _CountryBrandsSheetState extends ConsumerState<_CountryBrandsSheet> {
  String _selectedIndustry = 'All';

  @override
  Widget build(BuildContext context) {
    final repo      = ref.read(brandRepositoryProvider);
    final allBrands = repo.getBrandsByCountry(widget.countryId);
    final industries = ['All', ...repo.getIndustriesForCountry(widget.countryId)];

    final shown = _selectedIndustry == 'All'
        ? allBrands
        : allBrands.where((b) => b.industry == _selectedIndustry).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.appColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Drag handle ─────────────────────────────────────────
              SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),

              // ── Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pageHorizontal),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF06B6D4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.storefront_outlined,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.countryName} Markaları',
                            style: AppTextStyles.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${allBrands.length} marka · ${industries.length - 1} sektör',
                            style: AppTextStyles.captionMuted,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: context.appColors.textMuted, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 14),
              Divider(height: 1, color: context.appColors.divider),
              const SizedBox(height: 10),

              // ── Industry filter chips ────────────────────────────────
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageHorizontal),
                  itemCount: industries.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final ind      = industries[i];
                    final selected = ind == _selectedIndustry;
                    final color    = ind == 'All'
                        ? AppColors.primary
                        : _industryColor(ind);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIndustry = ind),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withOpacity(0.15)
                              : context.appColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? color : context.appColors.divider,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          ind,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                            color: selected ? color : context.appColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // ── Brand list ──────────────────────────────────────────
              Expanded(
                child: shown.isEmpty
                    ? Center(
                        child: Text('Bu sektörde marka yok.',
                            style: AppTextStyles.captionMuted),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.pageHorizontal, 4,
                            AppSpacing.pageHorizontal, 40),
                        itemCount: shown.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) => _BrandCard(brand: shown[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Brand card ───────────────────────────────────────────────────────────────

class _BrandCard extends StatelessWidget {
  final Brand brand;
  const _BrandCard({required this.brand});

  @override
  Widget build(BuildContext context) {
    final color = _industryColor(brand.industry);

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left:   BorderSide(color: color, width: 3),
          right:  BorderSide(color: context.appColors.divider),
          top:    BorderSide(color: context.appColors.divider),
          bottom: BorderSide(color: context.appColors.divider),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji icon circle
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(brand.industryEmoji,
                  style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + global badge
                Row(
                  children: [
                    Expanded(
                      child: Text(brand.name,
                          style: AppTextStyles.bodyMedium),
                    ),
                    if (brand.isGlobal)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Global',
                          style: AppTextStyles.overline
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),

                // Industry + founded year
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        brand.industry,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Est. ${brand.foundedYear}',
                      style: AppTextStyles.overline,
                    ),
                  ],
                ),
                SizedBox(height: 6),

                // Description
                Text(
                  brand.description,
                  style: AppTextStyles.caption
                      .copyWith(color: context.appColors.textSecondary),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


