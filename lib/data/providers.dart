// lib/data/providers.dart
// Riverpod providers for all data-layer dependencies.

import 'package:explore_index/data/models/travel_mode.dart';
import 'package:explore_index/data/repositories/brand_repository.dart';
import 'package:explore_index/data/repositories/brand_repository_impl.dart';
import 'package:explore_index/data/repositories/city_repository.dart';
import 'package:explore_index/data/repositories/city_repository_impl.dart';
import 'package:explore_index/data/repositories/country_repository.dart';
import 'package:explore_index/data/repositories/country_repository_impl.dart';
import 'package:explore_index/data/repositories/event_repository.dart';
import 'package:explore_index/data/repositories/event_repository_impl.dart';
import 'package:explore_index/data/repositories/place_repository.dart';
import 'package:explore_index/data/repositories/place_repository_impl.dart';
import 'package:explore_index/data/repositories/social_feed_repository.dart';
import 'package:explore_index/data/repositories/social_feed_repository_impl.dart';
import 'package:explore_index/data/repositories/trip_plan_repository.dart';
import 'package:explore_index/data/repositories/trip_plan_repository_impl.dart';
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
import 'package:explore_index/domain/services/mode_filter_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Services ──────────────────────────────────────────────────────────────────

final staticDataServiceProvider = Provider<StaticDataService>(
  (ref) => StaticDataService(),
);

final localStorageServiceProvider = Provider<LocalStorageService>(
  (ref) => LocalStorageService(),
);

final apiServiceProvider = Provider<ApiService>(
  (ref) => ApiServiceImpl(),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

final exifServiceProvider = Provider<ExifService>(
  (ref) => ExifService(),
);

final photoVerificationServiceProvider = Provider<PhotoVerificationService>(
  (ref) => PhotoVerificationService(
    locationService: ref.read(locationServiceProvider),
    exifService: ref.read(exifServiceProvider),
  ),
);

final modeFilterServiceProvider = Provider<ModeFilterService>(
  (_) => const ModeFilterService(),
);

// ── Travel Mode ───────────────────────────────────────────────────────────────

/// Global travel mode — persisted in Hive settings box.
///
/// All viewmodels that show discovery percentages `watch` this provider;
/// when it changes they automatically rebuild with the new mode filter.
final travelModeProvider =
    NotifierProvider<TravelModeNotifier, TravelMode>(TravelModeNotifier.new);

class TravelModeNotifier extends Notifier<TravelMode> {
  static const _key = 'travel_mode';

  @override
  TravelMode build() {
    final stored =
        ref.read(localStorageServiceProvider).getSetting<String>(_key, TravelMode.gold.name);
    return TravelMode.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => TravelMode.gold,
    );
  }

  Future<void> setMode(TravelMode mode) async {
    state = mode;
    await ref.read(localStorageServiceProvider).setSetting(_key, mode.name);
  }
}

// ── Repositories ──────────────────────────────────────────────────────────────

final brandRepositoryProvider = Provider<BrandRepository>(
  (ref) => const BrandRepositoryImpl(),
);

final countryRepositoryProvider = Provider<CountryRepository>(
  (ref) => CountryRepositoryImpl(ref.read(staticDataServiceProvider)),
);

final cityRepositoryProvider = Provider<CityRepository>(
  (ref) => CityRepositoryImpl(ref.read(staticDataServiceProvider)),
);

final placeRepositoryProvider = Provider<PlaceRepository>(
  (ref) => PlaceRepositoryImpl(ref.read(staticDataServiceProvider)),
);

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepositoryImpl(ref.read(staticDataServiceProvider)),
);

final visitRepositoryProvider = Provider<VisitRepository>(
  (ref) => VisitRepositoryImpl(
    localStorage: ref.read(localStorageServiceProvider),
  ),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepositoryImpl(
    staticDataService: ref.read(staticDataServiceProvider),
    localStorage: ref.read(localStorageServiceProvider),
  ),
);

final socialFeedRepositoryProvider = Provider<SocialFeedRepository>(
  (_) => const SocialFeedRepositoryImpl(),
);

final tripPlanRepositoryProvider = Provider<TripPlanRepository>(
  (ref) => TripPlanRepositoryImpl(ref.read(localStorageServiceProvider)),
);
