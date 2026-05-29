// lib/domain/usecases/verify_visit.dart

import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/visit.dart';
import 'package:explore_index/data/repositories/visit_repository.dart';
import 'package:explore_index/data/services/exif_service.dart';
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
  final ExifService exifService;
  final VisitRepository visitRepository;

  const VerifyVisitUseCase({
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
    // 1. Photo path is required.
    if (photoPath.isEmpty) {
      return VerifyVisitResult.failed(reason: VerificationFailReason.fileError);
    }

    // 2. Try to read EXIF GPS data — store if available, fall back to defaults.
    double photoLat = 0.0;
    double photoLng = 0.0;
    DateTime photoTakenAt = visitDate;

    final exifResult = await exifService.readGps(photoPath);
    if (exifResult.isSuccess && exifResult.data != null) {
      final gps = exifResult.data!;
      photoLat = gps.latitude;
      photoLng = gps.longitude;
      photoTakenAt = gps.takenAt ?? visitDate;
    }
    // If no EXIF data, keep defaults (0.0, 0.0, visitDate) — verification still succeeds.

    // 3. Persist the verified visit.
    final visit = Visit(
      id: const Uuid().v4(),
      placeId: place.id,
      userId: userId,
      visitedAt: visitDate,
      photoPath: photoPath,
      photoLatitude: photoLat,
      photoLongitude: photoLng,
      photoTakenAt: photoTakenAt,
      rating: rating,
      note: note,
      verified: true,
    );

    await visitRepository.saveVisit(visit);
    return VerifyVisitResult.success(visit: visit);
  }
}
