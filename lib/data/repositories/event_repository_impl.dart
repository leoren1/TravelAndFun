// lib/data/repositories/event_repository_impl.dart
// StaticDataService-backed implementation of EventRepository.

import 'package:explore_index/data/models/event.dart';
import 'package:explore_index/data/repositories/event_repository.dart';
import 'package:explore_index/data/services/static_data_service.dart';

class EventRepositoryImpl implements EventRepository {
  const EventRepositoryImpl(this._dataService);

  final StaticDataService _dataService;

  @override
  Future<List<Event>> getAllEvents() => _dataService.getEvents();

  @override
  Future<List<Event>> getEventsByCity(String cityId) =>
      _dataService.getEventsByCity(cityId);

  @override
  Future<List<Event>> getThisWeekEvents(String cityId) =>
      _dataService.getThisWeekEvents(cityId);

  @override
  Future<Event?> getEventById(String id) => _dataService.getEventById(id);
}
