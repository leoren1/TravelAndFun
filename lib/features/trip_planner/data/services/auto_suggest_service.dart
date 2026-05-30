import 'package:explore_index/features/trip_planner/data/models/auto_suggest_params.dart';
import 'package:explore_index/features/trip_planner/data/models/explore_category.dart';
import 'package:explore_index/features/trip_planner/data/models/explore_place.dart';
import 'package:explore_index/features/trip_planner/data/models/itinerary.dart';
import 'package:explore_index/features/trip_planner/data/models/schedule_slot.dart';
import 'package:explore_index/features/trip_planner/data/repositories/i_explore_repository.dart';
import 'package:flutter/material.dart';

class AutoSuggestService {
  final IExploreRepository _repo;
  AutoSuggestService(this._repo);

  /// Generates a complete multi-day itinerary based on user preferences.
  ///
  /// Algorithm:
  /// 1. Collect all places for the selected country (all cities or preferred city).
  /// 2. Filter by preferred categories when supplied.
  /// 3. Sort: highlight places first, then mustVisit tier, then by rating desc.
  /// 4. De-duplicate: a place appears at most once across the itinerary.
  /// 5. Distribute places across days according to travelStyle slotsPerDay.
  /// 6. For multi-city packed trips, group days by city (1-2 cities per day).
  /// 7. Assign start times sequentially with gaps; derive end times from
  ///    parsed estimatedDuration.
  Itinerary generate(AutoSuggestParams params) {
    final country = _repo.getCountryById(params.countryId);
    final countryName = country?.name ?? params.countryId;
    final countryFlag = country?.flagEmoji ?? '🌍';

    // 1. Gather candidate places -----------------------------------------------
    final List<ExplorePlace> candidates;
    if (params.preferredCityId != null) {
      candidates = _repo.getPlacesForCity(params.preferredCityId!);
    } else {
      candidates = _repo
          .getCitiesForCountry(params.countryId)
          .expand((city) => _repo.getPlacesForCity(city.id))
          .toList();
    }

    // 2. Filter by preferred categories -----------------------------------------
    final filtered = params.preferredCategoryIds.isEmpty
        ? candidates
        : candidates
            .where((p) =>
                params.preferredCategoryIds.contains(p.categoryId))
            .toList();

    // Fall back to all candidates if filtering leaves too few places
    final pool = filtered.length >= params.slotsPerDay ? filtered : candidates;

    // 3. Sort: highlights → mustVisit tier → rating desc -----------------------
    final sorted = List<ExplorePlace>.from(pool)
      ..sort((a, b) {
        if (a.isHighlight && !b.isHighlight) return -1;
        if (!a.isHighlight && b.isHighlight) return 1;
        final tierA = _tierOrder(a.tier);
        final tierB = _tierOrder(b.tier);
        if (tierA != tierB) return tierA.compareTo(tierB);
        return b.rating.compareTo(a.rating);
      });

    // 4. Build city rotation for multi-city trips ------------------------------
    final cityIds = params.preferredCityId != null
        ? [params.preferredCityId!]
        : _repo
            .getCitiesForCountry(params.countryId)
            .map((c) => c.id)
            .toList();

    // 5. Assign places to days -------------------------------------------------
    final slots = <ScheduleSlot>[];
    // Track per-day used places to allow the same place on different days
    // (recycling for long trips), but prevent duplicates within a single day.
    final usedPlaceIdsGlobal = <String>{};
    int placeIndex = 0;

    // Decide how many slots per day considering realistic daily time budget.
    // From 09:00 to 20:00 = 660 minutes. Average visit ≈ 120 min + 30 gap = 150.
    // Max realistic slots = 660 / 150 ≈ 4.  Cap packed at 4 as well.
    final effectiveSlotsPerDay = params.slotsPerDay.clamp(1, 4);

    // Max daily start time: no new slot may begin after 18:00.
    const int _kDailyStartCutoff = 18 * 60; // 18:00

    for (int dayIndex = 0; dayIndex < params.tripDays; dayIndex++) {
      final date = DateTime(
        params.departureDate.year,
        params.departureDate.month,
        params.departureDate.day + dayIndex,
      );

      // Determine which city (or cities) to use for this day
      final dayCityId = cityIds[dayIndex % cityIds.length];
      final city = _repo.getCityById(dayCityId);
      final cityName = city?.name ?? dayCityId;

      // For packed style, optionally mix in places from a second city on
      // the same day (afternoon visit to adjacent city)
      final secondCityId = params.travelStyle == 'packed' && cityIds.length > 1
          ? cityIds[(dayIndex + 1) % cityIds.length]
          : null;
      final secondCity =
          secondCityId != null ? _repo.getCityById(secondCityId) : null;

      final slotsThisDay = effectiveSlotsPerDay;
      // For packed trips, split day: first half from primary city, second half
      // from second city.
      final splitAtSlot =
          secondCityId != null ? (slotsThisDay / 2).ceil() : slotsThisDay;

      int currentMinutes = 9 * 60; // 9:00 AM start
      // Per-day set: prevent the same place twice on the same calendar day.
      final usedToday = <String>{};

      for (int slotIndex = 0; slotIndex < slotsThisDay; slotIndex++) {
        // Stop if next slot would start at or after 18:00
        if (currentMinutes >= _kDailyStartCutoff) break;

        // Decide which city pool to draw from for this slot.
        final String activeCityId;
        final String activeCityName;
        if (secondCityId != null && slotIndex >= splitAtSlot) {
          activeCityId = secondCityId;
          activeCityName = secondCity?.name ?? secondCityId;
        } else {
          activeCityId = dayCityId;
          activeCityName = cityName;
        }

        // Find next unused (globally) place for this city.
        ExplorePlace? place;
        for (int i = placeIndex; i < sorted.length; i++) {
          final candidate = sorted[i];
          if (!usedPlaceIdsGlobal.contains(candidate.id) &&
              !usedToday.contains(candidate.id) &&
              candidate.cityId == activeCityId) {
            place = candidate;
            placeIndex = i + 1;
            break;
          }
        }
        // If no city-specific unused place found, take any globally unused place
        if (place == null) {
          for (int i = 0; i < sorted.length; i++) {
            final candidate = sorted[i];
            if (!usedPlaceIdsGlobal.contains(candidate.id) &&
                !usedToday.contains(candidate.id)) {
              place = candidate;
              break;
            }
          }
        }
        // All places globally exhausted → recycle (allow revisits on new days)
        if (place == null) {
          usedPlaceIdsGlobal.clear();
          placeIndex = 0;
          for (int i = 0; i < sorted.length; i++) {
            final candidate = sorted[i];
            if (!usedToday.contains(candidate.id) &&
                candidate.cityId == activeCityId) {
              place = candidate;
              placeIndex = i + 1;
              break;
            }
          }
          // If still null (only 0 places total), abort day
          if (place == null) break;
        }

        usedPlaceIdsGlobal.add(place.id);
        usedToday.add(place.id);

        final durationMinutes = _parseDurationToMinutes(place.estimatedDuration);
        final startHour = currentMinutes ~/ 60;
        final startMin = currentMinutes % 60;

        // Cap slot end at 20:00 so evenings stay free
        final rawEnd = currentMinutes + durationMinutes;
        final cappedEnd = rawEnd.clamp(currentMinutes, 20 * 60);
        final endHour = cappedEnd ~/ 60;
        final endMin = cappedEnd % 60;

        // Fetch category emoji
        final categories = _repo.getCategoriesForCity(place.cityId);
        final ExploreCategory? cat = _findCategory(categories, place.categoryId);

        slots.add(
          ScheduleSlot(
            id: '${place.id}_day${dayIndex}_slot$slotIndex',
            placeId: place.id,
            placeName: place.name,
            cityId: activeCityId,
            cityName: activeCityName,
            countryName: countryName,
            date: date,
            startTime: TimeOfDay(hour: startHour, minute: startMin),
            endTime: TimeOfDay(hour: endHour, minute: endMin),
            categoryId: place.categoryId,
            categoryEmoji: cat?.emoji ?? '📍',
            gradientStartHex: place.gradientStartHex,
            gradientEndHex: place.gradientEndHex,
            notes: place.bestVisitTime,
          ),
        );

        // Advance current time: capped duration + 30-minute travel/rest gap
        currentMinutes = cappedEnd + 30;

        // For packed trips with a city switch, add a 60-minute transit gap
        if (secondCityId != null && slotIndex == splitAtSlot - 1) {
          currentMinutes += 60;
        }
      }
    }

    // 6. Determine unique city ids used ----------------------------------------
    final usedCityIds =
        slots.map((s) => s.cityId).toSet().toList();

    // 7. Build itinerary title --------------------------------------------------
    final title = _buildTitle(params, countryName, usedCityIds);

    return Itinerary(
      id: 'auto_${params.countryId}_${params.departureDate.millisecondsSinceEpoch}',
      title: title,
      countryId: params.countryId,
      countryName: countryName,
      countryFlag: countryFlag,
      cityIds: usedCityIds,
      startDate: params.departureDate,
      endDate: params.returnDate,
      slots: slots,
      isAutoGenerated: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  int _tierOrder(DiscoveryTier tier) => switch (tier) {
        DiscoveryTier.mustVisit => 0,
        DiscoveryTier.popular => 1,
        DiscoveryTier.hiddenGem => 2,
      };

  /// Parses duration strings like "2–3 hours", "30 min", "Half day",
  /// "Full day", "45 min–1 hour" into a minutes integer.
  int _parseDurationToMinutes(String duration) {
    final lower = duration.toLowerCase().trim();

    if (lower.contains('full day')) return 7 * 60; // 7 hours
    if (lower.contains('half day')) return 4 * 60; // 4 hours
    if (lower == 'self-paced') return 60;

    // Match patterns like "2–3 hours", "1–2 hours", "4–5 hours"
    final rangeHoursRe =
        RegExp(r'(\d+(?:\.\d+)?)\s*[–\-]\s*(\d+(?:\.\d+)?)\s*h');
    final rangeMatch = rangeHoursRe.firstMatch(lower);
    if (rangeMatch != null) {
      final lo = double.parse(rangeMatch.group(1)!);
      final hi = double.parse(rangeMatch.group(2)!);
      return ((lo + hi) / 2 * 60).round();
    }

    // Match "45 min–1 hour"
    final mixedRe =
        RegExp(r'(\d+)\s*min\s*[–\-]\s*(\d+(?:\.\d+)?)\s*h');
    final mixedMatch = mixedRe.firstMatch(lower);
    if (mixedMatch != null) {
      final mins = int.parse(mixedMatch.group(1)!);
      final hrs = double.parse(mixedMatch.group(2)!);
      return ((mins + hrs * 60) / 2).round();
    }

    // Match "30 min" / "45 min"
    final minRe = RegExp(r'(\d+)\s*min');
    final minMatch = minRe.firstMatch(lower);
    if (minMatch != null) {
      return int.parse(minMatch.group(1)!);
    }

    // Match single "2 hours" / "2h"
    final singleHourRe = RegExp(r'(\d+(?:\.\d+)?)\s*h');
    final singleMatch = singleHourRe.firstMatch(lower);
    if (singleMatch != null) {
      return (double.parse(singleMatch.group(1)!) * 60).round();
    }

    // Match "30 min" variant with "–" only
    final rangeMinRe =
        RegExp(r'(\d+)\s*[–\-]\s*(\d+)\s*min');
    final rangeMinMatch = rangeMinRe.firstMatch(lower);
    if (rangeMinMatch != null) {
      final lo = int.parse(rangeMinMatch.group(1)!);
      final hi = int.parse(rangeMinMatch.group(2)!);
      return ((lo + hi) / 2).round();
    }

    return 90; // Default fallback: 1.5 hours
  }

  ExploreCategory? _findCategory(
      List<ExploreCategory> cats, String categoryId) {
    try {
      return cats.firstWhere((c) => c.id == categoryId);
    } catch (_) {
      return null;
    }
  }

  String _buildTitle(
    AutoSuggestParams params,
    String countryName,
    List<String> usedCityIds,
  ) {
    final styleLabel = switch (params.travelStyle) {
      'relaxed' => 'Relaxed',
      'packed' => 'Grand',
      _ => 'Classic',
    };

    if (usedCityIds.length == 1) {
      final city = _repo.getCityById(usedCityIds.first);
      final cityName = city?.name ?? usedCityIds.first;
      return '$styleLabel $cityName Experience';
    }

    if (usedCityIds.length == 2) {
      final c1 = _repo.getCityById(usedCityIds[0])?.name ?? usedCityIds[0];
      final c2 = _repo.getCityById(usedCityIds[1])?.name ?? usedCityIds[1];
      return '$styleLabel $c1 & $c2';
    }

    return '$styleLabel $countryName ${params.tripDays}-Day Journey';
  }
}
