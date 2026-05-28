import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/router/app_routes.dart';
import 'package:explore_index/presentation/views/city_dashboard/city_dashboard_view.dart';
import 'package:explore_index/presentation/views/category_detail/category_detail_view.dart';
import 'package:explore_index/presentation/views/country_detail/country_detail_view.dart';
import 'package:explore_index/presentation/views/dashboard/dashboard_view.dart';
import 'package:explore_index/presentation/views/discovery_dna/discovery_dna_view.dart';
import 'package:explore_index/presentation/views/events/events_view.dart';
import 'package:explore_index/presentation/views/my_page/my_page_view.dart';
import 'package:explore_index/presentation/views/my_plans/my_plans_view.dart';
import 'package:explore_index/presentation/views/photo_journal/photo_journal_view.dart';
import 'package:explore_index/presentation/views/profile/profile_view.dart';
import 'package:explore_index/presentation/views/social_feed/social_feed_view.dart';
import 'package:explore_index/presentation/views/trip_planner/trip_planner_view.dart';
import 'package:explore_index/presentation/views/verify_visit/verify_visit_view.dart';
import 'package:explore_index/presentation/views/world_map/world_map_view.dart';
import 'package:explore_index/presentation/views/worth_it_again/worth_it_again_view.dart';
import 'package:explore_index/presentation/widgets/nav/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Page Not Found'),
        leading: BackButton(onPressed: () => context.go(AppRoutes.dashboard)),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🗺️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Route not found',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardView()),
          ),
          GoRoute(
            path: AppRoutes.map,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: WorldMapView()),
          ),
          GoRoute(
            path: AppRoutes.social,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SocialFeedView()),
          ),
          GoRoute(
            path: AppRoutes.plans,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MyPlansView()),
          ),
          GoRoute(
            path: AppRoutes.myPage,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MyPageView()),
          ),
        ],
      ),

      // ── Push routes (no bottom nav) ──────────────────────────────────────

      GoRoute(
        path: AppRoutes.tripPlanner,
        builder: (context, state) => const TripPlannerView(),
      ),
      GoRoute(
        path: AppRoutes.journal,
        builder: (context, state) => const PhotoJournalView(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileView(),
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
        path: AppRoutes.dna,
        builder: (context, state) => const DiscoveryDnaView(),
      ),
      GoRoute(
        path: AppRoutes.discoveryDna,
        builder: (context, state) => const DiscoveryDnaView(),
      ),
    ],
  );
});
