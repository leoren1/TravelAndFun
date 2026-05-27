// lib/domain/usecases/verify_visit.dart

import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/visit.dart';
import 'package:explore_index/data/repositories/visit_repository.dart';
import 'package:explore_index/data/services/exif_service.dart';
import 'package:explore_index/data/services/photo_verification_service.dart';
import 'package:uuid/uuid.dart';

/// Reasons why photo verification can fail.
enum VerificationFailReason {
  /// Photo GPS does not match the place location.
  locationMismatch,

  /// Photo contains no EXIF / GPS data.
  noExifData,

  /// The photo file could not be read.
  fileError,

  /// Device location is unavailable.
  deviceLocationUnavailable,

  /// Device is too far from the place.
  deviceTooFar,
}

/// The result returned by [VerifyVisitUseCase.execute].
class VerifyVisitResult {
  final bool success;
  final Visit? visit;
  final VerificationFailReason? reason;

  const VerifyVisitResult._({
    required this.success,
    this.visit,
    this.reason,
  });

  factory VerifyVisitResult.success({required Visit visit}) =>
      VerifyVisitResult._(success: true, visit: visit);

  factory VerifyVisitResult.failed({required VerificationFailReason reason}) =>
      VerifyVisitResult._(success: false, reason: reason);
}

class VerifyVisitUseCase {
  final PhotoVerificationService verificationService;
  final ExifService exifService;
  final VisitRepository visitRepository;

  const VerifyVisitUseCase({
    required this.verificationService,
    required this.exifService,
    required this.visitRepository,
  });

  Future<VerifyVisitResult> execute({
    required String photoPath,
    required Place place,
    required int rating,
    String? note,
    required DateTime visitDate,
    required String userId,
  }) async {
    // 1. Verify location via PhotoVerificationService.
    final verResult = await verificationService.verifyPhoto(
      photoPath: photoPath,
      placeLat: place.latitude,
      placeLng: place.longitude,
    );

    if (!verResult.isVerified) {
      final failReason = _mapStatus(verResult.status);
      return VerifyVisitResult.failed(reason: failReason);
    }

    // 2. Read EXIF data for photo coordinates and timestamp.
    final exifResult = await exifService.readGps(photoPath);
    if (!exifResult.isSuccess || exifResult.data == null) {
      return VerifyVisitResult.failed(reason: VerificationFailReason.noExifData);
    }

    final gps = exifResult.data!;

    // 3. Persist the verified visit.
    final visit = Visit(
      id: const Uuid().v4(),
      placeId: place.id,
      userId: userId,
      visitedAt: visitDate,
      photoPath: photoPath,
      photoLatitude: gps.latitude,
      photoLongitude: gps.longitude,
      photoTakenAt: gps.takenAt ?? visitDate,
      rating: rating,
      note: note,
      verified: true,
    );

    await visitRepository.saveVisit(visit);
    return VerifyVisitResult.success(visit: visit);
  }

  VerificationFailReason _mapStatus(VerificationStatus status) {
    return switch (status) {
      VerificationStatus.locationMismatch =>
        VerificationFailReason.locationMismatch,
      VerificationStatus.noExifData => VerificationFailReason.noExifData,
      VerificationStatus.fileError => VerificationFailReason.fileError,
      VerificationStatus.deviceLocationUnavailable =>
        VerificationFailReason.deviceLocationUnavailable,
      VerificationStatus.deviceTooFar => VerificationFailReason.deviceTooFar,
      VerificationStatus.verified => VerificationFailReason.locationMismatch,
    };
  }
}
