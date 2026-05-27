import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// App name
  ///
  /// In en, this message translates to:
  /// **'Explore Index'**
  String get appName;

  /// No description provided for @worldExplored.
  ///
  /// In en, this message translates to:
  /// **'World Explored'**
  String get worldExplored;

  /// No description provided for @continueDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Continue Discovery'**
  String get continueDiscovery;

  /// No description provided for @recentDiscoveries.
  ///
  /// In en, this message translates to:
  /// **'Recent Discoveries'**
  String get recentDiscoveries;

  /// No description provided for @nextCityWorthRevisiting.
  ///
  /// In en, this message translates to:
  /// **'Next City Worth Revisiting'**
  String get nextCityWorthRevisiting;

  /// No description provided for @yourTravelMap.
  ///
  /// In en, this message translates to:
  /// **'Your Travel Map'**
  String get yourTravelMap;

  /// No description provided for @countriesExplored.
  ///
  /// In en, this message translates to:
  /// **'Countries Explored'**
  String get countriesExplored;

  /// No description provided for @citiesVisited.
  ///
  /// In en, this message translates to:
  /// **'Cities Visited'**
  String get citiesVisited;

  /// No description provided for @placesVerified.
  ///
  /// In en, this message translates to:
  /// **'Places Verified'**
  String get placesVerified;

  /// No description provided for @discoveryProgress.
  ///
  /// In en, this message translates to:
  /// **'Discovery Progress'**
  String get discoveryProgress;

  /// No description provided for @topCity.
  ///
  /// In en, this message translates to:
  /// **'Top City'**
  String get topCity;

  /// No description provided for @exploreCountry.
  ///
  /// In en, this message translates to:
  /// **'Explore {country}'**
  String exploreCountry(String country);

  /// No description provided for @cityDiscovery.
  ///
  /// In en, this message translates to:
  /// **'City Discovery'**
  String get cityDiscovery;

  /// No description provided for @worthVisitingAgain.
  ///
  /// In en, this message translates to:
  /// **'Worth visiting again?'**
  String get worthVisitingAgain;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'YES'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'NO'**
  String get no;

  /// No description provided for @youStillHave.
  ///
  /// In en, this message translates to:
  /// **'You still have {percent}% undiscovered.'**
  String youStillHave(int percent);

  /// No description provided for @missingCategories.
  ///
  /// In en, this message translates to:
  /// **'Missing categories'**
  String get missingCategories;

  /// No description provided for @createSecondTripPlan.
  ///
  /// In en, this message translates to:
  /// **'Create Second Trip Plan'**
  String get createSecondTripPlan;

  /// No description provided for @viewAllEvents.
  ///
  /// In en, this message translates to:
  /// **'View All Events'**
  String get viewAllEvents;

  /// No description provided for @eventsIn.
  ///
  /// In en, this message translates to:
  /// **'Events in {city}'**
  String eventsIn(String city);

  /// No description provided for @onlyThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Only this week'**
  String get onlyThisWeek;

  /// No description provided for @verifyYourVisit.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Visit'**
  String get verifyYourVisit;

  /// No description provided for @uploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload photo'**
  String get uploadPhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @giveRating.
  ///
  /// In en, this message translates to:
  /// **'Give rating'**
  String get giveRating;

  /// No description provided for @optionalNote.
  ///
  /// In en, this message translates to:
  /// **'Optional note'**
  String get optionalNote;

  /// No description provided for @leaveNote.
  ///
  /// In en, this message translates to:
  /// **'Leave a note about your experience...'**
  String get leaveNote;

  /// No description provided for @visitDate.
  ///
  /// In en, this message translates to:
  /// **'Visit date'**
  String get visitDate;

  /// No description provided for @completeVisit.
  ///
  /// In en, this message translates to:
  /// **'Complete Visit'**
  String get completeVisit;

  /// No description provided for @visitBoostHint.
  ///
  /// In en, this message translates to:
  /// **'Your visit will increase {city} discovery by +{boost}%'**
  String visitBoostHint(String city, double boost);

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailed;

  /// No description provided for @verificationPassed.
  ///
  /// In en, this message translates to:
  /// **'Visit verified successfully!'**
  String get verificationPassed;

  /// No description provided for @errorNoExif.
  ///
  /// In en, this message translates to:
  /// **'No EXIF data found in photo.'**
  String get errorNoExif;

  /// No description provided for @errorNoGps.
  ///
  /// In en, this message translates to:
  /// **'Photo does not contain GPS location.'**
  String get errorNoGps;

  /// No description provided for @errorNoDate.
  ///
  /// In en, this message translates to:
  /// **'Photo does not contain a date.'**
  String get errorNoDate;

  /// No description provided for @errorTooFar.
  ///
  /// In en, this message translates to:
  /// **'Photo was taken too far from this location ({distance}m away).'**
  String errorTooFar(int distance);

  /// No description provided for @errorOldPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo is older than 14 days.'**
  String get errorOldPhoto;

  /// No description provided for @yourDiscoveryDna.
  ///
  /// In en, this message translates to:
  /// **'Your Discovery DNA'**
  String get yourDiscoveryDna;

  /// No description provided for @travelStyleCategories.
  ///
  /// In en, this message translates to:
  /// **'Your travel style in categories'**
  String get travelStyleCategories;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @historicalPlaces.
  ///
  /// In en, this message translates to:
  /// **'Historical Places'**
  String get historicalPlaces;

  /// No description provided for @foodRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Food & Restaurants'**
  String get foodRestaurants;

  /// No description provided for @cafes.
  ///
  /// In en, this message translates to:
  /// **'Cafes'**
  String get cafes;

  /// No description provided for @museumsArt.
  ///
  /// In en, this message translates to:
  /// **'Museums & Art'**
  String get museumsArt;

  /// No description provided for @routes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get routes;

  /// No description provided for @nature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get nature;

  /// No description provided for @nightlife.
  ///
  /// In en, this message translates to:
  /// **'Nightlife'**
  String get nightlife;

  /// No description provided for @localMarkets.
  ///
  /// In en, this message translates to:
  /// **'Local Markets'**
  String get localMarkets;

  /// No description provided for @hiddenGems.
  ///
  /// In en, this message translates to:
  /// **'Hidden Gems'**
  String get hiddenGems;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @notVerified.
  ///
  /// In en, this message translates to:
  /// **'Not Verified'**
  String get notVerified;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @mustVisit.
  ///
  /// In en, this message translates to:
  /// **'Must Visit'**
  String get mustVisit;

  /// No description provided for @hidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hidden;

  /// No description provided for @local.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get local;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level {number}'**
  String level(int number);

  /// No description provided for @xpProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {max} XP'**
  String xpProgress(int current, int max);

  /// No description provided for @badges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badges;

  /// No description provided for @yourStats.
  ///
  /// In en, this message translates to:
  /// **'Your Stats'**
  String get yourStats;

  /// No description provided for @mostExploredCountry.
  ///
  /// In en, this message translates to:
  /// **'Most explored country'**
  String get mostExploredCountry;

  /// No description provided for @mostCompletedCity.
  ///
  /// In en, this message translates to:
  /// **'Most completed city'**
  String get mostCompletedCity;

  /// No description provided for @favoriteCategory.
  ///
  /// In en, this message translates to:
  /// **'Favorite category'**
  String get favoriteCategory;

  /// No description provided for @citiesExplored.
  ///
  /// In en, this message translates to:
  /// **'Cities Explored'**
  String get citiesExplored;

  /// No description provided for @totalActivities.
  ///
  /// In en, this message translates to:
  /// **'Total Activities'**
  String get totalActivities;

  /// No description provided for @verifiedPhotos.
  ///
  /// In en, this message translates to:
  /// **'Verified Photos'**
  String get verifiedPhotos;

  /// No description provided for @averageRating.
  ///
  /// In en, this message translates to:
  /// **'Average Rating'**
  String get averageRating;

  /// No description provided for @seeAllCities.
  ///
  /// In en, this message translates to:
  /// **'See All Cities'**
  String get seeAllCities;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @shouldVisitAgain.
  ///
  /// In en, this message translates to:
  /// **'Should you visit {city} again?'**
  String shouldVisitAgain(String city);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
