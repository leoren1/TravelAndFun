# Explore Index

**Discover more. Experience deeper. Collect moments.**

Explore Index is a Flutter travel-companion app that tracks every place you visit, measures how deeply you have explored a city across 10 categories, and tells you whether a destination is worth revisiting — all without an internet connection required for day-to-day use.

---

## Screenshots

| Dashboard | City Discovery | Discovery DNA | Worth Visiting Again |
|-----------|---------------|---------------|----------------------|
| *(coming soon)* | *(coming soon)* | *(coming soon)* | *(coming soon)* |

---

## Getting Started

```bash
git clone https://github.com/your-org/TravelAndFun.git
cd TravelAndFun
flutter pub get
flutter run
```

> **Minimum requirements:** Flutter 3.19+, Dart 3.0+, Android API 21+ / iOS 13+.

---

## Folder Map

```
lib/
├── main.dart                        # Entry point; Hive init + ProviderScope
├── app.dart                         # MaterialApp.router setup
│
├── core/
│   ├── constants/
│   │   ├── app_assets.dart          # Asset path constants
│   │   ├── app_colors.dart          # Brand palette
│   │   ├── app_spacing.dart         # Spacing tokens
│   │   └── app_text_styles.dart     # Typography definitions
│   ├── errors/
│   │   ├── app_exception.dart       # Base exception type
│   │   └── repository_exception.dart
│   ├── extensions/
│   │   ├── context_extensions.dart  # BuildContext helpers
│   │   └── num_extensions.dart
│   ├── router/
│   │   ├── app_router.dart          # GoRouter configuration
│   │   └── app_routes.dart          # Named route constants
│   ├── theme/
│   │   └── app_theme.dart           # ThemeData factory
│   └── utils/
│       ├── date_utils.dart
│       ├── distance_calculator.dart
│       └── result.dart              # Generic Result<T, E> wrapper
│
├── data/
│   ├── models/                      # Plain Dart value objects (no codegen)
│   │   ├── badge.dart
│   │   ├── category.dart            # CategoryType enum + extensions
│   │   ├── city.dart
│   │   ├── country.dart
│   │   ├── discovery_dna.dart
│   │   ├── event.dart
│   │   ├── place.dart
│   │   ├── user_profile.dart
│   │   └── visit.dart
│   ├── providers.dart               # All Riverpod providers (services + repos)
│   ├── repositories/                # Interfaces + StaticData implementations
│   │   ├── city_repository.dart
│   │   ├── city_repository_impl.dart
│   │   ├── country_repository.dart
│   │   ├── country_repository_impl.dart
│   │   ├── event_repository.dart
│   │   ├── event_repository_impl.dart
│   │   ├── place_repository.dart
│   │   ├── place_repository_impl.dart
│   │   ├── user_repository.dart
│   │   ├── user_repository_impl.dart
│   │   ├── visit_repository.dart
│   │   └── visit_repository_impl.dart
│   └── services/
│       ├── api_service.dart         # Abstract ApiService interface
│       ├── api_service_impl.dart    # Dio client → https://api.exploreindex.app/v1
│       ├── exif_service.dart        # native_exif wrapper
│       ├── local_storage_service.dart # Hive wrapper
│       ├── location_service.dart    # geolocator wrapper
│       ├── photo_verification_service.dart
│       └── static_data_service.dart # Reads bundled JSON from assets
│
├── domain/
│   └── usecases/                    # Pure Dart; no Flutter imports
│       ├── award_badges.dart
│       ├── calculate_category_discovery.dart
│       ├── calculate_city_discovery.dart
│       ├── calculate_country_discovery.dart
│       ├── calculate_world_discovery.dart
│       ├── compute_discovery_dna.dart
│       ├── compute_worth_visiting_again.dart
│       └── verify_visit.dart
│
├── l10n/                            # ARB localisation files
├── presentation/
│   ├── viewmodels/                  # Riverpod StateNotifiers / AsyncNotifiers
│   │   ├── category_detail_viewmodel.dart
│   │   ├── city_dashboard_viewmodel.dart
│   │   ├── country_detail_viewmodel.dart
│   │   ├── dashboard_viewmodel.dart
│   │   ├── discovery_dna_viewmodel.dart
│   │   ├── events_viewmodel.dart
│   │   ├── profile_viewmodel.dart
│   │   ├── verify_visit_viewmodel.dart
│   │   ├── world_map_viewmodel.dart
│   │   └── worth_it_again_viewmodel.dart
│   ├── views/                       # Full-screen pages (one folder per screen)
│   │   ├── category_detail/
│   │   ├── city_dashboard/
│   │   ├── country_detail/
│   │   ├── dashboard/
│   │   ├── discovery_dna/
│   │   ├── events/
│   │   ├── profile/
│   │   ├── verify_visit/
│   │   ├── world_map/
│   │   └── worth_it_again/
│   └── widgets/                     # Reusable UI components
│       ├── common/
│       │   ├── app_back_button.dart
│       │   ├── badge_hex.dart
│       │   ├── circular_progress_card.dart
│       │   ├── filter_chip_group.dart
│       │   ├── place_card.dart
│       │   ├── primary_button.dart
│       │   ├── progress_bar.dart
│       │   └── stat_chip.dart
│       └── nav/
│
└── static_data/                     # Bundled JSON (countries, cities, places…)
    ├── badges.json
    ├── cities.json
    ├── countries.json
    ├── events.json
    ├── places.json
    └── user_profile.json

test/
├── widget_test.dart                 # Default Flutter widget smoke test
└── domain/
    ├── calculate_city_discovery_test.dart
    ├── compute_discovery_dna_test.dart
    └── compute_worth_visiting_again_test.dart
```

