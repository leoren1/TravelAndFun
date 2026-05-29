// AutoSuggestView — luxury AI travel concierge wizard.
// 5-step flow: country → dates → categories → style → result.
// Cinematic dark theme; generating overlay is hypnotic; result feels like
// unwrapping a personalised gift.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/features/trip_planner/data/models/auto_suggest_params.dart';
import 'package:explore_index/features/trip_planner/data/models/explore_country.dart';
import 'package:explore_index/features/trip_planner/data/models/itinerary.dart';
import 'package:explore_index/features/trip_planner/data/static/explore_static_data.dart';
import 'package:explore_index/features/trip_planner/presentation/providers/explore_providers.dart';
import 'package:explore_index/features/trip_planner/presentation/widgets/tp_cinematic_header.dart';
import 'package:explore_index/features/trip_planner/presentation/widgets/tp_glass_card.dart';
import 'package:explore_index/core/router/app_routes.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Step metadata
// ─────────────────────────────────────────────────────────────────────────────

const _stepTitles = [
  'Choose Destination',
  'Set Travel Dates',
  'Your Interests',
  'Travel Style',
  'Your Itinerary',
];

const _stepSubtitles = [
  'Where do you want to go?',
  'How long is your trip?',
  'What do you love to explore?',
  'How packed should your days be?',
  'Your personalised journey',
];

// ─────────────────────────────────────────────────────────────────────────────
// Root widget
// ─────────────────────────────────────────────────────────────────────────────

class AutoSuggestView extends ConsumerStatefulWidget {
  const AutoSuggestView({super.key});

  @override
  ConsumerState<AutoSuggestView> createState() => _AutoSuggestViewState();
}

