// lib/presentation/views/mode_selector/mode_selector_sheet.dart
//
// Travel Mode selector bottom sheet.
// Call [showModeSelectorSheet] from any screen.

import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/data/models/travel_mode.dart';
import 'package:explore_index/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

void showModeSelectorSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _ModeSelectorSheet(),
  );
}

class _ModeSelectorSheet extends ConsumerWidget {
  const _ModeSelectorSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(travelModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusHero),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
        MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.appColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Header
          Row(
            children: [
              const Icon(Icons.tune_outlined,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Text('Travel Mode', style: AppTextStyles.title),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your mode changes which cities and places\ncount toward your discovery percentage.',
            style: AppTextStyles.captionMuted,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Mode cards
          ...TravelMode.values.map((mode) => _ModeCard(
                mode: mode,
                isActive: mode == currentMode,
                onTap: () {
                  ref.read(travelModeProvider.notifier).setMode(mode);
                  Navigator.of(context).pop();
                },
              )),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final TravelMode mode;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final modeColor = mode.color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isActive
              ? modeColor.withOpacity(0.12)
              : context.appColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(
            color: isActive ? modeColor : context.appColors.divider,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Emoji badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: modeColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                mode.emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mode.displayName, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    mode.description,
                    style: AppTextStyles.captionMuted,
                  ),
                ],
              ),
            ),

            // Active indicator
            if (isActive) ...[
              const SizedBox(width: AppSpacing.md),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: modeColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inline mode badge widget — use in AppBar actions
// ---------------------------------------------------------------------------

class ModeBadge extends ConsumerWidget {
  const ModeBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(travelModeProvider);
    return GestureDetector(
      onTap: () => showModeSelectorSheet(context),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: mode.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
          border: Border.all(color: mode.color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mode.emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              mode.shortName,
              style: AppTextStyles.overline.copyWith(
                color: mode.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

