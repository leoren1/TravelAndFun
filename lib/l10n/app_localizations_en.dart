// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Explore Index';

  @override
  String get worldExplored => 'World Explored';

  @override
  String get continueDiscovery => 'Continue Discovery';

  @override
  String get recentDiscoveries => 'Recent Discoveries';

  @override
  String get nextCityWorthRevisiting => 'Next City Worth Revisiting';

  @override
  String get yourTravelMap => 'Your Travel Map';

  @override
  String get countriesExplored => 'Countries Explored';

  @override
  String get citiesVisited => 'Cities Visited';

  @override
  String get placesVerified => 'Places Verified';

  @override
  String get discoveryProgress => 'Discovery Progress';

  @override
  String get topCity => 'Top City';

  @override
  String exploreCountry(String country) {
    return 'Explore $country';
  }

  @override
  String get cityDiscovery => 'City Discovery';

  @override
  String get worthVisitingAgain => 'Worth visiting again?';

  @override
  String get yes => 'YES';

  @override
  String get no => 'NO';

  @override
  String youStillHave(int percent) {
    return 'You still have $percent% undiscovered.';
  }

  @override
  String get missingCategories => 'Missing categories';

  @override
  String get createSecondTripPlan => 'Create Second Trip Plan';

  @override
  String get viewAllEvents => 'View All Events';

  @override
  String eventsIn(String city) {
    return 'Events in $city';
  }

  @override
  String get onlyThisWeek => 'Only this week';

  @override
  String get verifyYourVisit => 'Verify Your Visit';

  @override
  String get uploadPhoto => 'Upload photo';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get giveRating => 'Give rating';

  @override
  String get optionalNote => 'Optional note';

  @override
  String get leaveNote => 'Leave a note about your experience...';

  @override
  String get visitDate => 'Visit date';

  @override
  String get completeVisit => 'Complete Visit';

  @override
  String visitBoostHint(String city, double boost) {
    return 'Your visit will increase $city discovery by +$boost%';
  }

  @override
  String get verificationFailed => 'Verification failed';

  @override
  String get verificationPassed => 'Visit verified successfully!';

  @override
  String get errorNoExif => 'No EXIF data found in photo.';

  @override
  String get errorNoGps => 'Photo does not contain GPS location.';

  @override
  String get errorNoDate => 'Photo does not contain a date.';

  @override
  String errorTooFar(int distance) {
    return 'Photo was taken too far from this location (${distance}m away).';
  }

  @override
  String get errorOldPhoto => 'Photo is older than 14 days.';

  @override
  String get yourDiscoveryDna => 'Your Discovery DNA';

  @override
  String get travelStyleCategories => 'Your travel style in categories';

  @override
  String get categories => 'Categories';

  @override
  String get historicalPlaces => 'Historical Places';

  @override
  String get foodRestaurants => 'Food & Restaurants';

  @override
  String get cafes => 'Cafes';

  @override
  String get museumsArt => 'Museums & Art';

  @override
  String get routes => 'Routes';

  @override
  String get nature => 'Nature';

  @override
  String get nightlife => 'Nightlife';

  @override
  String get localMarkets => 'Local Markets';

  @override
  String get hiddenGems => 'Hidden Gems';

  @override
  String get events => 'Events';

  @override
  String get completed => 'Completed';

  @override
  String get notVerified => 'Not Verified';

  @override
  String get verified => 'Verified';

  @override
  String get all => 'All';

  @override
  String get mustVisit => 'Must Visit';

  @override
  String get hidden => 'Hidden';

  @override
  String get local => 'Local';

  @override
  String level(int number) {
    return 'Level $number';
  }

  @override
  String xpProgress(int current, int max) {
    return '$current / $max XP';
  }

  @override
  String get badges => 'Badges';

  @override
  String get yourStats => 'Your Stats';

  @override
  String get mostExploredCountry => 'Most explored country';

  @override
  String get mostCompletedCity => 'Most completed city';

  @override
  String get favoriteCategory => 'Favorite category';

  @override
  String get citiesExplored => 'Cities Explored';

  @override
  String get totalActivities => 'Total Activities';

  @override
  String get verifiedPhotos => 'Verified Photos';

  @override
  String get averageRating => 'Average Rating';

  @override
  String get seeAllCities => 'See All Cities';

  @override
  String get locked => 'Locked';

  @override
  String get today => 'Today';

  @override
  String shouldVisitAgain(String city) {
    return 'Should you visit $city again?';
  }
}
