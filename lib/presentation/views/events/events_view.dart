// lib/presentation/views/events/events_view.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/data/models/event.dart';
import 'package:explore_index/presentation/viewmodels/events_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EventsView extends ConsumerStatefulWidget {
  final String cityId;
  const EventsView({super.key, required this.cityId});

  @override
  ConsumerState<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends ConsumerState<EventsView> {
  DateTime _selectedDay = DateTime.now();
  bool _showingAll = false;

  /// Returns the Monday of the week containing [date].
  DateTime _weekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  List<DateTime> _weekDays(DateTime date) {
    final start = _weekStart(date);
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  bool _isActiveOnDay(Event event, DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(hours: 23, minutes: 59, seconds: 59));
    return event.startDate.isBefore(dayEnd) && event.endDate.isAfter(dayStart);
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(eventsViewModelProvider(widget.cityId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: asyncState.whenOrNull(
          data: (s) => Text('Events in ${s.city.name}', style: AppTextStyles.titleSmall),
        ) ??
            const Text('Events', style: AppTextStyles.titleSmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () => ref
                .read(eventsViewModelProvider(widget.cityId).notifier)
                .refresh(),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: asyncState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Text(err.toString(), style: AppTextStyles.body),
        ),
        data: (state) {
          final days = _weekDays(_selectedDay);
          final dayEvents = state.filteredEvents
              .where((e) => _isActiveOnDay(e, _selectedDay))
              .toList();
          final displayed = _showingAll
              ? state.filteredEvents
              : dayEvents;

          // Month/year header text.
          final monthYear =
              '${_monthName(_selectedDay.month)} ${_selectedDay.year}';

          return Column(
            children: [
              // ── Month/year + week strip ─────────────────────────────────
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.md,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageHorizontal,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Text(monthYear, style: AppTextStyles.bodyMedium),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(
                              () => _selectedDay = _selectedDay
                                  .subtract(const Duration(days: 7)),
                            ),
                            child: const Icon(Icons.chevron_left,
                                color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          GestureDetector(
                            onTap: () => setState(
                              () => _selectedDay = _selectedDay
                                  .add(const Duration(days: 7)),
                            ),
                            child: const Icon(Icons.chevron_right,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Week day strip
                    Row(
                      children: days.map((day) {
                        final isSelected = day.year == _selectedDay.year &&
                            day.month == _selectedDay.month &&
                            day.day == _selectedDay.day;
                        final isToday = day.year == DateTime.now().year &&
                            day.month == DateTime.now().month &&
                            day.day == DateTime.now().day;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDay = day;
                                _showingAll = false;
                              });
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _dayAbbr(day.weekday),
                                  style: AppTextStyles.overline.copyWith(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : isToday
                                            ? AppColors.primary.withOpacity(0.15)
                                            : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${day.day}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: isSelected
                                          ? AppColors.textPrimary
                                          : isToday
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                      fontWeight: isSelected || isToday
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),

              // ── Event list ────────────────────────────────────────────
              Expanded(
                child: displayed.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_busy,
                                color: AppColors.textMuted, size: 48),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No events on this day',
                              style: AppTextStyles.captionMuted,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pageHorizontal,
                          vertical: AppSpacing.lg,
                        ),
                        itemCount: displayed.length + 1,
                        itemBuilder: (context, index) {
                          if (index == displayed.length) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                  top: AppSpacing.lg, bottom: AppSpacing.xxxl),
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.primary),
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.md),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSmall),
                                  ),
                                ),
                                onPressed: () =>
                                    setState(() => _showingAll = !_showingAll),
                                child: Text(
                                  _showingAll
                                      ? 'Show Selected Day'
                                      : 'View All Events',
                                ),
                              ),
                            );
                          }
                          return _EventCard(event: displayed[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _dayAbbr(int weekday) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];

  String _monthName(int month) => const [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][month - 1];
}

// ---------------------------------------------------------------------------
// Event Card
// ---------------------------------------------------------------------------

class _EventCard extends StatelessWidget {
  final Event event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final timeRange = '${_formatTime(event.startDate)} – ${_formatTime(event.endDate)}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppSpacing.radiusCard),
              bottomLeft: Radius.circular(AppSpacing.radiusCard),
            ),
            child: CachedNetworkImage(
              imageUrl: event.image,
              width: 90,
              height: 110,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(width: 90, height: 110, color: AppColors.surfaceElevated),
              errorWidget: (_, __, ___) => Container(
                width: 90,
                height: 110,
                color: AppColors.surfaceElevated,
                alignment: Alignment.center,
                child: const Icon(Icons.event, color: AppColors.textMuted, size: 28),
              ),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event.title,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Time
                  Row(
                    children: [
                      const Icon(Icons.access_time_outlined,
                          color: AppColors.textMuted, size: 13),
                      const SizedBox(width: 4),
                      Text(timeRange, style: AppTextStyles.captionMuted),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Category chips
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _CategoryPill(label: event.category),
                      if (event.subcategory.isNotEmpty)
                        _CategoryPill(label: event.subcategory),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      // Only this week pill
                      if (event.onlyThisWeek)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusChip),
                          ),
                          child: Text(
                            'Only this week',
                            style: AppTextStyles.overline
                                .copyWith(color: AppColors.danger),
                          ),
                        ),
                      if (event.onlyThisWeek)
                        const SizedBox(width: AppSpacing.xs),
                      // Boost chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusChip),
                        ),
                        child: Text(
                          '+${event.discoveryBoost.toStringAsFixed(1)}%',
                          style: AppTextStyles.overline
                              .copyWith(color: AppColors.success),
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
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  const _CategoryPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
      ),
      child: Text(label, style: AppTextStyles.overline),
    );
  }
}
