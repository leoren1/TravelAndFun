// lib/presentation/viewmodels/country_detail_viewmodel.dart

import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/country.dart';
import 'package:explore_index/data/models/travel_mode.dart';
import 'package:explore_index/data/providers.dart';
import 'package:explore_index/domain/usecases/calculate_city_discovery.dart';
import 'package:explore_index/domain/usecases/calculate_country_discovery.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Supporting model
// ---------------------------------------------------------------------------

class CitySummary {
  final City city;
  final double discoveryPercent;
  final int totalActivities;
  final int verifiedPhotos;
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
  final double countryDiscovery;
  final int totalActivities;
  final int verifiedPhotos;
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
    // Rebuild whenever the user switches travel mode.
    final mode = ref.watch(travelModeProvider);

    final countryRepo = ref.read(countryRepositoryProvider);
    final cityRepo    = ref.read(cityRepositoryProvider);
    final placeRepo   = ref.read(placeRepositoryProvider);
    final visitRepo   = ref.read(visitRepositoryProvider);

    final country = await countryRepo.getCountryById(countryId);
    if (country == null) throw StateError('Country not found: $countryId');

    final allCities  = await cityRepo.getAllCities();
    final places     = await placeRepo.getAllPlaces();
    final allVisits  = await visitRepo.getAllVisits();

    // Show all cities of the country in the list (not just mode-filtered),
    // but calculate discovery with the current mode filter.
    final countryCities =
        allCities.where((c) => country.cityIds.contains(c.id)).toList();

    int totalActivities = 0;
    int verifiedPhotos  = 0;
    double ratingSum    = 0;
    int ratingCount     = 0;

    final citySummaries = countryCities.map((city) {
      final cityVisits = allVisits.where((v) {
        final idx = places.indexWhere((p) => p.id == v.placeId);
        return idx >= 0 && places[idx].cityId == city.id;
      }).toList();

      final disc = CalculateCityDiscovery(
        city: city,
        visits: cityVisits,
        places: places,
        mode: mode,
      ).execute();

      final verified =
          cityVisits.where((v) => v.verified && v.photoPath.isNotEmpty).length;
      final cityRatingSum =
          cityVisits.fold<double>(0, (sum, v) => sum + v.rating);

      totalActivities += cityVisits.length;
      verifiedPhotos  += verified;
      ratingSum       += cityRatingSum;
      ratingCount     += cityVisits.length;

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

    // Country-level discovery using the proper use-case.
    final countryDiscovery = CalculateCountryDiscovery(
      country: country,
      cities: allCities,
      visits: allVisits,
      places: places,
      mode: mode,
    ).execute();

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
