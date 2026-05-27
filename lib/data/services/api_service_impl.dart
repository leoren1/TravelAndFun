// lib/data/services/api_service_impl.dart
// Dio-based implementation of ApiService.
// All methods are wired up but defer to UnimplementedError until a real backend
// endpoint is available. Replace each throw with the appropriate Dio call.

import 'package:dio/dio.dart';
import 'package:explore_index/data/models/badge.dart';
import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/country.dart';
import 'package:explore_index/data/models/discovery_dna.dart';
import 'package:explore_index/data/models/event.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/user_profile.dart';
import 'package:explore_index/data/models/visit.dart';
import 'package:explore_index/data/services/api_service.dart';

class ApiServiceImpl implements ApiService {
  ApiServiceImpl({Dio? dio, String baseUrl = 'https://api.exploreindex.app/v1'})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _setupInterceptors();
  }

  final Dio _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // TODO: attach auth token from secure storage when available.
          handler.next(options);
        },
        onResponse: (response, handler) {
          handler.next(response);
        },
        onError: (DioException e, handler) {
          // Centralised error logging; callers receive the raw DioException.
          handler.next(e);
        },
      ),
    );
  }

  // ── Countries ─────────────────────────────────────────────────────────────

  @override
  Future<List<Country>> getCountries() async {
    final response = await _dio.get<List<dynamic>>('/countries');
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(Country.fromJson)
        .toList();
  }

  @override
  Future<Country> getCountry(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/countries/$id');
    return Country.fromJson(response.data!);
  }

  // ── Cities ────────────────────────────────────────────────────────────────

  @override
  Future<List<City>> getCitiesByCountry(String countryId) async {
    final response = await _dio.get<List<dynamic>>(
      '/cities',
      queryParameters: {'countryId': countryId},
    );
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(City.fromJson)
        .toList();
  }

  @override
  Future<City> getCity(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/cities/$id');
    return City.fromJson(response.data!);
  }

  // ── Places ────────────────────────────────────────────────────────────────

  @override
  Future<List<Place>> getPlacesByCity(String cityId) async {
    final response = await _dio.get<List<dynamic>>(
      '/places',
      queryParameters: {'cityId': cityId},
    );
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(Place.fromJson)
        .toList();
  }

  @override
  Future<List<Place>> getPlacesByCityAndCategory(
    String cityId,
    String categoryKey,
  ) async {
    final response = await _dio.get<List<dynamic>>(
      '/places',
      queryParameters: {'cityId': cityId, 'category': categoryKey},
    );
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(Place.fromJson)
        .toList();
  }

  @override
  Future<Place> getPlace(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/places/$id');
    return Place.fromJson(response.data!);
  }

  // ── Events ────────────────────────────────────────────────────────────────

  @override
  Future<List<Event>> getEventsByCity(String cityId) async {
    final response = await _dio.get<List<dynamic>>(
      '/events',
      queryParameters: {'cityId': cityId},
    );
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(Event.fromJson)
        .toList();
  }

  @override
  Future<List<Event>> getThisWeekEvents(String cityId) async {
    final response = await _dio.get<List<dynamic>>(
      '/events',
      queryParameters: {'cityId': cityId, 'onlyThisWeek': true},
    );
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(Event.fromJson)
        .toList();
  }

  @override
  Future<Event> getEvent(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/events/$id');
    return Event.fromJson(response.data!);
  }

  // ── Visits ────────────────────────────────────────────────────────────────

  @override
  Future<List<Visit>> getVisitsByUser(String userId) async {
    final response = await _dio.get<List<dynamic>>(
      '/visits',
      queryParameters: {'userId': userId},
    );
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(Visit.fromJson)
        .toList();
  }

  @override
  Future<Visit> createVisit(Visit visit) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/visits',
      data: visit.toJson(),
    );
    return Visit.fromJson(response.data!);
  }

  @override
  Future<Visit> updateVisit(Visit visit) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/visits/${visit.id}',
      data: visit.toJson(),
    );
    return Visit.fromJson(response.data!);
  }

  @override
  Future<void> deleteVisit(String visitId) async {
    await _dio.delete<void>('/visits/$visitId');
  }

  // ── User Profile ──────────────────────────────────────────────────────────

  @override
  Future<UserProfile> getUserProfile(String userId) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/users/$userId/profile');
    return UserProfile.fromJson(response.data!);
  }

  @override
  Future<UserProfile> updateUserProfile(
    String userId,
    UserProfile profile,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/users/$userId/profile',
      data: profile.toJson(),
    );
    return UserProfile.fromJson(response.data!);
  }

  // ── Badges ────────────────────────────────────────────────────────────────

  @override
  Future<List<Badge>> getBadges() async {
    final response = await _dio.get<List<dynamic>>('/badges');
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(Badge.fromJson)
        .toList();
  }

  @override
  Future<List<Badge>> getBadgesByUser(String userId) async {
    final response =
        await _dio.get<List<dynamic>>('/users/$userId/badges');
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(Badge.fromJson)
        .toList();
  }

  // ── Discovery DNA ─────────────────────────────────────────────────────────

  @override
  Future<DiscoveryDna> getDiscoveryDna(String userId) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/users/$userId/discovery-dna');
    return DiscoveryDna.fromJson(response.data!);
  }
}
