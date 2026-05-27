// lib/data/services/local_storage_service.dart
// Hive wrapper providing typed access to all local storage boxes.

import 'package:hive_flutter/hive_flutter.dart';

/// Names of all Hive boxes used by the app.
class HiveBoxNames {
  HiveBoxNames._();

  static const String visits = 'visits';
  static const String userProfile = 'user_profile';
  static const String settings = 'settings';
  static const String cache = 'cache';
}

/// Central access point for Hive storage.
///
/// Call [LocalStorageService.init] once at app start (before [runApp]).
/// Then inject or read a singleton [LocalStorageService] via its provider.
class LocalStorageService {
  LocalStorageService._();

  static final LocalStorageService _instance = LocalStorageService._();

  /// The singleton instance.
  factory LocalStorageService() => _instance;

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Initialises Hive (path + Flutter integration) and opens all boxes.
  ///
  /// Must be awaited before [runApp] is called.
  static Future<void> init() async {
    await Hive.initFlutter();
    await registerAdapters();
    await openBoxes();
  }

  /// Registers all custom Hive type adapters.
  ///
  /// Add adapter registrations here when new annotated models are introduced.
  /// Returns a [Future] so callers may use `await` for consistency.
  static Future<void> registerAdapters() async {
    // Example: if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(MyAdapter());
  }

  /// Opens every named box required by the app.
  static Future<void> openBoxes() async {
    await Future.wait([
      Hive.openBox<String>(HiveBoxNames.visits),
      Hive.openBox<String>(HiveBoxNames.userProfile),
      Hive.openBox<dynamic>(HiveBoxNames.settings),
      Hive.openBox<String>(HiveBoxNames.cache),
    ]);
  }

  // ── Box accessors ─────────────────────────────────────────────────────────

  /// The box that persists visit JSON strings, keyed by visit id.
  Box<String> get visitsBox => Hive.box<String>(HiveBoxNames.visits);

  /// The box that persists the user profile JSON string.
  Box<String> get userProfileBox =>
      Hive.box<String>(HiveBoxNames.userProfile);

  /// A general-purpose settings box for primitive values.
  Box<dynamic> get settingsBox => Hive.box<dynamic>(HiveBoxNames.settings);

  /// A general-purpose cache box for serialised string values.
  Box<String> get cacheBox => Hive.box<String>(HiveBoxNames.cache);

  // ── Generic helpers ───────────────────────────────────────────────────────

  /// Reads a value from [settingsBox] by [key], returning [defaultValue] if absent.
  T getSetting<T>(String key, T defaultValue) {
    final value = settingsBox.get(key);
    if (value is T) return value;
    return defaultValue;
  }

  /// Writes [value] into [settingsBox] under [key].
  Future<void> setSetting<T>(String key, T value) =>
      settingsBox.put(key, value);

  /// Removes a setting by [key].
  Future<void> deleteSetting(String key) => settingsBox.delete(key);

  // ── Cache helpers ─────────────────────────────────────────────────────────

  /// Stores a JSON string in the cache box under [key].
  Future<void> cacheJson(String key, String jsonString) =>
      cacheBox.put(key, jsonString);

  /// Retrieves a cached JSON string by [key], or null if absent.
  String? getCachedJson(String key) => cacheBox.get(key);

  /// Removes a cached entry by [key].
  Future<void> deleteCached(String key) => cacheBox.delete(key);

  /// Clears all entries from the cache box.
  Future<void> clearCache() => cacheBox.clear();

  // ── Cleanup ───────────────────────────────────────────────────────────────

  /// Closes all open Hive boxes and flushes pending writes.
  Future<void> closeAll() => Hive.close();
}
