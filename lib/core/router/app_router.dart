import 'package:explore_index/core/router/app_routes.dart';
import 'package:explore_index/presentation/views/city_dashboard/city_dashboard_view.dart';
import 'package:explore_index/presentation/views/category_detail/category_detail_view.dart';
import 'package:explore_index/presentation/views/country_detail/country_detail_view.dart';
import 'package:explore_index/presentation/views/dashboard/dashboard_view.dart';
import 'package:explore_index/presentation/views/discovery_dna/discovery_dna_view.dart';
import 'package:explore_index/presentation/views/events/events_view.dart';
import 'package:explore_index/presentation/views/profile/profile_view.dart';
import 'package:explore_index/presentation/views/verify_visit/verify_visit_view.dart';
import 'package:explore_index/presentation/views/world_map/cities_list_view.dart';
import 'package:explore_index/presentation/views/world_map/world_map_view.dart';
import 'package:explore_index/presentation/views/worth_it_again/worth_it_again_view.dart';
import 'package:explore_index/presentation/widgets/nav/bottom_nav_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// TODO(social): Future routes: /social/feed, /social/friends, /social/chat/:userId
// Reserve lib/presentation/views/social/ for these features.

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) => const NoTransitionPage(child: DashboardView()),
          ),
          GoRoute(
            path: AppRoutes.map,
            pageBuilder: (context, state) => const NoTransitionPage(child: WorldMapView()),
          ),
          GoRoute(
            path: AppRoutes.cities,
            pageBuilder: (context, state) => const NoTransitionPage(child: CitiesListView()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => const NoTransitionPage(child: ProfileView()),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.countryDetail,
        builder: (context, state) {
          final countryId = state.pathParameters['countryId']!;
          return CountryDetailView(countryId: countryId);
        },
      ),
      GoRoute(
        path: AppRoutes.cityDashboard,
        builder: (context, state) {
          final cityId = state.pathParameters['cityId']!;
          return CityDashboardView(cityId: cityId);
        },
      ),
      GoRoute(
        path: AppRoutes.categoryDetail,
        builder: (context, state) {
          final cityId = state.pathParameters['cityId']!;
          final cat    = state.pathParameters['cat']!;
          return CategoryDetailView(cityId: cityId, categoryName: cat);
        },
      ),
      GoRoute(
        path: AppRoutes.events,
        builder: (context, state) {
          final cityId = state.pathParameters['cityId']!;
          return EventsView(cityId: cityId);
        },
      ),
      GoRoute(
        path: AppRoutes.worthAgain,
        builder: (context, state) {
          final cityId = state.pathParameters['cityId']!;
          return WorthItAgainView(cityId: cityId);
        },
      ),
      GoRoute(
        path: AppRoutes.verifyVisit,
        builder: (context, state) {
          final placeId = state.pathParameters['placeId']!;
          return VerifyVisitView(placeId: placeId);
        },
      ),
      GoRoute(
        path: AppRoutes.discoveryDna,
        builder: (context, state) => const DiscoveryDnaView(),
      ),
    ],
  );
});

