// Schedule timeline tile widget.
// Renders a single ScheduleSlot as a rich timeline entry with:
//   • A coloured left-accent bar (gradients from the place).
//   • Time range and duration display.
//   • Category emoji + place name + city / country context.
//   • Swipe-to-delete dismiss gesture.
import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/features/trip_planner/data/models/schedule_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

class TpScheduleTile extends StatefulWidget {
  final ScheduleSlot slot;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  /// Compact single-line mode for dense lists.
  final bool isCompact;

  const TpScheduleTile({
    super.key,
    required this.slot,
    required this.onTap,
    this.onDelete,
    this.isCompact = false,
  });

  @override
  State<TpScheduleTile> createState() => _TpScheduleTileState();
}

class _TpScheduleTileState extends State<TpScheduleTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tile = _buildTile();

    if (widget.onDelete != null) {
      return Dismissible(
        key: ValueKey(widget.slot.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) {
          HapticFeedback.mediumImpact();
          widget.onDelete!();
        },
        background: _buildSwipeBackground(),
        child: tile,
      );
    }

    return tile;
  }

  Widget _buildTile() {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.isCompact ? _compactContent() : _fullContent(),
      ),
    );
  }

  // ── Full tile ───────────────────────────────────────────────────────────────

  Widget _fullContent() {
    final slot = widget.slot;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.divider),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left accent bar (gradient) ─────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [slot.gradientStart, slot.gradientEnd],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // ── Time column ────────────────────────────────────────────────
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    slot.startDisplay,
                    style: AppTextStyles.caption.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (slot.endTime != null) ...[
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      width: 1,
                      height: 14,
                      color: context.appColors.divider,
                    ),
                    Text(
                      slot.endDisplay,
                      style: AppTextStyles.captionMuted.copyWith(
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Vertical divider
            Container(
              width: 1,
              color: context.appColors.divider,
              margin: const EdgeInsets.symmetric(vertical: 12),
            ),

            // ── Main content ───────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          slot.categoryEmoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            slot.placeName,
                            style: AppTextStyles.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: context.appColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${slot.cityName}, ${slot.countryName}',
                            style: AppTextStyles.captionMuted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (slot.notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: context.appColors.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.wb_sunny_rounded,
                              size: 11,
                              color: AppColors.warning,
                            ),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                slot.notes,
                                style: AppTextStyles.overline.copyWith(
                                  color: context.appColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Duration chip (right side) ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DurationChip(
                    duration: slot.durationDisplay,
                    color: slot.gradientStart,
                  ),
                  if (widget.onDelete != null) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.onDelete!();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 14,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Compact tile ─────────────────────────────────────────────────────────────

  Widget _compactContent() {
    final slot = widget.slot;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 3),
      height: 56,
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Row(
        children: [
          // Accent bar
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12),
            ),
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [slot.gradientStart, slot.gradientEnd],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              slot.categoryEmoji,
              style: const TextStyle(fontSize: 18),
            ),
          ),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.placeName,
                  style: AppTextStyles.caption.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  slot.startDisplay +
                      (slot.endTime != null ? ' – ${slot.endDisplay}' : ''),
                  style: AppTextStyles.captionMuted.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _DurationChip(
              duration: slot.durationDisplay,
              color: slot.gradientStart,
              small: true,
            ),
          ),
        ],
      ),
    );
  }

  // ── Swipe background ─────────────────────────────────────────────────────────

  Widget _buildSwipeBackground() {
    return Container(
      alignment: Alignment.centerRight,
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.delete_sweep_rounded,
            color: AppColors.danger,
            size: 22,
          ),
          const SizedBox(width: 6),
          Text(
            'Remove',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: duration chip
// ─────────────────────────────────────────────────────────────────────────────

class _DurationChip extends StatelessWidget {
  final String duration;
  final Color color;
  final bool small;

  const _DurationChip({
    required this.duration,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        duration,
        style: AppTextStyles.overline.copyWith(
          color: color,
          fontSize: small ? 9 : 10,
        ),
      ),
    );
  }
}

