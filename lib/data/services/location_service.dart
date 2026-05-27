// lib/data/services/location_service.dart
// Thin wrapper around the geolocator package.

import 'package:geolocator/geolocator.dart';

/// Result returned by [LocationService.getCurrentPosition].
class LocationResult {
  final double latitude;
  final double longitude;
  final double accuracy; // metres
  final DateTime timestamp;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  @override
  String toString() =>
      'LocationResult(lat: $latitude, lng: $longitude, accuracy: ${accuracy}m)';
}

/// Possible outcomes when requesting location access.
enum LocationPermissionStatus {
  granted,
  deniedOnce,
  deniedForever,
  serviceDisabled,
}

class LocationService {
  // ── Permission & Service checks ───────────────────────────────────────────

  /// Returns true if location services are enabled on the device.
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  /// Checks the current permission status without requesting anything.
  Future<LocationPermission> checkPermission() =>
      Geolocator.checkPermission();

  /// Requests location permission from the user.
  ///
  /// Returns a [LocationPermissionStatus] summarising the outcome.
  Future<LocationPermissionStatus> requestPermission() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse =>
        LocationPermissionStatus.granted,
      LocationPermission.deniedForever =>
        LocationPermissionStatus.deniedForever,
      _ => LocationPermissionStatus.deniedOnce,
    };
  }

  /// Opens the device's app settings so the user can change permissions.
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Opens the device's location settings.
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  // ── Position acquisition ──────────────────────────────────────────────────

  /// Returns the current device position.
  ///
  /// Throws [LocationServiceDisabledException] if location services are off.
  /// Throws [PermissionDeniedException] if the permission is denied.
  Future<LocationResult> getCurrentPosition({
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 15),
  }) async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: desiredAccuracy,
      timeLimit: timeLimit,
    );

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
    );
  }

  /// Returns the last known position, or null if unavailable.
  Future<LocationResult?> getLastKnownPosition() async {
    final position = await Geolocator.getLastKnownPosition();
    if (position == null) return null;

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
    );
  }

  // ── Distance helpers ──────────────────────────────────────────────────────

  /// Returns the distance in **metres** between two coordinates.
  double distanceBetween({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Convenience: returns distance from a [LocationResult] to a target point.
  double distanceFromResult({
    required LocationResult from,
    required double toLatitude,
    required double toLongitude,
  }) {
    return distanceBetween(
      startLatitude: from.latitude,
      startLongitude: from.longitude,
      endLatitude: toLatitude,
      endLongitude: toLongitude,
    );
  }
}
