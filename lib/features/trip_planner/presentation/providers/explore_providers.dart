// All Riverpod providers for the Trip Planner feature.
// State classes and notifiers are defined inline.
import 'package:explore_index/features/trip_planner/data/models/auto_suggest_params.dart';
import 'package:explore_index/features/trip_planner/data/models/explore_category.dart';
import 'package:explore_index/features/trip_planner/data/models/explore_city.dart';
import 'package:explore_index/features/trip_planner/data/models/explore_country.dart';
import 'package:explore_index/features/trip_planner/data/models/explore_place.dart';
import 'package:explore_index/features/trip_planner/data/models/itinerary.dart';
import 'package:explore_index/features/trip_planner/data/models/schedule_slot.dart';
import 'package:explore_index/features/trip_planner/data/repositories/explore_repository_impl.dart';
import 'package:explore_index/features/trip_planner/data/repositories/i_explore_repository.dart';
import 'package:explore_index/features/trip_planner/data/services/auto_suggest_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Infrastructure providers
// ─────────────────────────────────────────────────────────────────────────────

final exploreRepositoryProvider = Provider<IExploreRepository>(
  (ref) => const ExploreRepositoryImpl(),
);

final autoSuggestServiceProvider = Provider<AutoSuggestService>(
  (ref) => AutoSuggestService(ref.read(exploreRepositoryProvider)),
);

// ─────────────────────────────────────────────────────────────────────────────
// Itinerary list (in-memory; swap inner store for Hive later)
// ─────────────────────────────────────────────────────────────────────────────

class ItineraryListNotifier extends StateNotifier<List<Itinerary>> {
  ItineraryListNotifier() : super([]);

  void addItinerary(Itinerary itinerary) =>
      state = [...state, itinerary];

  void removeItinerary(String id) =>
      state = state.where((i) => i.id != id).toList();

  void updateItinerary(Itinerary updated) => state = [
        for (final i in state)
          if (i.id == updated.id) updated else i,
      ];

  Itinerary? findById(String id) =>
      state.cast<Itinerary?>().firstWhere(
            (i) => i?.id == id,
            orElse: () => null,
          );
}

final itineraryListProvider =
    StateNotifierProvider<ItineraryListNotifier, List<Itinerary>>(
  (ref) => ItineraryListNotifier(),
);

// ─────────────────────────────────────────────────────────────────────────────
// TripMainState + provider
// ─────────────────────────────────────────────────────────────────────────────

class TripMainState {
  final List<ExploreCity> trendingCities;
  final List<ExploreCountry> allCountries;
  final List<ExploreCity> featuredCities;

  const TripMainState({
    required this.trendingCities,
    required this.allCountries,
    required this.featuredCities,
  });
}

