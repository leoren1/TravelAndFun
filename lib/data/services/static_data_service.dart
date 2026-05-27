// lib/data/services/static_data_service.dart
// Loads bundled JSON assets from lib/static_data/ and caches them in memory.

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:explore_index/data/models/category.dart';
import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/country.dart';
import 'package:explore_index/data/models/event.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/user_profile.dart';

class StaticDataService {
  // ── In-memory caches ──────────────────────────────────────────────────────

  List<Country>? _countries;
  List<City>? _cities;
  List<Place>? _places;
  List<Event>? _events;
  UserProfile? _userProfile;

  // ── Countries ─────────────────────────────────────────────────────────────

  /// Returns all countries, loading from the asset bundle on first call.
  Future<List<Country>> getCountries() async {
    if (_countries != null) return _countries!;
    final raw = await _loadJson('lib/static_data/countries.json');
    _countries = (raw as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Country.fromJson)
        .toList();
    return _countries!;
  }

  /// Returns the country with [id], or null if not found.
  Future<Country?> getCountryById(String id) async {
    final list = await getCountries();
    try {
      return list.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Cities ────────────────────────────────────────────────────────────────

  /// Returns all cities, loading from the asset bundle on first call.
  Future<List<City>> getCities() async {
    if (_cities != null) return _cities!;
    final raw = await _loadJson('lib/static_data/cities.json');
    _cities = (raw as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(City.fromJson)
        .toList();
    return _cities!;
  }

  /// Returns all cities whose [City.countryId] matches [countryId].
  Future<List<City>> getCitiesByCountry(String countryId) async {
    final list = await getCities();
    return list.where((c) => c.countryId == countryId).toList();
  }

  /// Returns the city with [id], or null if not found.
  Future<City?> getCityById(String id) async {
    final list = await getCities();
    try {
      return list.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Places ────────────────────────────────────────────────────────────────

  /// Returns all places, loading from the asset bundle on first call.
  Future<List<Place>> getPlaces() async {
    if (_places != null) return _places!;
    final raw = await _loadJson('lib/static_data/places.json');
    _places = (raw as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Place.fromJson)
        .toList();
    return _places!;
  }

  /// Returns all places belonging to [cityId].
  Future<List<Place>> getPlacesByCity(String cityId) async {
    final list = await getPlaces();
    return list.where((p) => p.cityId == cityId).toList();
  }

  /// Returns places in [cityId] filtered by [categoryKey].
  Future<List<Place>> getPlacesByCityAndCategory(
    String cityId,
    String categoryKey,
  ) async {
    final list = await getPlaces();
    return list
        .where((p) => p.cityId == cityId && p.category.jsonKey == categoryKey)
        .toList();
  }

  /// Returns the place with [id], or null if not found.
  Future<Place?> getPlaceById(String id) async {
    final list = await getPlaces();
    try {
      return list.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Events ────────────────────────────────────────────────────────────────

  /// Returns all events, loading from the asset bundle on first call.
  Future<List<Event>> getEvents() async {
    if (_events != null) return _events!;
    final raw = await _loadJson('lib/static_data/events.json');
    _events = (raw as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Event.fromJson)
        .toList();
    return _events!;
  }

  /// Returns all events for [cityId].
  Future<List<Event>> getEventsByCity(String cityId) async {
    final list = await getEvents();
    return list.where((e) => e.cityId == cityId).toList();
  }

  /// Returns events for [cityId] where [Event.onlyThisWeek] is true.
  Future<List<Event>> getThisWeekEvents(String cityId) async {
    final list = await getEventsByCity(cityId);
    return list.where((e) => e.onlyThisWeek).toList();
  }

  /// Returns the event with [id], or null if not found.
  Future<Event?> getEventById(String id) async {
    final list = await getEvents();
    try {
      return list.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── User Profile ──────────────────────────────────────────────────────────

  /// Returns the bundled user profile, loading from the asset bundle on first call.
  Future<UserProfile> getUserProfile() async {
    if (_userProfile != null) return _userProfile!;
    final raw = await _loadJson('lib/static_data/user_profile.json');
    _userProfile = UserProfile.fromJson(raw as Map<String, dynamic>);
    return _userProfile!;
  }

  // ── Cache management ──────────────────────────────────────────────────────

  /// Clears all in-memory caches, forcing next calls to re-read from assets.
  void clearCache() {
    _countries = null;
    _cities = null;
    _places = null;
    _events = null;
    _userProfile = null;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<dynamic> _loadJson(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    return json.decode(jsonString);
  }
}
