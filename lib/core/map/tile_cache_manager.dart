// lib/core/map/tile_cache_manager.dart
//
// Offline map tile cache + bulk download manager.
// Tiles are stored as: {appDocDir}/map_tiles_cache/{z}/{x}/{y}.png
// Uses the existing `dio` package for HTTP and `path_provider` for paths.
// Web uses browser cache natively — this class is no-op on web.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _kSubdomains = ['a', 'b', 'c', 'd'];
const _kUserAgent = 'com.exploreindex.explore_index';
const _kTileBase =
    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _buildTileUrl(int z, int x, int y) {
  final s = _kSubdomains[(x + y) % 4];
  return _kTileBase
      .replaceAll('{s}', s)
      .replaceAll('{z}', '$z')
      .replaceAll('{x}', '$x')
      .replaceAll('{y}', '$y');
}

int _lonToTileX(double lon, int zoom) =>
    ((lon + 180) / 360 * math.pow(2, zoom)).floor();

int _latToTileY(double lat, int zoom) {
  final latRad = lat * math.pi / 180;
  return ((1 -
              math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
          2 *
          math.pow(2, zoom))
      .floor()
      .clamp(0, math.pow(2, zoom).toInt() - 1);
}

// ---------------------------------------------------------------------------
// DownloadProgress
// ---------------------------------------------------------------------------

class DownloadProgress {
  final int done;
  final int total;
  final int failed;

  const DownloadProgress({
    required this.done,
    required this.total,
    required this.failed,
  });

  double get fraction => total == 0 ? 0 : done / total;
  bool get isComplete => done >= total;
  int get succeeded => done - failed;
}

// ---------------------------------------------------------------------------
// TileCacheManager
// ---------------------------------------------------------------------------

class TileCacheManager {
  static TileCacheManager? _instance;

  /// Returns the singleton; call [init] first.
  static TileCacheManager get instance {
    assert(_instance != null,
        'TileCacheManager.init() must be called before accessing instance');
    return _instance!;
  }

  final Directory _cacheDir;
  final Dio _dio;
  bool _downloadCancelled = false;

  TileCacheManager._(this._cacheDir)
      : _dio = Dio(
          BaseOptions(
            headers: {'User-Agent': _kUserAgent},
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );

  /// Initialise the manager. Must be called once in [main] before [runApp].
  /// Safe to call on web (becomes a no-op).
  static Future<void> init() async {
    if (kIsWeb) return;
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/map_tiles_cache');
    await dir.create(recursive: true);
    _instance = TileCacheManager._(dir);
  }

  // ---------------------------------------------------------------------------
  // Per-tile access
  // ---------------------------------------------------------------------------

  File _fileFor(int z, int x, int y) =>
      File('${_cacheDir.path}/$z/$x/$y.png');

  bool isCached(int z, int x, int y) => _fileFor(z, x, y).existsSync();

  Future<void> _fetchAndCache(int z, int x, int y) async {
    final file = _fileFor(z, x, y);
    if (file.existsSync()) return;
    try {
      await file.parent.create(recursive: true);
      await _dio.download(
        _buildTileUrl(z, x, y),
        file.path,
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );
    } catch (_) {
      // Delete partial file on error so it will be retried next time.
      if (file.existsSync()) unawaited(file.delete());
    }
  }

  /// Returns an [ImageProvider] for the given tile coordinates.
  ///
  /// * If the tile is cached on disk → [FileImage] (fully offline).
  /// * Otherwise → [NetworkImage] and the tile is cached in the background
  ///   so future accesses are offline-capable.
  ImageProvider imageFor(int z, int x, int y) {
    final file = _fileFor(z, x, y);
    if (file.existsSync()) return FileImage(file);
    // Schedule background cache — don't await.
    unawaited(_fetchAndCache(z, x, y));
    return NetworkImage(
      _buildTileUrl(z, x, y),
      headers: {'User-Agent': _kUserAgent},
    );
  }

  // ---------------------------------------------------------------------------
  // Bulk download
  // ---------------------------------------------------------------------------

  /// Estimates the number of tiles for a region.
  static int estimateTileCount({
    required LatLng southWest,
    required LatLng northEast,
    required int minZoom,
    required int maxZoom,
  }) {
    int count = 0;
    for (int z = minZoom; z <= maxZoom; z++) {
      final x0 = _lonToTileX(southWest.longitude, z);
      final x1 = _lonToTileX(northEast.longitude, z);
      final y0 = _latToTileY(northEast.latitude, z); // north = smaller y
      final y1 = _latToTileY(southWest.latitude, z); // south = larger y
      count += (x1 - x0 + 1).clamp(0, 9999) * (y1 - y0 + 1).clamp(0, 9999);
    }
    return count;
  }

  /// Cancels an ongoing [downloadRegion] stream.
  void cancelDownload() => _downloadCancelled = true;

  /// Downloads all tiles for the given bounding box and zoom range.
  /// Yields [DownloadProgress] updates. Call [cancelDownload] to abort.
  Stream<DownloadProgress> downloadRegion({
    required LatLng southWest,
    required LatLng northEast,
    required int minZoom,
    required int maxZoom,
    int parallelism = 5,
  }) async* {
    _downloadCancelled = false;

    // Build the full coordinate list.
    final coords = <(int, int, int)>[];
    for (int z = minZoom; z <= maxZoom; z++) {
      final x0 = _lonToTileX(southWest.longitude, z);
      final x1 = _lonToTileX(northEast.longitude, z);
      final y0 = _latToTileY(northEast.latitude, z);
      final y1 = _latToTileY(southWest.latitude, z);
      for (int x = x0; x <= x1; x++) {
        for (int y = y0; y <= y1; y++) {
          coords.add((z, x, y));
        }
      }
    }

    final total = coords.length;
    int done = 0;
    int failed = 0;

    yield DownloadProgress(done: 0, total: total, failed: 0);

    for (int i = 0; i < coords.length; i += parallelism) {
      if (_downloadCancelled) break;
      final batch =
          coords.sublist(i, math.min(i + parallelism, coords.length));
      await Future.wait(batch.map((c) async {
        if (_downloadCancelled) return;
        try {
          await _fetchAndCache(c.$1, c.$2, c.$3);
        } catch (_) {
          failed++;
        }
      }));
      done += batch.length;
      yield DownloadProgress(done: done, total: total, failed: failed);
    }
  }

  // ---------------------------------------------------------------------------
  // Cache info
  // ---------------------------------------------------------------------------

  /// Returns disk usage in bytes.
  Future<int> cacheSize() async {
    if (!_cacheDir.existsSync()) return 0;
    int size = 0;
    await for (final entity in _cacheDir.list(recursive: true)) {
      if (entity is File) size += entity.lengthSync();
    }
    return size;
  }

  /// Deletes the entire tile cache.
  Future<void> clearCache() async {
    if (_cacheDir.existsSync()) await _cacheDir.delete(recursive: true);
    await _cacheDir.create();
  }
}

// ---------------------------------------------------------------------------
// Custom TileProvider for flutter_map
// ---------------------------------------------------------------------------

/// A [TileProvider] that serves tiles from the local disk cache when available
/// and falls back to the network otherwise. Tiles fetched from the network are
/// automatically saved to disk for future offline use.
///
/// On web this class is never instantiated — the browser's own cache is used.
class OfflineTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return TileCacheManager.instance.imageFor(
      coordinates.z,
      coordinates.x,
      coordinates.y,
    );
  }
}