---

## Swapping StaticDataService for the Real API

The app ships with a local `StaticDataService` so it works out of the box without a backend. When you are ready to point at the real REST API, make the following changes.

### 1. Where the wiring lives

Open `lib/data/providers.dart`. The five data-read repositories are currently wired like this:

```dart
final countryRepositoryProvider = Provider<CountryRepository>(
  (ref) => CountryRepositoryImpl(ref.read(staticDataServiceProvider)),
);

final cityRepositoryProvider = Provider<CityRepository>(
  (ref) => CityRepositoryImpl(ref.read(staticDataServiceProvider)),
);

final placeRepositoryProvider = Provider<PlaceRepository>(
  (ref) => PlaceRepositoryImpl(ref.read(staticDataServiceProvider)),
);

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepositoryImpl(ref.read(staticDataServiceProvider)),
);

// userRepositoryProvider accepts both StaticDataService and LocalStorageService
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepositoryImpl(
    staticDataService: ref.read(staticDataServiceProvider),
    localStorage: ref.read(localStorageServiceProvider),
  ),
);
```

### 2. What to change

Replace each `ref.read(staticDataServiceProvider)` argument with `ref.read(apiServiceProvider)` and update the corresponding `*RepositoryImpl` constructor to accept `ApiService` instead of `StaticDataService`:

```dart
// BEFORE
final countryRepositoryProvider = Provider<CountryRepository>(
  (ref) => CountryRepositoryImpl(ref.read(staticDataServiceProvider)),
);

// AFTER
final countryRepositoryProvider = Provider<CountryRepository>(
  (ref) => CountryRepositoryImpl(ref.read(apiServiceProvider)),
);
```

Repeat for `cityRepositoryProvider`, `placeRepositoryProvider`, `eventRepositoryProvider`, and `userRepositoryProvider`.

### 3. The Dio client is already wired

`lib/data/services/api_service_impl.dart` already contains a fully configured Dio client pointing at:

```
https://api.exploreindex.app/v1
```

All REST methods (`getCountries`, `getCitiesByCountry`, `getPlacesByCity`, `getEventsByCity`, `getVisitsByUser`, etc.) are implemented and ready to use — no `UnimplementedError` throws remain in the file. The only step left is to add your auth-token injection inside `_setupInterceptors()`:

