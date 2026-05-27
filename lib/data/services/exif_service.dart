// lib/data/services/exif_service.dart
// Thin wrapper around the native_exif package.

import 'package:native_exif/native_exif.dart';

/// Parsed GPS data extracted from a photo's EXIF metadata.
class ExifGpsData {
  final double latitude;
  final double longitude;
  final DateTime? takenAt;

  const ExifGpsData({
    required this.latitude,
    required this.longitude,
    this.takenAt,
  });

  @override
  String toString() =>
      'ExifGpsData(lat: $latitude, lng: $longitude, takenAt: $takenAt)';
}

/// Possible outcomes when reading EXIF from a photo.
enum ExifReadStatus {
  /// GPS data was found and parsed successfully.
  success,

  /// The file exists but contains no GPS tags.
  noGpsData,

  /// The file path is invalid or the file cannot be opened.
  fileError,

  /// A parsing error occurred (malformed EXIF).
  parseError,
}

class ExifReadResult {
  final ExifReadStatus status;
  final ExifGpsData? data;
  final String? errorMessage;

  const ExifReadResult._({required this.status, this.data, this.errorMessage});

  factory ExifReadResult.success(ExifGpsData data) =>
      ExifReadResult._(status: ExifReadStatus.success, data: data);

  factory ExifReadResult.noGps() =>
      ExifReadResult._(status: ExifReadStatus.noGpsData);

  factory ExifReadResult.fileError(String message) =>
      ExifReadResult._(status: ExifReadStatus.fileError, errorMessage: message);

  factory ExifReadResult.parseError(String message) =>
      ExifReadResult._(
          status: ExifReadStatus.parseError, errorMessage: message);

  bool get isSuccess => status == ExifReadStatus.success;
}

class ExifService {
  /// Reads GPS latitude, longitude, and (optionally) the capture timestamp
  /// from the EXIF metadata embedded in the image at [filePath].
  Future<ExifReadResult> readGps(String filePath) async {
    late Exif exif;
    try {
      exif = await Exif.fromPath(filePath);
    } catch (e) {
      return ExifReadResult.fileError('Cannot open file: $e');
    }

    try {
      final latLng = await exif.getLatLong();
      if (latLng == null) {
        await exif.close();
        return ExifReadResult.noGps();
      }

      DateTime? takenAt;
      try {
        final dateTimeStr =
            await exif.getAttribute('DateTimeOriginal') as String?;
        if (dateTimeStr != null && dateTimeStr.isNotEmpty) {
          // EXIF DateTime format: "YYYY:MM:DD HH:MM:SS"
          takenAt = _parseExifDateTime(dateTimeStr);
        }
      } catch (_) {
        // Timestamp is optional — silently ignore parse failures.
      }

      await exif.close();
      return ExifReadResult.success(
        ExifGpsData(
          latitude: latLng.latitude,
          longitude: latLng.longitude,
          takenAt: takenAt,
        ),
      );
    } catch (e) {
      await exif.close();
      return ExifReadResult.parseError('EXIF parse error: $e');
    }
  }

  /// Returns true if the image at [filePath] contains GPS coordinates.
  Future<bool> hasGpsData(String filePath) async {
    final result = await readGps(filePath);
    return result.isSuccess;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Converts an EXIF-format date-time string ("YYYY:MM:DD HH:MM:SS") to a
  /// [DateTime].  Returns null if parsing fails.
  DateTime? _parseExifDateTime(String raw) {
    try {
      // "2024:06:15 14:32:00" → "2024-06-15T14:32:00"
      final normalised = raw
          .replaceFirstMapped(
            RegExp(r'^(\d{4}):(\d{2}):(\d{2})'),
            (m) => '${m[1]}-${m[2]}-${m[3]}',
          )
          .replaceFirst(' ', 'T');
      return DateTime.parse(normalised);
    } catch (_) {
      return null;
    }
  }
}
