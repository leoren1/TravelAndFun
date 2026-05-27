// lib/data/services/api_service.dart
// Abstract contract for the remote REST API.

import 'package:explore_index/data/models/badge.dart';
import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/country.dart';
import 'package:explore_index/data/models/discovery_dna.dart';
import 'package:explore_index/data/models/event.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/user_profile.dart';
import 'package:explore_index/data/models/visit.dart';

/// Defines all remote API operations required by Explore Index.
///
/// Both the live [ApiServiceImpl] and any test fakes implement this interface
/// so that the rest of the codebase is decoupled from the HTTP layer.
abstract class ApiService {
  // ── Countries ────────────────────────────────────────────────────────────

  /// Fetches the full list of available countries.
  Future<List<Country>> getCountries();

  /// Fetches a single country by its [id].
  Future<Country> getCountry(String id);

  // ── Cities ───────────────────────────────────────────────────────────────

  /// Fetches all cities belonging to [countryId].
  Future<List<City>> getCitiesByCountry(String countryId);

  /// Fetches a single city by its [id].
  Future<City> getCity(String id);

  // ── Places ───────────────────────────────────────────────────────────────

  /// Fetches all places belonging to [cityId].
  Future<List<Place>> getPlacesByCity(String cityId);

  /// Fetches places in [cityId] filtered by [categoryKey].
  Future<List<Place>> getPlacesByCityAndCategory(
    String cityId,
    String categoryKey,
  );

  /// Fetches a single place by its [id].
  Future<Place> getPlace(String id);

  // ── Events ───────────────────────────────────────────────────────────────

  /// Fetches all upcoming events for [cityId].
  Future<List<Event>> getEventsByCity(String cityId);

  /// Fetches events for [cityId] that occur only within the current week.
  Future<List<Event>> getThisWeekEvents(String cityId);

  /// Fetches a single event by its [id].
  Future<Event> getEvent(String id);

  // ── Visits ───────────────────────────────────────────────────────────────

  /// Fetches all visits for [userId].
  Future<List<Visit>> getVisitsByUser(String userId);

  /// Submits a new visit record to the server.
  ///
  /// Returns the server-persisted [Visit] (may contain server-assigned fields).
  Future<Visit> createVisit(Visit visit);

  /// Updates an existing visit record.
  Future<Visit> updateVisit(Visit visit);

  /// Deletes the visit identified by [visitId].
  Future<void> deleteVisit(String visitId);

  // ── User Profile ─────────────────────────────────────────────────────────

  /// Fetches the profile for [userId].
  Future<UserProfile> getUserProfile(String userId);

  /// Updates the profile for [userId] with the supplied [profile].
  Future<UserProfile> updateUserProfile(String userId, UserProfile profile);

  // ── Badges ───────────────────────────────────────────────────────────────

  /// Fetches all badge definitions available in the app.
  Future<List<Badge>> getBadges();

  /// Fetches only the badges already earned by [userId].
  Future<List<Badge>> getBadgesByUser(String userId);

  // ── Discovery DNA ─────────────────────────────────────────────────────────

  /// Fetches the computed Discovery DNA for [userId].
  Future<DiscoveryDna> getDiscoveryDna(String userId);
}