```dart
onRequest: (options, handler) {
  // TODO: replace with a real token read from secure storage
  options.headers['Authorization'] = 'Bearer $yourToken';
  handler.next(options);
},
```

### 4. Zero ViewModel changes required

All ViewModels depend on the repository interfaces (`CountryRepository`, `CityRepository`, etc.), not on the service implementations. Swapping the provider binding is the only change needed — no ViewModel code is affected.

---

## Architecture Overview

Explore Index follows **MVVM + Repository** layered architecture:

```
UI (Views)
    ↕  watches / reads
ViewModels  (Riverpod StateNotifier / AsyncNotifier)
    ↕  calls
Repositories  (interfaces in data/repositories/)
    ↕  delegates to
Services  (StaticDataService | ApiServiceImpl | LocalStorageService)
    ↕
Data Sources  (bundled JSON assets | Hive | REST API)
```

Domain use cases (`domain/usecases/`) are plain Dart classes that take
models as constructor arguments and expose a single `execute()` method.
They contain all business logic and have zero Flutter dependencies, making
them trivially testable without a test harness or mocking framework.

---

## State Management

The project uses **Riverpod 2** (`flutter_riverpod: ^2.5.1`).

| Concept | How it is used |
|---------|----------------|
| `Provider` | Singletons: services, repositories |
| `AsyncNotifierProvider` | Screen-level async state (city data, places list) |
| `StateNotifierProvider` | Local UI state (filter selections, form state) |
| `ref.watch` | Reactive data binding in widgets |
| `ref.read` | One-shot reads inside event handlers |

All providers are declared in `lib/data/providers.dart` and are globally
accessible via `ProviderScope` at the root of the widget tree.

---

## Running Tests

```bash
# Run all tests
flutter test

# Run only domain unit tests
flutter test test/domain/

# Run a single test file with verbose output
flutter test test/domain/calculate_city_discovery_test.dart --reporter expanded

# Run with coverage (requires lcov)
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

The domain tests are pure Dart and do not require a running device or
emulator. They execute in milliseconds via the Dart VM test runner.

---

## Key Design Decisions

### No freezed — no build_runner

All models (`City`, `Place`, `Visit`, `DiscoveryDna`, etc.) are hand-written
plain Dart classes with `copyWith`, `toJson`, `fromJson`, `==`, and `hashCode`
implemented explicitly.

**Why:** `freezed` + `json_serializable` require `build_runner` to generate
code before every compile. This adds a mandatory build step, complicates CI
pipelines, and produces generated files that clutter version control diffs.
Plain Dart models are immediately readable, debuggable, and refactorable
without a code-generation phase. The trade-off is a few extra lines of
boilerplate per model — an acceptable cost for a codebase of this size.

### Pure domain use cases

Each business-logic operation is isolated in a standalone `UseCase` class
(e.g., `CalculateCategoryDiscovery`, `ComputeDiscoveryDna`). These classes:

- Accept only plain Dart models as constructor parameters.
- Expose a single `execute()` method with a clear return type.
- Have no Flutter, Riverpod, or I/O imports.

This makes them instantly unit-testable and reusable across any future
platform target (desktop, web, CLI scripts).

### StaticDataService as the default data source

Bundling all reference data (countries, cities, places, events) as JSON
assets means the app works on first install with zero network dependency.
The `StaticDataService` loads these assets asynchronously on first access
and caches the parsed results in memory. Swapping to the real API is a
single-file, five-line change (see the section above).

### Riverpod over BLoC / Provider

Riverpod's compile-time safety, auto-disposal, and first-class async support
remove the need for manual `dispose()` calls and StreamController management.
The `ref.watch` / `ref.read` distinction enforces correct reactive vs.
imperative usage without extra tooling.

---

## Contributing

1. Fork the repository and create a feature branch.
2. Run `flutter analyze` — zero warnings expected.
3. Add or update tests for any changed domain logic.
4. Open a pull request with a description of the change and its motivation.

---

## License

MIT — see `LICENSE` for details.