class _AutoSuggestViewState extends ConsumerState<AutoSuggestView>
    with TickerProviderStateMixin {
  // Pulse controller for the generating overlay icon
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _goBack(AutoSuggestState state) {
    if (state.step > 0) {
      ref.read(autoSuggestProvider.notifier).goToStep(state.step - 1);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(autoSuggestProvider);

    return Scaffold(
      backgroundColor: context.appColors.background,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              _AutoSuggestHeader(
                state: state,
                onBack: () => _goBack(state),
              ),
              _StepIndicator(currentStep: state.step),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(parent: anim, curve: Curves.easeOut),
                      ),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey<int>(state.step),
                    child: _buildStepContent(state),
                  ),
                ),
              ),
            ],
          ),

          // Generating overlay
          if (state.isGenerating)
            _GeneratingOverlay(
              pulseCtrl: _pulseCtrl,
              state: state,
            ),
        ],
      ),
    );
  }

  Widget _buildStepContent(AutoSuggestState state) {
    switch (state.step) {
      case 0:
        return _StepSelectCountry(
          selectedCountryId: state.params?.countryId,
        );
      case 1:
        return _StepSelectDates(
          params: state.params,
        );
      case 2:
        return _StepSelectCategories(
          selectedIds: state.params?.preferredCategoryIds ?? [],
        );
      case 3:
        return _StepSelectStyle(
          selectedStyle: state.params?.travelStyle,
        );
      case 4:
        return _StepResults(
          generatedItinerary: state.generatedItinerary,
          error: state.error,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _AutoSuggestHeader extends ConsumerWidget {
  final AutoSuggestState state;
  final VoidCallback onBack;

  const _AutoSuggestHeader({
    required this.state,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Back / close button
            GestureDetector(
              onTap: onBack,
              child: TpGlassCard(
                padding: const EdgeInsets.all(10),
                borderRadius: BorderRadius.circular(12),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: context.appColors.textPrimary,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Step title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _stepTitles[state.step.clamp(0, 4)],
                    style: AppTextStyles.titleSmall,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _stepSubtitles[state.step.clamp(0, 4)],
                    style: AppTextStyles.captionMuted,
                  ),
                ],
              ),
            ),
            // Skip button (steps 0–3, when params exist)
            if (state.step < 4 && state.params != null)
              TextButton(
                onPressed: () {
                  ref
                      .read(autoSuggestProvider.notifier)
                      .goToStep(state.step + 1);
                },
                child: Text(
                  'Skip',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step progress indicator
// ─────────────────────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: List.generate(5, (i) {
          final isActive = i <= currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 3,
              margin: EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : context.appColors.divider,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 0 — Select Country
// ─────────────────────────────────────────────────────────────────────────────

class _StepSelectCountry extends ConsumerWidget {
  final String? selectedCountryId;

  const _StepSelectCountry({this.selectedCountryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(tripMainProvider);

    return asyncState.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text(
          'Could not load countries',
          style: AppTextStyles.body.copyWith(color: context.appColors.textSecondary),
        ),
      ),
      data: (tripState) {
        final countries = tripState.allCountries;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select your destination', style: AppTextStyles.title),
              SizedBox(height: 8),
              Text(
                "We'll build a perfect itinerary for you",
                style:
                    AppTextStyles.body.copyWith(color: context.appColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ...countries.map((country) => _CountrySelectCard(
                    country: country,
                    isSelected: selectedCountryId == country.id,
                    onTap: () {
                      ref
                          .read(autoSuggestProvider.notifier)
                          .setCountry(country.id);
                    },
                  )),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

class _CountrySelectCard extends StatelessWidget {
  final ExploreCountry country;
  final bool isSelected;
  final VoidCallback onTap;

  const _CountrySelectCard({
    required this.country,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 140,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: AppColors.success, width: 2)
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            TpCinematicHeader(
              gradientStart: country.gradientStart,
              gradientEnd: country.gradientEnd,
              height: 140,
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              country.flagEmoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                country.name,
                                style: AppTextStyles.title.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          country.tagline,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _GlassChip('${country.cityCount} cities'),
                            const SizedBox(width: 8),
                            _GlassChip('${country.totalPlaces} places'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withOpacity(0.4),
                      size: 18,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  final String label;
  const _GlassChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.overline.copyWith(color: Colors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Select Dates
// ─────────────────────────────────────────────────────────────────────────────

class _StepSelectDates extends ConsumerStatefulWidget {
  final AutoSuggestParams? params;

  const _StepSelectDates({this.params});

  @override
  ConsumerState<_StepSelectDates> createState() => _StepSelectDatesState();
}

class _StepSelectDatesState extends ConsumerState<_StepSelectDates> {
  DateTime? _departure;
  DateTime? _returnDate;

  @override
  void initState() {
    super.initState();
    _departure = widget.params?.departureDate;
    _returnDate = widget.params?.returnDate;
  }

  Future<void> _pickDeparture() async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _departure ?? tomorrow,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
      builder: (ctx, child) => _pickerTheme(ctx, child),
    );
    if (picked != null) {
      setState(() {
        _departure = picked;
        if (_returnDate != null && _returnDate!.isBefore(picked)) {
          _returnDate = picked.add(const Duration(days: 7));
        }
      });
    }
  }

  Future<void> _pickReturn() async {
    final firstDate =
        (_departure ?? DateTime.now()).add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate ?? firstDate.add(const Duration(days: 6)),
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 730)),
      builder: (ctx, child) => _pickerTheme(ctx, child),
    );
    if (picked != null) {
      setState(() => _returnDate = picked);
    }
  }

  Widget _pickerTheme(BuildContext ctx, Widget? child) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          surface: context.appColors.surfaceElevated,
        ),
      ),
      child: child!,
    );
  }

  bool get _bothSelected => _departure != null && _returnDate != null;

  int get _tripDays => _bothSelected
      ? _returnDate!.difference(_departure!).inDays + 1
      : 0;

  int get _slotsPerDay {
    final style = widget.params?.travelStyle ?? 'balanced';
    return switch (style) {
      'relaxed' => 3,
      'packed' => 6,
      _ => 4,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('When are you travelling?', style: AppTextStyles.title),
          SizedBox(height: 8),
          Text(
            "We'll plan the perfect number of activities per day",
            style: AppTextStyles.body.copyWith(color: context.appColors.textSecondary),
          ),
          SizedBox(height: 32),

          // Departure
          Text('Departure Date',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: context.appColors.textPrimary)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDeparture,
            child: TpGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              borderRadius: BorderRadius.circular(14),
              child: Row(
                children: [
                  const Icon(Icons.flight_takeoff_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _departure != null
                          ? DateFormat('EEE, MMM d yyyy').format(_departure!)
                          : 'Select departure date',
                      style: AppTextStyles.body.copyWith(
                        color: _departure != null
                            ? context.appColors.textPrimary
                            : context.appColors.textMuted,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: context.appColors.textMuted, size: 16),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Return
          Text('Return Date',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: context.appColors.textPrimary)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickReturn,
            child: TpGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              borderRadius: BorderRadius.circular(14),
              child: Row(
                children: [
                  const Icon(Icons.flight_land_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _returnDate != null
                          ? DateFormat('EEE, MMM d yyyy').format(_returnDate!)
                          : 'Select return date',
                      style: AppTextStyles.body.copyWith(
                        color: _returnDate != null
                            ? context.appColors.textPrimary
                            : context.appColors.textMuted,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: context.appColors.textMuted, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Trip summary
          if (_bothSelected)
            AnimatedOpacity(
              opacity: _bothSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: TpGlassCard(
                tintColor: AppColors.primary,
                opacity: 0.10,
                borderRadius: BorderRadius.circular(14),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_tripDays day${_tripDays == 1 ? '' : 's'} trip',
                          style: AppTextStyles.titleSmall,
                        ),
                        Text(
                          '$_slotsPerDay activities per day planned',
                          style: AppTextStyles.caption.copyWith(
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 32),

          if (_bothSelected)
            _PrimaryButton(
              label: 'Continue →',
              onPressed: () {
                ref
                    .read(autoSuggestProvider.notifier)
                    .setDates(_departure!, _returnDate!);
              },
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Select Categories
// ─────────────────────────────────────────────────────────────────────────────

class _StepSelectCategories extends ConsumerStatefulWidget {
  final List<String> selectedIds;

  const _StepSelectCategories({required this.selectedIds});

  @override
  ConsumerState<_StepSelectCategories> createState() =>
      _StepSelectCategoriesState();
}

class _StepSelectCategoriesState extends ConsumerState<_StepSelectCategories> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedIds);
  }

  void _toggleCategory(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = ExploreStaticData.categories;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What do you love?', style: AppTextStyles.title),
          SizedBox(height: 8),
          Text(
            'Select all that interest you',
            style: AppTextStyles.body.copyWith(color: context.appColors.textSecondary),
          ),
          const SizedBox(height: 24),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: categories.map((cat) {
              final isSelected = _selected.contains(cat.id);
              return GestureDetector(
                onTap: () => _toggleCategory(cat.id),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cat.accent.withOpacity(0.2)
                        : context.appColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected ? cat.accent : context.appColors.divider,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        cat.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      SizedBox(height: 8),
                      Text(
                        cat.label,
                        style: AppTextStyles.caption.copyWith(
                          color: isSelected
                              ? context.appColors.textPrimary
                              : context.appColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 4),
                        Icon(
                          Icons.check_circle_rounded,
                          color: cat.accent,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          if (_selected.isNotEmpty)
            _PrimaryButton(
              label: 'Continue → (${_selected.length} selected)',
              onPressed: () {
                ref
                    .read(autoSuggestProvider.notifier)
                    .setCategories(List.from(_selected));
              },
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — Select Travel Style
// ─────────────────────────────────────────────────────────────────────────────

class _StepSelectStyle extends ConsumerStatefulWidget {
  final String? selectedStyle;

  const _StepSelectStyle({this.selectedStyle});

  @override
  ConsumerState<_StepSelectStyle> createState() => _StepSelectStyleState();
}

class _StepSelectStyleState extends ConsumerState<_StepSelectStyle> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedStyle;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How packed should your days be?', style: AppTextStyles.title),
          SizedBox(height: 8),
          Text(
            'Choose a pace that matches your energy',
            style: AppTextStyles.body.copyWith(color: context.appColors.textSecondary),
          ),
          const SizedBox(height: 24),

          _TravelStyleCard(
            style: 'relaxed',
            emoji: '🌅',
            title: 'Relaxed',
            description:
                '3 activities per day. Long lunches, unhurried evenings, time to get lost.',
            isSelected: _selected == 'relaxed',
            onTap: () => setState(() => _selected = 'relaxed'),
          ),
          const SizedBox(height: 12),
          _TravelStyleCard(
            style: 'balanced',
            emoji: '⚖️',
            title: 'Balanced',
            description:
                '4 activities per day. See the highlights without rushing. Perfect rhythm.',
            isSelected: _selected == 'balanced',
            onTap: () => setState(() => _selected = 'balanced'),
          ),
          const SizedBox(height: 12),
          _TravelStyleCard(
            style: 'packed',
            emoji: '⚡',
            title: 'Packed',
            description:
                '6 activities per day. Maximum discovery. For the insatiable explorer.',
            isSelected: _selected == 'packed',
            onTap: () => setState(() => _selected = 'packed'),
          ),
          const SizedBox(height: 32),

          if (_selected != null)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: TextButton.icon(
                  icon: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 20),
                  label: Text(
                    'Generate My Itinerary',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () async {
                    if (_selected == null) return;
                    ref
                        .read(autoSuggestProvider.notifier)
                        .setStyle(_selected!);
                    await ref
                        .read(autoSuggestProvider.notifier)
                        .generate();
                  },
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _TravelStyleCard extends StatelessWidget {
  final String style;
  final String emoji;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _TravelStyleCard({
    required this.style,
    required this.emoji,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: TpGlassCard(
          tintColor: isSelected ? AppColors.primary : null,
          opacity: isSelected ? 0.15 : 0.05,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : Border.all(color: context.appColors.divider),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleSmall),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTextStyles.caption.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 — Results
// ─────────────────────────────────────────────────────────────────────────────

class _StepResults extends ConsumerWidget {
  final Itinerary? generatedItinerary;
  final String? error;

  const _StepResults({this.generatedItinerary, this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😔', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                error!,
                style: AppTextStyles.body
                    .copyWith(color: context.appColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _PrimaryButton(
                label: 'Try Again',
                onPressed: () =>
                    ref.read(autoSuggestProvider.notifier).goToStep(3),
              ),
            ],
          ),
        ),
      );
    }

    if (generatedItinerary == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final itinerary = generatedItinerary!;
    final days = itinerary.days;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your perfect trip! ✦',
                      style: AppTextStyles.title,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${itinerary.totalDays} days · ${itinerary.totalPlaces} places · ${itinerary.countryName}',
                      style: AppTextStyles.captionMuted,
                    ),
                  ],
                ),
              ),
              Text(
                itinerary.countryFlag,
                style: const TextStyle(fontSize: 32),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.success, Color(0xFF16A34A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextButton.icon(
                icon: const Icon(Icons.save_alt_rounded,
                    color: Colors.white, size: 20),
                label: Text(
                  'Save Itinerary',
                  style: AppTextStyles.titleSmall.copyWith(color: Colors.white),
                ),
                onPressed: () {
                  ref
                      .read(scheduleProvider.notifier)
                      .importItinerary(itinerary);
                  ref.read(autoSuggestProvider.notifier).reset();
                  context.push(AppRoutes.schedule);
                },
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Day-by-day breakdown
          ...List.generate(days.length, (dayIndex) {
            final day = days[dayIndex];
            final slots = itinerary.slotsForDay(day);
            if (slots.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day header
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDeep],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Day ${dayIndex + 1}',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE, MMM d').format(day),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),

                // Slots
                ...slots.map((slot) => Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.appColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.appColors.divider),
                      ),
                      child: Row(
                        children: [
                          // Gradient time bar
                          Container(
                            width: 4,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  slot.gradientStart,
                                  slot.gradientEnd,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Place info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      slot.categoryEmoji,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        slot.placeName,
                                        style: AppTextStyles.bodyMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '${slot.startDisplay} – ${slot.endDisplay}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: context.appColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  slot.durationDisplay,
                                  style: AppTextStyles.captionMuted,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 16),
              ],
            );
          }),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generating overlay
// ─────────────────────────────────────────────────────────────────────────────

class _GeneratingOverlay extends StatelessWidget {
  final AnimationController pulseCtrl;
  final AutoSuggestState state;

  const _GeneratingOverlay({
    required this.pulseCtrl,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final params = state.params;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.75),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing icon
              _PulsingIcon(controller: pulseCtrl),
              const SizedBox(height: 32),
              Text(
                'Building your journey...',
                style: AppTextStyles.title.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (params != null)
                Text(
                  'Analysing ${params.tripDays} days · '
                  '${params.preferredCategoryIds.length} interests · '
                  '${params.travelStyle} pace',
                  style: AppTextStyles.body.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 32),
              const _AnimatedGeneratingSteps(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingIcon extends StatelessWidget {
  final AnimationController controller;
  const _PulsingIcon({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scaleAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    final glowAnim = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) {
        return Transform.scale(
          scale: scaleAnim.value,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(glowAnim.value),
                  blurRadius: 32,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated generating steps (sequential reveal)
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedGeneratingSteps extends StatefulWidget {
  const _AnimatedGeneratingSteps();

  @override
  State<_AnimatedGeneratingSteps> createState() =>
      _AnimatedGeneratingStepsState();
}

class _AnimatedGeneratingStepsState extends State<_AnimatedGeneratingSteps>
    with SingleTickerProviderStateMixin {
  static const _steps = [
    '🗺️  Mapping destinations...',
    '📍  Selecting top places...',
    '⏰  Optimising your schedule...',
    '✦  Crafting your experience...',
  ];

  int _visibleCount = 0;
  late final List<Timer> _timers;

  @override
  void initState() {
    super.initState();
    _timers = [];
    for (int i = 0; i < _steps.length; i++) {
      final t = Timer(Duration(milliseconds: 600 + i * 900), () {
        if (mounted) setState(() => _visibleCount = i + 1);
      });
      _timers.add(t);
    }
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_steps.length, (i) {
        final visible = i < _visibleCount;
        return AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 400),
          child: AnimatedSlide(
            offset: visible ? Offset.zero : const Offset(0, 0.3),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            child: Padding(
              padding:
                  EdgeInsets.symmetric(vertical: 4),
              child: Text(
                _steps[i],
                style: AppTextStyles.body.copyWith(
                  color: visible
                      ? context.appColors.textPrimary
                      : Colors.transparent,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared primary button
// ─────────────────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _PrimaryButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isEnabled
              ? LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isEnabled ? null : context.appColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.titleSmall.copyWith(
              color: isEnabled ? Colors.white : context.appColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

