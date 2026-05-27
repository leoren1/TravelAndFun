// lib/data/repositories/event_repository.dart
// Abstract contract for event data access.

import 'package:explore_index/data/models/event.dart';

abstract class EventRepository {
  /// Returns all events across all cities.
  Future<List<Event>> getAllEvents();

  /// Returns all events for [cityId].
  Future<List<Event>> getEventsByCity(String cityId);

  /// Returns events for [cityId] where [Event.onlyThisWeek] is true.
  Future<List<Event>> getThisWeekEvents(String cityId);

  /// Returns the event identified by [id], or null if not found.
  Future<Event?> getEventById(String id);
}
