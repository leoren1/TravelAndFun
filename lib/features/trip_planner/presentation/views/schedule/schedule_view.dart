// ScheduleView — visual day-planner timeline.
// Cinematic dark theme with purple-accent gradient items, hour grid, and
// smooth scroll-sync between the time axis and the slot canvas.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/data/models/trip_plan.dart';
import 'package:explore_index/data/providers.dart';
import 'package:explore_index/features/trip_planner/data/models/itinerary.dart';
import 'package:explore_index/features/trip_planner/data/models/schedule_slot.dart';
import 'package:explore_index/features/trip_planner/presentation/providers/explore_providers.dart';
import 'package:explore_index/features/trip_planner/presentation/widgets/tp_glass_card.dart';
import 'package:explore_index/core/router/app_routes.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Root widget
// ─────────────────────────────────────────────────────────────────────────────

class ScheduleView extends ConsumerWidget {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scheduleProvider);
    final activeItinerary = state.activeItinerary;

    return Scaffold(
      backgroundColor: context.appColors.background,
      body: Column(
        children: [
          // Header
          _ScheduleHeader(
            itineraries: state.itineraries,
            activeItinerary: activeItinerary,
          ),

          // Itinerary selector (when multiple)
          if (state.itineraries.length > 1)
            _ItinerarySelector(state: state),

          // Body
          if (state.itineraries.isEmpty)
            const Expanded(child: _EmptyScheduleState())
          else ...[
            if (activeItinerary != null) ...[
              _DaySelector(
                itinerary: activeItinerary,
                selectedDayIndex: state.selectedDayIndex,
              ),
              Expanded(
                child: _TimelineView(
                  itinerary: activeItinerary,
                  selectedDayIndex: state.selectedDayIndex,
                ),
              ),
            ] else
              const Expanded(child: _EmptyScheduleState()),
            _AddPlaceBar(),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Schedule header
// ─────────────────────────────────────────────────────────────────────────────

class _ScheduleHeader extends ConsumerWidget {
  final List<Itinerary> itineraries;
  final Itinerary? activeItinerary;

  const _ScheduleHeader({
    required this.itineraries,
    required this.activeItinerary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = itineraries.isEmpty
        ? 'Add your first trip'
        : '${itineraries.length} trip${itineraries.length == 1 ? '' : 's'} planned';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Schedule', style: AppTextStyles.display),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.captionMuted,
                ),
              ],
            ),
            const Spacer(),
            // Save to Plans (only visible when there's an active itinerary)
            if (activeItinerary != null) ...[
              GestureDetector(
                onTap: () => _saveToPlans(context, ref, activeItinerary!),
                child: TpGlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  borderRadius: BorderRadius.circular(14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bookmark_add_outlined,
                          color: AppColors.success, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Save Plan',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            GestureDetector(
              onTap: () => _showCreateItinerarySheet(context, ref),
              child: TpGlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                borderRadius: BorderRadius.circular(14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'New Trip',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
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

  void _showCreateItinerarySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateItinerarySheet(ref: ref),
    );
  }

  /// Saves the active itinerary as one TripPlan per unique city in its slots.
  Future<void> _saveToPlans(
      BuildContext context, WidgetRef ref, Itinerary itinerary) async {
    // Group slots by cityId to create one TripPlan per city.
    final byCityId = <String, List<ScheduleSlot>>{};
    for (final slot in itinerary.slots) {
      byCityId.putIfAbsent(slot.cityId, () => []).add(slot);
    }

    if (byCityId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No places scheduled yet.')),
        );
      }
      return;
    }

    final repo = ref.read(tripPlanRepositoryProvider);
    int saved = 0;

    for (final entry in byCityId.entries) {
      final cSlots = entry.value..sort((a, b) => a.date.compareTo(b.date));
      final plan = TripPlan(
        id: 'plan_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
        cityId: entry.key,
        cityName: cSlots.first.cityName,
        countryId: itinerary.countryId,
        plannedDate: cSlots.first.date,
        placeIds: cSlots.map((s) => s.placeId).toSet().toList(),
        currentDiscovery: 0.0,
        projectedDiscovery: 0.0,
        status: TripPlanStatus.planned,
        createdAt: DateTime.now(),
      );
      await repo.savePlan(plan);
      saved++;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved == 1
                ? '✅ Trip plan saved!'
                : '✅ $saved trip plans saved!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Itinerary selector row (shown when multiple itineraries exist)
// ─────────────────────────────────────────────────────────────────────────────

class _ItinerarySelector extends ConsumerWidget {
  final ScheduleState state;
  _ItinerarySelector({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 48,
      color: context.appColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: state.itineraries.length,
        itemBuilder: (ctx, i) {
          final itin = state.itineraries[i];
          final isActive = itin.id == state.activeItineraryId;
          return GestureDetector(
            onTap: () =>
                ref.read(scheduleProvider.notifier).setActiveItinerary(itin.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : context.appColors.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: isActive
                    ? null
                    : Border.all(color: context.appColors.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    itin.countryFlag,
                    style: const TextStyle(fontSize: 12),
                  ),
                  SizedBox(width: 4),
                  Text(
                    itin.title,
                    style: AppTextStyles.caption.copyWith(
                      color: isActive
                          ? Colors.white
                          : context.appColors.textSecondary,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day selector strip
// ─────────────────────────────────────────────────────────────────────────────

class _DaySelector extends ConsumerWidget {
  final Itinerary itinerary;
  final int selectedDayIndex;

  const _DaySelector({
    required this.itinerary,
    required this.selectedDayIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 80,
      color: context.appColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: itinerary.totalDays,
        itemBuilder: (ctx, i) {
          final day = itinerary.days[i];
          final isSelected = i == selectedDayIndex;
          final slotsCount = itinerary.slotsForDay(day).length;

          return GestureDetector(
            onTap: () =>
                ref.read(scheduleProvider.notifier).selectDay(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : context.appColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: isSelected
                    ? null
                    : Border.all(color: context.appColors.divider),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(day).toUpperCase(),
                    style: AppTextStyles.overline.copyWith(
                      color: isSelected
                          ? Colors.white
                          : context.appColors.textMuted,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    day.day.toString(),
                    style: AppTextStyles.titleSmall.copyWith(
                      color: isSelected
                          ? Colors.white
                          : context.appColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (slotsCount > 0)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Colors.white.withOpacity(0.6)
                            : AppColors.primary,
                      ),
                    )
                  else
                    const SizedBox(height: 6),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timeline view — the cinematic hour grid + placed slots
// ─────────────────────────────────────────────────────────────────────────────

class _TimelineView extends StatefulWidget {
  final Itinerary itinerary;
  final int selectedDayIndex;

  const _TimelineView({
    required this.itinerary,
    required this.selectedDayIndex,
  });

  @override
  State<_TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<_TimelineView> {
  final ScrollController _scrollController = ScrollController();

  static const double _hourHeight = 60.0;
  static const int _startHour = 6;
  static const int _endHour = 23;
  static const int _totalHours = _endHour - _startHour; // 17
  static const double _timeAxisWidth = 60.0;
  static const double _bottomPad = 40.0;

  @override
  void initState() {
    super.initState();
    // Scroll to 8 AM on first render (offset: 2 hours from start)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(2 * _hourHeight);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = widget.itinerary.days[
        widget.selectedDayIndex.clamp(0, widget.itinerary.totalDays - 1)];
    final daySlots = widget.itinerary.slotsForDay(selectedDay);
    final totalHeight = _totalHours * _hourHeight + _bottomPad;

    return SingleChildScrollView(
      controller: _scrollController,
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          children: [
            // ── Hour lines (full width) ──────────────────────────────────────
            for (int hour = _startHour; hour <= _endHour; hour++)
              Positioned(
                top: (hour - _startHour) * _hourHeight,
                left: 0,
                right: 0,
                child: _HourLine(hour: hour),
              ),

            // ── Placed schedule items ────────────────────────────────────────
            for (final slot in daySlots)
              Positioned(
                top: _topForSlot(slot),
                left: _timeAxisWidth + 4,
                right: 16,
                height: math.max(
                  slot.durationMinutes.toDouble(),
                  48,
                ),
                child: _ScheduleItem(slot: slot),
              ),

            // ── Time-axis labels (left column) ───────────────────────────────
            // Rendered on top so they're always readable
            for (int hour = _startHour; hour <= _endHour; hour++)
              Positioned(
                top: (hour - _startHour) * _hourHeight,
                left: 0,
                width: _timeAxisWidth,
                height: _hourHeight,
                child: _TimeLabel(hour: hour),
              ),
          ],
        ),
      ),
    );
  }

  double _topForSlot(ScheduleSlot slot) {
    final hourOffset = slot.startTime.hour - _startHour;
    return hourOffset * _hourHeight + slot.startTime.minute.toDouble();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hour line
// ─────────────────────────────────────────────────────────────────────────────

class _HourLine extends StatelessWidget {
  final int hour;
  const _HourLine({required this.hour});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 60), // time-axis width
        Expanded(
          child: Container(
            height: 1,
            color: context.appColors.divider.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Time label (left axis)
// ─────────────────────────────────────────────────────────────────────────────

class _TimeLabel extends StatelessWidget {
  final int hour;
  const _TimeLabel({required this.hour});

  @override
  Widget build(BuildContext context) {
    final String label;
    if (hour == 12) {
      label = '12 PM';
    } else if (hour > 12) {
      label = '${hour - 12} PM';
    } else {
      label = '$hour AM';
    }

    return Container(
      width: 60,
      padding: const EdgeInsets.only(left: 12),
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          label,
          style: AppTextStyles.captionMuted.copyWith(fontSize: 10),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Schedule item card (stateful for long-press delete handle)
// ─────────────────────────────────────────────────────────────────────────────

class _ScheduleItem extends ConsumerStatefulWidget {
  final ScheduleSlot slot;
  const _ScheduleItem({required this.slot});

  @override
  ConsumerState<_ScheduleItem> createState() => _ScheduleItemState();
}

class _ScheduleItemState extends ConsumerState<_ScheduleItem> {
  bool _isLongPressed = false;

  void _showSlotDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SlotDetailSheet(slot: widget.slot),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove from schedule?',
          style: AppTextStyles.titleSmall,
        ),
        content: Text(
          'Remove "${widget.slot.placeName}" from this day?',
          style: AppTextStyles.body.copyWith(color: context.appColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.caption.copyWith(color: context.appColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(scheduleProvider.notifier)
                  .removeSlot(widget.slot.id);
            },
            child: Text(
              'Remove',
              style: AppTextStyles.caption.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    setState(() => _isLongPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final slotHeight = math.max(
      widget.slot.durationMinutes.toDouble(),
      48.0,
    );

    return GestureDetector(
      onTap: () {
        if (_isLongPressed) {
          setState(() => _isLongPressed = false);
        } else {
          _showSlotDetail(context);
        }
      },
      onLongPress: () {
        setState(() => _isLongPressed = true);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.slot.gradientStart, widget.slot.gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: widget.slot.gradientStart.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.slot.categoryEmoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          widget.slot.placeName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (slotHeight > 48) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${widget.slot.startDisplay} – ${widget.slot.endDisplay}',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                  if (slotHeight > 72) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.slot.durationDisplay,
                      style: AppTextStyles.captionMuted.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Delete button (shown on long press)
            if (_isLongPressed)
              Positioned(
                right: 4,
                top: 4,
                child: GestureDetector(
                  onTap: () => _confirmDelete(context),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: context.appColors.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.appColors.divider,
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: context.appColors.textPrimary,
                      size: 14,
                    ),
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
// Slot detail sheet
// ─────────────────────────────────────────────────────────────────────────────

class _SlotDetailSheet extends StatelessWidget {
  final ScheduleSlot slot;
  const _SlotDetailSheet({required this.slot});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gradient header
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [slot.gradientStart, slot.gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    slot.categoryEmoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          slot.placeName,
                          style: AppTextStyles.title.copyWith(
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${slot.cityName}, ${slot.countryName}',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'Time',
                  value:
                      '${slot.startDisplay}${slot.endTime != null ? ' – ${slot.endDisplay}' : ''}',
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value: slot.durationDisplay,
                ),
                if (slot.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.notes_rounded,
                    label: 'Notes',
                    value: slot.notes,
                  ),
                ],
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: context.appColors.surfaceElevated,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Close',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: context.appColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.captionMuted,
              ),
              Text(
                value,
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty schedule state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyScheduleState extends StatelessWidget {
  const _EmptyScheduleState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: AppColors.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No trips scheduled yet',
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Add places to your schedule\nor use Auto Suggest to create a trip',
              style: AppTextStyles.body.copyWith(color: context.appColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _PrimaryButton(
              label: '✦ Auto Suggest',
              onPressed: () => context.push(AppRoutes.autoSuggest),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: () => context.push(AppRoutes.tripPlanner),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.appColors.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Browse Destinations',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: context.appColors.textSecondary,
                  ),
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
// Add place bar (bottom)
// ─────────────────────────────────────────────────────────────────────────────

class _AddPlaceBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomPadding),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        border: Border(
          top: BorderSide(color: context.appColors.divider),
        ),
      ),
      child: Row(
        children: [
          // Browse places button
          Expanded(
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.tripPlanner),
              child: TpGlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                borderRadius: BorderRadius.circular(14),
                child: Row(
                  children: [
                    const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Add a place',
                      style: AppTextStyles.body.copyWith(
                        color: context.appColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Auto-suggest button
          GestureDetector(
            onTap: () => context.push(AppRoutes.autoSuggest),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Suggest',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Create Itinerary bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CreateItinerarySheet extends StatefulWidget {
  final WidgetRef ref;
  const _CreateItinerarySheet({required this.ref});

  @override
  State<_CreateItinerarySheet> createState() => _CreateItinerarySheetState();
}

class _CreateItinerarySheetState extends State<_CreateItinerarySheet> {
  final _titleController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked.add(const Duration(days: 7));
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final firstDate = _startDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: firstDate.add(const Duration(days: 7)),
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 730)),
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Widget _datePickerTheme(BuildContext ctx, Widget? child) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          surface: context.appColors.surfaceElevated,
        ),
      ),
      child: child!,
    );
  }

  void _createItinerary() {
    final title = _titleController.text.trim();
    if (title.isEmpty || _startDate == null || _endDate == null) return;

    final itinerary = Itinerary(
      id: 'itin_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      countryId: '',
      countryName: 'My Trip',
      countryFlag: '✈️',
      cityIds: const [],
      startDate: _startDate!,
      endDate: _endDate!,
      slots: const [],
      isAutoGenerated: false,
    );

    widget.ref.read(scheduleProvider.notifier).createItinerary(itinerary);
    Navigator.of(context).pop();
  }

  bool get _canCreate =>
      _titleController.text.trim().isNotEmpty &&
      _startDate != null &&
      _endDate != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.appColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Trip', style: AppTextStyles.title),
                const SizedBox(height: 4),
                Text(
                  'Name your adventure',
                  style: AppTextStyles.captionMuted,
                ),
                const SizedBox(height: 20),

                // Title field
                TextField(
                  controller: _titleController,
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: 'e.g. Paris Escape, Japan Adventure…',
                    hintStyle: AppTextStyles.body
                        .copyWith(color: context.appColors.textMuted),
                    filled: true,
                    fillColor: context.appColors.surfaceElevated,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: context.appColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: context.appColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Dates row
                Row(
                  children: [
                    Expanded(
                      child: _DatePickerTile(
                        icon: Icons.flight_takeoff_rounded,
                        label: 'Departure',
                        value: _startDate != null
                            ? DateFormat('MMM d, yyyy').format(_startDate!)
                            : null,
                        onTap: _pickStartDate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DatePickerTile(
                        icon: Icons.flight_land_rounded,
                        label: 'Return',
                        value: _endDate != null
                            ? DateFormat('MMM d, yyyy').format(_endDate!)
                            : null,
                        onTap: _pickEndDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Create button
                _PrimaryButton(
                  label: 'Create Trip',
                  onPressed: _canCreate ? _createItinerary : null,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _DatePickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: context.appColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.appColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 14),
                const SizedBox(width: 4),
                Text(label, style: AppTextStyles.captionMuted),
              ],
            ),
            SizedBox(height: 4),
            Text(
              value ?? 'Select date',
              style: AppTextStyles.bodyMedium.copyWith(
                color: value != null
                    ? context.appColors.textPrimary
                    : context.appColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared primary button
// ─────────────────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _PrimaryButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isEnabled
              ? LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isEnabled ? null : context.appColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.titleSmall.copyWith(
              color: isEnabled ? Colors.white : context.appColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}