final tripMainProvider = FutureProvider.autoDispose<TripMainState>((ref) async {
  final repo = ref.read(exploreRepositoryProvider);
  return TripMainState(
    trendingCities: repo.getTrendingCities(limit: 6),
    allCountries: repo.getAllCountries(),
    featuredCities: repo.getFeaturedCities(limit: 8),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// CountryExplorationState + provider (family by countryId)
// ─────────────────────────────────────────────────────────────────────────────

class CountryExplorationState {
  final ExploreCountry country;
  final List<ExploreCity> cities;
  final String? selectedMoodFilter;
  final List<ExplorePlace> highlights;

  const CountryExplorationState({
    required this.country,
    required this.cities,
    this.selectedMoodFilter,
    required this.highlights,
  });

  CountryExplorationState copyWith({
    ExploreCountry? country,
    List<ExploreCity>? cities,
    String? selectedMoodFilter,
    bool clearMoodFilter = false,
    List<ExplorePlace>? highlights,
  }) =>
      CountryExplorationState(
        country: country ?? this.country,
        cities: cities ?? this.cities,
        selectedMoodFilter:
            clearMoodFilter ? null : (selectedMoodFilter ?? this.selectedMoodFilter),
        highlights: highlights ?? this.highlights,
      );

  List<ExploreCity> get filteredCities {
    if (selectedMoodFilter == null) return cities;
    return cities
        .where((c) => c.moodTags.contains(selectedMoodFilter))
        .toList();
  }
}

final countryExplorationProvider =
    FutureProvider.autoDispose.family<CountryExplorationState, String>(
  (ref, countryId) async {
    final repo = ref.read(exploreRepositoryProvider);
    final country = repo.getCountryById(countryId);
    if (country == null) {
      throw StateError('Country not found: $countryId');
    }
    final cities = repo.getCitiesForCountry(countryId);
    final highlightPlaces = cities
        .expand((c) => repo.getHighlightPlacesForCity(c.id, limit: 2))
        .toList();
    return CountryExplorationState(
      country: country,
      cities: cities,
      highlights: highlightPlaces,
    );
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// CityDiscoveryState + provider (family by cityId)
// ─────────────────────────────────────────────────────────────────────────────

class CityDiscoveryState {
  final ExploreCity city;
  final ExploreCountry country;
  final List<ExploreCategory> categories;
  final String? selectedCategoryId;
  final Map<String, List<ExplorePlace>> placesByCategory;

  const CityDiscoveryState({
    required this.city,
    required this.country,
    required this.categories,
    this.selectedCategoryId,
    required this.placesByCategory,
  });

  CityDiscoveryState copyWith({
    ExploreCity? city,
    ExploreCountry? country,
    List<ExploreCategory>? categories,
    String? selectedCategoryId,
    bool clearCategory = false,
    Map<String, List<ExplorePlace>>? placesByCategory,
  }) =>
      CityDiscoveryState(
        city: city ?? this.city,
        country: country ?? this.country,
        categories: categories ?? this.categories,
        selectedCategoryId:
            clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
        placesByCategory: placesByCategory ?? this.placesByCategory,
      );

  List<ExplorePlace> get visiblePlaces {
    if (selectedCategoryId == null) {
      return placesByCategory.values.expand((list) => list).toList()
        ..sort((a, b) {
          if (a.isHighlight && !b.isHighlight) return -1;
          if (!a.isHighlight && b.isHighlight) return 1;
          return b.rating.compareTo(a.rating);
        });
    }
    return placesByCategory[selectedCategoryId] ?? [];
  }
}

final cityDiscoveryProvider =
    FutureProvider.autoDispose.family<CityDiscoveryState, String>(
  (ref, cityId) async {
    final repo = ref.read(exploreRepositoryProvider);
    final city = repo.getCityById(cityId);
    if (city == null) throw StateError('City not found: $cityId');
    final country = repo.getCountryById(city.countryId);
    if (country == null) throw StateError('Country not found: ${city.countryId}');
    final categories = repo.getCategoriesForCity(cityId);
    final placesByCategory = <String, List<ExplorePlace>>{};
    for (final cat in categories) {
      placesByCategory[cat.id] =
          repo.getPlacesForCityAndCategory(cityId, cat.id);
    }
    return CityDiscoveryState(
      city: city,
      country: country,
      categories: categories,
      placesByCategory: placesByCategory,
    );
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// PlaceDetailState + provider (family by placeId)
// ─────────────────────────────────────────────────────────────────────────────

class PlaceDetailState {
  final ExplorePlace place;
  final ExploreCity city;
  final ExploreCategory category;
  final List<ExplorePlace> nearbyPlaces;
  final bool isInSchedule;

  const PlaceDetailState({
    required this.place,
    required this.city,
    required this.category,
    required this.nearbyPlaces,
    required this.isInSchedule,
  });

  PlaceDetailState copyWith({
    ExplorePlace? place,
    ExploreCity? city,
    ExploreCategory? category,
    List<ExplorePlace>? nearbyPlaces,
    bool? isInSchedule,
  }) =>
      PlaceDetailState(
        place: place ?? this.place,
        city: city ?? this.city,
        category: category ?? this.category,
        nearbyPlaces: nearbyPlaces ?? this.nearbyPlaces,
        isInSchedule: isInSchedule ?? this.isInSchedule,
      );
}

final placeDetailProvider =
    FutureProvider.autoDispose.family<PlaceDetailState, String>(
  (ref, placeId) async {
    final repo = ref.read(exploreRepositoryProvider);
    final place = repo.getPlaceById(placeId);
    if (place == null) throw StateError('Place not found: $placeId');
    final city = repo.getCityById(place.cityId);
    if (city == null) throw StateError('City not found: ${place.cityId}');
    final categories = repo.getCategoriesForCity(place.cityId);
    ExploreCategory category;
    try {
      category = categories.firstWhere((c) => c.id == place.categoryId);
    } catch (_) {
      category = const ExploreCategory(
        id: 'unknown',
        label: 'Other',
        emoji: '📍',
        accentHex: '7B5BFF',
        description: '',
      );
    }
    final nearby = repo.getNearbyPlaces(placeId, limit: 5);
    // Cross-check against the active schedule for isInSchedule flag.
    final scheduleState = ref.read(scheduleProvider);
    final activeItinerary = scheduleState.activeItineraryId != null
        ? ref
            .read(itineraryListProvider.notifier)
            .findById(scheduleState.activeItineraryId!)
        : null;
    final isInSchedule =
        activeItinerary?.slots.any((s) => s.placeId == placeId) ?? false;
    return PlaceDetailState(
      place: place,
      city: city,
      category: category,
      nearbyPlaces: nearby,
      isInSchedule: isInSchedule,
    );
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// ScheduleState + ScheduleNotifier
// ─────────────────────────────────────────────────────────────────────────────

class ScheduleState {
  final List<Itinerary> itineraries;
  final String? activeItineraryId;
  final int selectedDayIndex;
  final bool isAddingSlot;

  const ScheduleState({
    required this.itineraries,
    this.activeItineraryId,
    required this.selectedDayIndex,
    required this.isAddingSlot,
  });

  ScheduleState copyWith({
    List<Itinerary>? itineraries,
    String? activeItineraryId,
    bool clearActiveItinerary = false,
    int? selectedDayIndex,
    bool? isAddingSlot,
  }) =>
      ScheduleState(
        itineraries: itineraries ?? this.itineraries,
        activeItineraryId: clearActiveItinerary
            ? null
            : (activeItineraryId ?? this.activeItineraryId),
        selectedDayIndex: selectedDayIndex ?? this.selectedDayIndex,
        isAddingSlot: isAddingSlot ?? this.isAddingSlot,
      );

  Itinerary? get activeItinerary =>
      activeItineraryId == null
          ? null
          : itineraries.cast<Itinerary?>().firstWhere(
                (i) => i?.id == activeItineraryId,
                orElse: () => null,
              );
}

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  ScheduleNotifier()
      : super(const ScheduleState(
          itineraries: [],
          selectedDayIndex: 0,
          isAddingSlot: false,
        ));

  /// Creates a new itinerary, adds it to the list, and sets it as active.
  void createItinerary(Itinerary itinerary) {
    state = state.copyWith(
      itineraries: [...state.itineraries, itinerary],
      activeItineraryId: itinerary.id,
      selectedDayIndex: 0,
    );
  }

  void setActiveItinerary(String id) {
    state = state.copyWith(
      activeItineraryId: id,
      selectedDayIndex: 0,
    );
  }

  void selectDay(int index) {
    state = state.copyWith(selectedDayIndex: index);
  }

  void addSlot(ScheduleSlot slot) {
    final active = state.activeItinerary;
    if (active == null) return;
    final updated = active.copyWith(slots: [...active.slots, slot]);
    state = state.copyWith(
      itineraries: [
        for (final i in state.itineraries)
          if (i.id == updated.id) updated else i,
      ],
    );
  }

  void removeSlot(String slotId) {
    final active = state.activeItinerary;
    if (active == null) return;
    final updated = active.copyWith(
      slots: active.slots.where((s) => s.id != slotId).toList(),
    );
    state = state.copyWith(
      itineraries: [
        for (final i in state.itineraries)
          if (i.id == updated.id) updated else i,
      ],
    );
  }

  /// Moves a slot to a new date and start time, recalculating the end time.
  void moveSlot(String slotId, DateTime newDate, TimeOfDay newStartTime) {
    final active = state.activeItinerary;
    if (active == null) return;
    final slotIndex = active.slots.indexWhere((s) => s.id == slotId);
    if (slotIndex == -1) return;
    final original = active.slots[slotIndex];
    final durationMins = original.durationMinutes;
    final endTotalMins =
        newStartTime.hour * 60 + newStartTime.minute + durationMins;
    final newEndTime = TimeOfDay(
      hour: (endTotalMins ~/ 60).clamp(0, 23),
      minute: endTotalMins % 60,
    );
    final moved = original.copyWith(
      date: newDate,
      startTime: newStartTime,
      endTime: newEndTime,
    );
    final newSlots = List<ScheduleSlot>.from(active.slots);
    newSlots[slotIndex] = moved;
    final updated = active.copyWith(slots: newSlots);
    state = state.copyWith(
      itineraries: [
        for (final i in state.itineraries)
          if (i.id == updated.id) updated else i,
      ],
    );
  }

  void setIsAddingSlot(bool value) {
    state = state.copyWith(isAddingSlot: value);
  }

  /// Imports an auto-generated itinerary and activates it.
  /// If the same itinerary id already exists it is just selected.
  void importItinerary(Itinerary itinerary) {
    final alreadyExists = state.itineraries.any((i) => i.id == itinerary.id);
    if (alreadyExists) {
      state = state.copyWith(
        activeItineraryId: itinerary.id,
        selectedDayIndex: 0,
      );
      return;
    }
    state = state.copyWith(
      itineraries: [...state.itineraries, itinerary],
      activeItineraryId: itinerary.id,
      selectedDayIndex: 0,
    );
  }
}

final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, ScheduleState>(
  (ref) => ScheduleNotifier(),
);

// ─────────────────────────────────────────────────────────────────────────────
// AutoSuggestState + AutoSuggestNotifier
// ─────────────────────────────────────────────────────────────────────────────

class AutoSuggestState {
  /// Wizard step index: 0 = country, 1 = dates, 2 = categories, 3 = style, 4 = result.
  final int step;
  final AutoSuggestParams? params;
  final bool isGenerating;
  final Itinerary? generatedItinerary;
  final String? error;

  const AutoSuggestState({
    required this.step,
    this.params,
    required this.isGenerating,
    this.generatedItinerary,
    this.error,
  });

  AutoSuggestState copyWith({
    int? step,
    AutoSuggestParams? params,
    bool? isGenerating,
    Itinerary? generatedItinerary,
    bool clearItinerary = false,
    String? error,
    bool clearError = false,
  }) =>
      AutoSuggestState(
        step: step ?? this.step,
        params: params ?? this.params,
        isGenerating: isGenerating ?? this.isGenerating,
        generatedItinerary:
            clearItinerary ? null : (generatedItinerary ?? this.generatedItinerary),
        error: clearError ? null : (error ?? this.error),
      );
}

class AutoSuggestNotifier extends StateNotifier<AutoSuggestState> {
  final AutoSuggestService _service;

  AutoSuggestNotifier(this._service)
      : super(const AutoSuggestState(
          step: 0,
          isGenerating: false,
        ));

  /// Step 0 → 1: sets the country and optional preferred city.
  void setCountry(String countryId, {String? preferredCityId}) {
    final existing = state.params;
    final now = DateTime.now();
    final params = existing != null
        ? existing.copyWith(
            countryId: countryId,
            preferredCityId: preferredCityId,
          )
        : AutoSuggestParams(
            countryId: countryId,
            preferredCityId: preferredCityId,
            departureDate: now.add(const Duration(days: 30)),
            returnDate: now.add(const Duration(days: 37)),
            preferredCategoryIds: const [],
            travelStyle: 'balanced',
          );
    state = state.copyWith(
      params: params,
      step: 1,
      clearError: true,
    );
  }

  /// Step 1 → 2: sets departure and return dates.
  void setDates(DateTime departure, DateTime returnDate) {
    if (state.params == null) return;
    state = state.copyWith(
      params: state.params!.copyWith(
        departureDate: departure,
        returnDate: returnDate,
      ),
      step: 2,
      clearError: true,
    );
  }

  /// Step 2 → 3: sets preferred category ids.
  void setCategories(List<String> categoryIds) {
    if (state.params == null) return;
    state = state.copyWith(
      params: state.params!.copyWith(preferredCategoryIds: categoryIds),
      step: 3,
      clearError: true,
    );
  }

  /// Step 3: sets the travel style. Call [generate] afterwards.
  void setStyle(String style) {
    if (state.params == null) return;
    state = state.copyWith(
      params: state.params!.copyWith(travelStyle: style),
      clearError: true,
    );
  }

  /// Triggers the suggestion engine. Advances to step 4 while loading.
  Future<void> generate() async {
    if (state.params == null) {
      state = state.copyWith(error: 'Please complete all steps first.');
      return;
    }
    state = state.copyWith(isGenerating: true, clearError: true, step: 4);
    try {
      // Small delay so the loading state can render before the synchronous
      // generation work blocks the isolate.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final itinerary = _service.generate(state.params!);
      state = state.copyWith(
        isGenerating: false,
        generatedItinerary: itinerary,
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Could not generate itinerary: $e',
        step: 3,
      );
    }
  }

  void reset() {
    state = const AutoSuggestState(step: 0, isGenerating: false);
  }

  void goToStep(int step) {
    state = state.copyWith(step: step);
  }
}

final autoSuggestProvider =
    StateNotifierProvider<AutoSuggestNotifier, AutoSuggestState>(
  (ref) => AutoSuggestNotifier(ref.read(autoSuggestServiceProvider)),
);
