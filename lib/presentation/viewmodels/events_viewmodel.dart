// lib/presentation/viewmodels/events_viewmodel.dart

import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/event.dart';
import 'package:explore_index/data/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class EventsState {
  final City city;

  /// All events for the city (sorted by start date ascending).
  final List<Event> allEvents;

  /// Events that are active right now (today between startDate and endDate).
  final List<Event> activeEvents;

  /// Events limited to this week (onlyThisWeek == true).
  final List<Event> thisWeekEvents;

  /// Currently applied text filter (empty string = no filter).
  final String searchQuery;

  const EventsState({
    required this.city,
    required this.allEvents,
    required this.activeEvents,
    required this.thisWeekEvents,
    this.searchQuery = '',
  });

  /// Returns [allEvents] filtered by [searchQuery] (case-insensitive title match).
  List<Event> get filteredEvents {
    if (searchQuery.isEmpty) return allEvents;
    final q = searchQuery.toLowerCase();
    return allEvents
        .where(
          (e) =>
              e.title.toLowerCase().contains(q) ||
              e.category.toLowerCase().contains(q) ||
              e.subcategory.toLowerCase().contains(q),
        )
        .toList();
  }

  EventsState copyWith({
    City? city,
    List<Event>? allEvents,
    List<Event>? activeEvents,
    List<Event>? thisWeekEvents,
    String? searchQuery,
  }) {
    return EventsState(
      city: city ?? this.city,
      allEvents: allEvents ?? this.allEvents,
      activeEvents: activeEvents ?? this.activeEvents,
      thisWeekEvents: thisWeekEvents ?? this.thisWeekEvents,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class EventsViewModel
    extends AutoDisposeFamilyAsyncNotifier<EventsState, String> {
  @override
  Future<EventsState> build(String cityId) async {
    final cityRepo = ref.read(cityRepositoryProvider);
    final eventRepo = ref.read(eventRepositoryProvider);

    final city = await cityRepo.getCityById(cityId);
    if (city == null) throw StateError('City not found: $cityId');

    final allEvents = await eventRepo.getEventsByCity(cityId);
    final thisWeekEvents = await eventRepo.getThisWeekEvents(cityId);

    // Sort all events by start date ascending.
    final sorted = [...allEvents]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final activeEvents = sorted.where((e) => e.isActive).toList();

    return EventsState(
      city: city,
      allEvents: sorted,
      activeEvents: activeEvents,
      thisWeekEvents: thisWeekEvents,
    );
  }

  void setSearchQuery(String query) {
    state.whenData(
      (data) => state = AsyncData(data.copyWith(searchQuery: query)),
    );
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final eventsViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<EventsViewModel, EventsState, String>(
  EventsViewModel.new,
);
