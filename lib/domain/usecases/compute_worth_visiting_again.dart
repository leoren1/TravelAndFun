// lib/domain/usecases/compute_worth_visiting_again.dart

import 'package:explore_index/data/models/category.dart';
import 'package:explore_index/data/models/city.dart';
import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/models/visit.dart';
import 'package:explore_index/domain/usecases/calculate_category_discovery.dart';
import 'package:explore_index/domain/usecases/calculate_city_discovery.dart';

class WorthVisitingResult {
  final bool worthIt;
  final double discoveryPercent;
  final String reason;
  final List<CategoryType> missingCategories;
  final String insightParagraph;
  final List<String> tripPlanPlaceIds;

  const WorthVisitingResult({
    required this.worthIt,
    required this.discoveryPercent,
    required this.reason,
    required this.missingCategories,
    required this.insightParagraph,
    required this.tripPlanPlaceIds,
  });
}

class ComputeWorthVisitingAgain {
  final City city;
  final List<Visit> visits;
  final List<Place> places;

  const ComputeWorthVisitingAgain({
    required this.city,
    required this.visits,
    required this.places,
  });

  WorthVisitingResult execute() {
    final cityDiscovery = CalculateCityDiscovery(
      city: city,
      visits: visits,
      places: places,
    ).execute();

    final catCalc = CalculateCategoryDiscovery(
      city: city,
      visits: visits,
      places: places,
    );
    final allCatDiscoveries = catCalc.executeAll();

    // Only consider categories that actually have places in this city.
    // Categories with no places return 0% but can never be improved by visiting.
    final activeCatDiscoveries = Map.fromEntries(
      allCatDiscoveries.entries.where((e) =>
          places.any((p) => p.cityId == city.id && p.category == e.key)),
    );

    final worthIt = cityDiscovery >= 10 && cityDiscovery <= 80;

    final sorted = activeCatDiscoveries.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final missingCategories = sorted.take(3).map((e) => e.key).toList();

    final reason = worthIt
        ? 'Major categories are still unexplored (${missingCategories.map((c) => c.displayName).join(', ')})'
        : cityDiscovery > 80
            ? 'You have thoroughly explored this city!'
            : 'Start your first visit to discover this city.';

    final insightTemplate = _selectTemplate(cityDiscovery, missingCategories);

    // Top 5 unvisited places from missing categories
    final visitedPlaceIds = visits.map((v) => v.placeId).toSet();
    final tripPlanPlaces = places
        .where(
          (p) =>
              p.cityId == city.id &&
              missingCategories.contains(p.category) &&
              !visitedPlaceIds.contains(p.id),
        )
        .take(5)
        .map((p) => p.id)
        .toList();

    return WorthVisitingResult(
      worthIt: worthIt,
      discoveryPercent: cityDiscovery,
      reason: reason,
      missingCategories: missingCategories,
      insightParagraph: insightTemplate,
      tripPlanPlaceIds: tripPlanPlaces,
    );
  }

  String _selectTemplate(double discovery, List<CategoryType> missing) {
    final missingNames = missing.map((c) => c.displayName).join(', ');
    if (discovery < 10) {
      return 'Your first visit was just the beginning. The city has much more to offer — start with ${missing.isNotEmpty ? missing.first.displayName : "new experiences"} next time.';
    } else if (discovery < 30) {
      return 'Your first visit was mostly historical. A second visit should focus on local life, food, and hidden neighborhoods. Don\'t miss: $missingNames.';
    } else if (discovery < 50) {
      return 'You know the highlights. Dive deeper into $missingNames to truly understand the soul of this city.';
    } else if (discovery < 80) {
      return 'You are getting close to mastering this city. Focus on $missingNames and you will become a true local expert.';
    } else {
      return 'You have explored this city thoroughly. Consider yourself a local expert!';
    }
  }
}
