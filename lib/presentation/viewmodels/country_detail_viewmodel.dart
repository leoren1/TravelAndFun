// lib/presentation/viewmodels/country_detail_viewmodel.dart

import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/country.dart';
import 'package:explore_index/data/providers.dart';
import 'package:explore_index/domain/usecases/calculate_city_discovery.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Supporting model
// ---------------------------------------------------------------------------

class CitySummary {
  final City city;

  /// Discovery percentage 0.0–100.0 for this city.
  final double discoveryPercent;

  /// Total number of verified visits (activities) recorded in this city.
  final int totalActivities;

  /// Number of verified visits that have a photo.
  final int verifiedPhotos;

  /// Average rating across all visits in this city (0.0 if none).
  final double averageRating;

  const CitySummary({
    required this.city,
    required this.discoveryPercent,
    required this.totalActivities,
    required this.verifiedPhotos,
    required this.averageRating,
  });

  CitySummary copyWith({
    City? city,
    double? discoveryPercent,
    int? totalActivities,
    int? verifiedPhotos,
    double? averageRating,
  }) {
    return CitySummary(
      city: city ?? this.city,
      discoveryPercent: discoveryPercent ?? this.discoveryPercent,
      totalActivities: totalActivities ?? this.totalActivities,
      verifiedPhotos: verifiedPhotos ?? this.verifiedPhotos,
      averageRating: averageRating ?? this.averageRating,
    );
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class CountryDetailState {
  final Country country;
  final List<CitySummary> cities;

  /// Overall discovery percentage for the country (average of its cities).
  final double countryDiscovery;

  /// Total activities (verified visits) across all cities in the country.
  final int totalActivities;

  /// Total verified photos across all cities.
  final int verifiedPhotos;

  /// Average rating across all visits in all cities (0.0 if none).
  final double averageRating;

  const CountryDetailState({
    required this.country,
    required this.cities,
    required this.countryDiscovery,
    required this.totalActivities,
    required this.verifiedPhotos,
    required this.averageRating,
  });

  CountryDetailState copyWith({
    Country? country,
    List<CitySummary>? cities,
    double? countryDiscovery,
    int? totalActivities,
    int? verifiedPhotos,
    double? averageRating,
  }) {
    return CountryDetailState(
      country: country ?? this.country,
      cities: cities ?? this.cities,
      countryDiscovery: countryDiscovery ?? this.countryDiscovery,
      totalActivities: totalActivities ?? this.totalActivities,
      verifiedPhotos: verifiedPhotos ?? this.verifiedPhotos,
      averageRating: averageRating ?? this.averageRating,
    );
  }
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class CountryDetailViewModel
    extends AutoDisposeFamilyAsyncNotifier<CountryDetailState, String> {
  @override
  Future<CountryDetailState> build(String countryId) async {
    final countryRepo = ref.read(countryRepositoryProvider);
    final cityRepo = ref.read(cityRepositoryProvider);
    final placeRepo = ref.read(placeRepositoryProvider);
    final visitRepo = ref.read(visitRepositoryProvider);

    final country = await countryRepo.getCountryById(countryId);
    if (country == null) {
      throw StateError('Country not found: $countryId');
    }

    final allCities = await cityRepo.getAllCities();
    final places = await placeRepo.getAllPlaces();
    final allVisits = await visitRepo.getAllVisits();

    final countryCities =
        allCities.where((c) => country.cityIds.contains(c.id)).toList();

    int totalActivities = 0;
    int verifiedPhotos = 0;
    double ratingSum = 0;
    int ratingCount = 0;

    final citySummaries = countryCities.map((city) {
      final cityVisits = allVisits.where((v) {
        final idx = places.indexWhere((p) => p.id == v.placeId);
        return idx >= 0 && places[idx].cityId == city.id;
      }).toList();

      final disc = CalculateCityDiscovery(
        city: city,
        visits: cityVisits,
        places: places,
      ).execute();

      final verified =
          cityVisits.where((v) => v.verified && v.photoPath.isNotEmpty).length;
      final cityRatingSum =
          cityVisits.fold<double>(0, (sum, v) => sum + v.rating);

      totalActivities += cityVisits.length;
      verifiedPhotos += verified;
      ratingSum += cityRatingSum;
      ratingCount += cityVisits.length;

      return CitySummary(
        city: city,
        discoveryPercent: disc,
        totalActivities: cityVisits.length,
        verifiedPhotos: verified,
        averageRating: cityVisits.isEmpty
            ? 0.0
            : cityRatingSum / cityVisits.length,
      );
    }).toList();

    final countryDiscovery = citySummaries.isEmpty
        ? 0.0
        : citySummaries
                .map((s) => s.discoveryPercent)
                .reduce((a, b) => a + b) /
            citySummaries.length;

    return CountryDetailState(
      country: country,
      cities: citySummaries,
      countryDiscovery: countryDiscovery,
      totalActivities: totalActivities,
      verifiedPhotos: verifiedPhotos,
      averageRating: ratingCount == 0 ? 0.0 : ratingSum / ratingCount,
    );
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final countryDetailViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<CountryDetailViewModel, CountryDetailState, String>(
  CountryDetailViewModel.new,
);
