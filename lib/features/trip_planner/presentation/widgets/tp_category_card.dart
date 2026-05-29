// Category cards and chips used on the City Discovery page.
//
//  • TpCategoryCard  — full card with emoji, label, place count and selection glow.
//  • TpCategoryChip  — compact inline pill for horizontal filter rows.
import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/features/trip_planner/data/models/explore_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TpCategoryCard
// ─────────────────────────────────────────────────────────────────────────────

class TpCategoryCard extends StatefulWidget {
  final ExploreCategory category;
  final int placeCount;
  final bool isSelected;
  final VoidCallback onTap;

  const TpCategoryCard({
    super.key,
    required this.category,
    required this.placeCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<TpCategoryCard> createState() => _TpCategoryCardState();
}

class _TpCategoryCardState extends State<TpCategoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    _controller.reverse();
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.category.accent;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: 100,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? accent.withOpacity(0.15)
                : context.appColors.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.isSelected
                  ? accent.withOpacity(0.70)
                  : context.appColors.divider,
              width: widget.isSelected ? 1.5 : 1.0,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.30),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji in a tinted circle
              AnimatedContainer(
                duration: Duration(milliseconds: 250),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? accent.withOpacity(0.22)
                      : context.appColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isSelected
                        ? accent.withOpacity(0.50)
                        : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.category.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text(
                widget.category.label,
                style: AppTextStyles.caption.copyWith(
                  color: widget.isSelected ? accent : context.appColors.textSecondary,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                '${widget.placeCount} place${widget.placeCount != 1 ? 's' : ''}',
                style: AppTextStyles.overline.copyWith(
                  color: widget.isSelected
                      ? accent.withOpacity(0.80)
                      : context.appColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TpCategoryChip  (compact pill for horizontal filter rows)
// ─────────────────────────────────────────────────────────────────────────────

class TpCategoryChip extends StatelessWidget {
  final ExploreCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  /// When true the place-count badge is hidden.
  final bool hideCount;
  final int placeCount;

  const TpCategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
    this.hideCount = false,
    this.placeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final accent = category.accent;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accent.withOpacity(0.18) : context.appColors.surfaceElevated,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? accent.withOpacity(0.65) : context.appColors.divider,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : const [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category.emoji,
              style: const TextStyle(fontSize: 14),
            ),
            SizedBox(width: 6),
            Text(
              category.label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? accent : context.appColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (!hideCount && placeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accent.withOpacity(0.25)
                      : context.appColors.surface,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  '$placeCount',
                  style: AppTextStyles.overline.copyWith(
                    color: isSelected ? accent : context.appColors.textMuted,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

