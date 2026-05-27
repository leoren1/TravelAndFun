class AppRoutes {
  AppRoutes._();

  static const String dashboard      = '/';
  static const String map            = '/map';
  static const String cities         = '/cities';
  static const String profile        = '/profile';
  static const String countryDetail  = '/country/:countryId';
  static const String cityDashboard  = '/city/:cityId';
  static const String categoryDetail = '/city/:cityId/category/:cat';
  static const String events         = '/city/:cityId/events';
  static const String worthAgain     = '/city/:cityId/worth-again';
  static const String verifyVisit    = '/place/:placeId/verify';
  static const String discoveryDna   = '/profile/dna';

  static String countryDetailPath(String countryId) => '/country/$countryId';
  static String cityDashboardPath(String cityId) => '/city/$cityId';
  static String categoryDetailPath(String cityId, String cat) => '/city/$cityId/category/$cat';
  static String eventsPath(String cityId) => '/city/$cityId/events';
  static String worthAgainPath(String cityId) => '/city/$cityId/worth-again';
  static String verifyVisitPath(String placeId) => '/place/$placeId/verify';
}
