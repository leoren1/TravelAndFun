class AppRoutes {
  AppRoutes._();

  static const String dashboard      = '/';
  static const String map            = '/map';
  static const String social         = '/social';
  static const String journal        = '/journal';
  static const String profile        = '/profile';
  static const String plans          = '/plans';
  static const String myPage         = '/me';
  static const String tripPlanner    = '/trip-planner';
  static const String countryDetail  = '/country/:countryId';
  static const String cityDashboard  = '/city/:cityId';
  static const String categoryDetail = '/city/:cityId/category/:cat';
  static const String events         = '/city/:cityId/events';
  static const String worthAgain     = '/city/:cityId/worth-again';
  static const String verifyVisit    = '/place/:placeId/verify';
  static const String dna            = '/dna';
  static const String discoveryDna   = '/profile/dna'; // kept for compat

  // ── New Immersive Trip Planner routes ──────────────────────────────────────
  // The /trip-planner root now shows the new TripMainView (immersive portal).
  // Old popup-based TripPlannerView is replaced entirely.

  /// Immersive country exploration page.
  static const String exploreCountry  = '/trip-planner/country/:countryId';

  /// Full-page city discovery with categories & places.
  static const String exploreCity     = '/trip-planner/city/:cityId';

  /// Place detail with gallery, nearby recommendations & schedule CTA.
  static const String explorePlace    = '/trip-planner/place/:placeId';

  /// Visual timeline schedule (all itineraries).
  static const String schedule        = '/trip-planner/schedule';

  /// AI auto-suggest flow (country → dates → categories → style → result).
  static const String autoSuggest     = '/trip-planner/auto-suggest';

  // ── Path builders ─────────────────────────────────────────────────────────
  static String exploreCountryPath(String countryId) => '/trip-planner/country/$countryId';
  static String exploreCityPath(String cityId)       => '/trip-planner/city/$cityId';
  static String explorePlacePath(String placeId)     => '/trip-planner/place/$placeId';

  // ── Legacy routes (existing discovery module — untouched) ─────────────────
  // Legacy alias kept so existing code that references AppRoutes.cities still compiles.
  static const String cities = '/cities';

  static String countryDetailPath(String countryId) => '/country/$countryId';
  static String cityDashboardPath(String cityId) => '/city/$cityId';
  static String categoryDetailPath(String cityId, String cat) => '/city/$cityId/category/$cat';
  static String eventsPath(String cityId) => '/city/$cityId/events';
  static String worthAgainPath(String cityId) => '/city/$cityId/worth-again';
  static String verifyVisitPath(String placeId) => '/place/$placeId/verify';
}
