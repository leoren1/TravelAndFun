// lib/data/services/photo_verification_service.dart
// Composes LocationService and ExifService to verify that a photo was taken
// at (or near) a given place.

import 'package:explore_index/data/services/exif_service.dart';
import 'package:explore_index/data/services/location_service.dart';

/// The outcome of a photo verification attempt.
enum VerificationStatus {
  /// Photo GPS matches the place location within tolerance.
  verified,

  /// Photo has GPS data but it is too far from the place.
  locationMismatch,

  /// Photo has no GPS / EXIF data.
  noExifData,

  /// Could not read the photo file.
  fileError,

  /// The device's current location could not be obtained.
  deviceLocationUnavailable,

  /// Device location is present but too far from the place.
  deviceTooFar,
}

class VerificationResult {
  final VerificationStatus status;

  /// Distance in metres between the photo GPS and the place (if computable).
  final double? photoDistanceMetres;

  /// Distance in metres between the device and the place (if computable).
  final double? deviceDistanceMetres;

  final String? errorMessage;

  const VerificationResult({
    required this.status,
    this.photoDistanceMetres,
    this.deviceDistanceMetres,
    this.errorMessage,
  });

  bool get isVerified => status == VerificationStatus.verified;

  @override
  String toString() =>
      'VerificationResult(status: $status, '
      'photoDist: $photoDistanceMetres m, '
      'deviceDist: $deviceDistanceMetres m)';
}

class PhotoVerificationService {
  PhotoVerificationService({
    required LocationService locationService,
    required ExifService exifService,

    /// Maximum distance (metres) allowed between photo GPS and place location.
    double maxPhotoDistanceMetres = 200.0,

    /// Maximum distance (metres) allowed between current device and place location.
    double maxDeviceDistanceMetres = 500.0,
  })  : _locationService = locationService,
        _exifService = exifService,
        _maxPhotoDist = maxPhotoDistanceMetres,
        _maxDeviceDist = maxDeviceDistanceMetres;

  final LocationService _locationService;
  final ExifService _exifService;
  final double _maxPhotoDist;
  final double _maxDeviceDist;

  /// Verifies [photoPath] was taken at the coordinates ([placeLat], [placeLng]).
  ///
  /// The check runs in two steps:
  /// 1. EXIF GPS must be within [_maxPhotoDist] metres of the place.
  /// 2. (Optional) Current device location must be within [_maxDeviceDist]
  ///    metres of the place.  Pass [requireDeviceLocation] = false to skip.
  Future<VerificationResult> verifyPhoto({
    required String photoPath,
    required double placeLat,
    required double placeLng,
    bool requireDeviceLocation = true,
  }) async {
    // ── Step 1: EXIF check ────────────────────────────────────────────────
    final exifResult = await _exifService.readGps(photoPath);

    if (exifResult.status == ExifReadStatus.fileError) {
      return VerificationResult(
        status: VerificationStatus.fileError,
        errorMessage: exifResult.errorMessage,
      );
    }

    if (!exifResult.isSuccess || exifResult.data == null) {
      return const VerificationResult(status: VerificationStatus.noExifData);
    }

    final gps = exifResult.data!;
    final photoDist = _locationService.distanceBetween(
      startLatitude: gps.latitude,
      startLongitude: gps.longitude,
      endLatitude: placeLat,
      endLongitude: placeLng,
    );

    if (photoDist > _maxPhotoDist) {
      return VerificationResult(
        status: VerificationStatus.locationMismatch,
        photoDistanceMetres: photoDist,
      );
    }

    // ── Step 2: Device location check (optional) ──────────────────────────
    if (!requireDeviceLocation) {
      return VerificationResult(
        status: VerificationStatus.verified,
        photoDistanceMetres: photoDist,
      );
    }

    LocationResult? deviceLocation;
    try {
      final permStatus = await _locationService.requestPermission();
      if (permStatus == LocationPermissionStatus.granted) {
        deviceLocation = await _locationService.getCurrentPosition();
      }
    } catch (_) {
      // Non-fatal: fall through to unavailable result.
    }

    if (deviceLocation == null) {
      // Cannot get device location; treat as unverifiable if required.
      return VerificationResult(
        status: VerificationStatus.deviceLocationUnavailable,
        photoDistanceMetres: photoDist,
      );
    }

    final deviceDist = _locationService.distanceBetween(
      startLatitude: deviceLocation.latitude,
      startLongitude: deviceLocation.longitude,
      endLatitude: placeLat,
      endLongitude: placeLng,
    );

    if (deviceDist > _maxDeviceDist) {
      return VerificationResult(
        status: VerificationStatus.deviceTooFar,
        photoDistanceMetres: photoDist,
        deviceDistanceMetres: deviceDist,
      );
    }

    return VerificationResult(
      status: VerificationStatus.verified,
      photoDistanceMetres: photoDist,
      deviceDistanceMetres: deviceDist,
    );
  }
}
