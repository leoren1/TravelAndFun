// lib/data/providers.dart
// Riverpod providers for all data-layer dependencies.
//
// Usage:
//   final countries = await ref.read(countryRepositoryProvider).getAllCountries();

import 'package:explore_index/data/repositories/city_repository.dart';
import 'package:explore_index/data/repositories/city_repository_impl.dart';
import 'package:explore_index/data/repositories/country_repository.dart';
import 'package:explore_index/data/repositories/country_repository_impl.dart';
import 'package:explore_index/data/repositories/event_repository.dart';
import 'package:explore_index/data/repositories/event_repository_impl.dart';
import 'package:explore_index/data/repositories/place_repository.dart';
import 'package:explore_index/data/repositories/place_repository_impl.dart';
import 'package:explore_index/data/repositories/user_repository.dart';
import 'package:explore_index/data/repositories/visit_repository.dart';
import 'package:explore_index/data/repositories/visit_repository_impl.dart';
import 'package:explore_index/data/services/api_service.dart';
import 'package:explore_index/data/services/api_service_impl.dart';
import 'package:explore_index/data/services/exif_service.dart';
import 'package:explore_index/data/services/local_storage_service.dart';
import 'package:explore_index/data/services/location_service.dart';
import 'package:explore_index/data/services/photo_verification_service.dart';
import 'package:explore_index/data/services/static_data_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Services ──────────────────────────────────────────────────────────────────

/// Provides the singleton [StaticDataService] that reads bundled JSON assets.
final staticDataServiceProvider = Provider<StaticDataService>(
  (ref) => StaticDataService(),
);

/// Provides the singleton [LocalStorageService] (Hive wrapper).
///
/// Requires [LocalStorageService.init] to have been called before [runApp].
final localStorageServiceProvider = Provider<LocalStorageService>(
  (ref) => LocalStorageService(),
);

/// Provides the [ApiService] backed by Dio.
final apiServiceProvider = Provider<ApiService>(
  (ref) => ApiServiceImpl(),
);

/// Provides [LocationService] wrapping geolocator.
final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

/// Provides [ExifService] wrapping native_exif.
final exifServiceProvider = Provider<ExifService>(
  (ref) => ExifService(),
);

/// Provides [PhotoVerificationService] composed from location + exif services.
final photoVerificationServiceProvider = Provider<PhotoVerificationService>(
  (ref) => PhotoVerificationService(
    locationService: ref.read(locationServiceProvider),
    exifService: ref.read(exifServiceProvider),
  ),
);

// ── Repositories ──────────────────────────────────────────────────────────────

/// Provides [CountryRepository] backed by [StaticDataService].
final countryRepositoryProvider = Provider<CountryRepository>(
  (ref) => CountryRepositoryImpl(ref.read(staticDataServiceProvider)),
);

/// Provides [CityRepository] backed by [StaticDataService].
final cityRepositoryProvider = Provider<CityRepository>(
  (ref) => CityRepositoryImpl(ref.read(staticDataServiceProvider)),
);

/// Provides [PlaceRepository] backed by [StaticDataService].
final placeRepositoryProvider = Provider<PlaceRepository>(
  (ref) => PlaceRepositoryImpl(ref.read(staticDataServiceProvider)),
);

/// Provides [EventRepository] backed by [StaticDataService].
final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepositoryImpl(ref.read(staticDataServiceProvider)),
);

/// Provides [VisitRepository] backed by Hive via [LocalStorageService].
final visitRepositoryProvider = Provider<VisitRepository>(
  (ref) => VisitRepositoryImpl(
    localStorage: ref.read(localStorageServiceProvider),
  ),
);

/// Provides [UserRepository] backed by [StaticDataService] + Hive.
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepositoryImpl(
    staticDataService: ref.read(staticDataServiceProvider),
    localStorage: ref.read(localStorageServiceProvider),
  ),
);
