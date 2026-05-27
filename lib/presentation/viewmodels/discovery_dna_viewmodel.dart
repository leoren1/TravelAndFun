// lib/presentation/viewmodels/discovery_dna_viewmodel.dart

import 'package:explore_index/data/models/discovery_dna.dart';
import 'package:explore_index/data/providers.dart';
import 'package:explore_index/domain/usecases/compute_discovery_dna.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Supporting model
// ---------------------------------------------------------------------------

/// A single axis entry for the radar/spider chart.
class DnaAxis {
  final String label;
  final double value;

  const DnaAxis({required this.label, required this.value});
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class DiscoveryDnaState {
  final DiscoveryDna dna;

  /// Radar chart axes derived from [dna.dimensions].
  final List<DnaAxis> axes;

  /// The axis with the highest value.
  final DnaAxis? topAxis;

  /// The axis with the lowest value.
  final DnaAxis? bottomAxis;

  /// Whether the user has enough data for meaningful insights.
  final bool hasData;

  const DiscoveryDnaState({
    required this.dna,
    required this.axes,
    this.topAxis,
    this.bottomAxis,
    required this.hasData,
  });

  DiscoveryDnaState copyWith({
    DiscoveryDna? dna,
    List<DnaAxis>? axes,
    DnaAxis? topAxis,
    DnaAxis? bottomAxis,
    bool? hasData,
  }) {
    return DiscoveryDnaState(
      dna: dna ?? this.dna,
      axes: axes ?? this.axes,
      topAxis: topAxis ?? this.topAxis,
      bottomAxis: bottomAxis ?? this.bottomAxis,
      hasData: hasData ?? this.hasData,
    );
  }
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class DiscoveryDnaViewModel extends AsyncNotifier<DiscoveryDnaState> {
  @override
  Future<DiscoveryDnaState> build() async {
    final cityRepo = ref.read(cityRepositoryProvider);
    final placeRepo = ref.read(placeRepositoryProvider);
    final visitRepo = ref.read(visitRepositoryProvider);

    final cities = await cityRepo.getAllCities();
    final places = await placeRepo.getAllPlaces();
    final visits = await visitRepo.getAllVisits();

    final dna = ComputeDiscoveryDna(
      cities: cities,
      visits: visits,
      places: places,
    ).execute();

    final axesList = dna.dimensions.entries
        .map((e) => DnaAxis(label: e.key, value: e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final hasData = visits.isNotEmpty;

    return DiscoveryDnaState(
      dna: dna,
      axes: axesList,
      topAxis: axesList.isNotEmpty ? axesList.first : null,
      bottomAxis: axesList.isNotEmpty ? axesList.last : null,
      hasData: hasData,
    );
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final discoveryDnaViewModelProvider =
    AsyncNotifierProvider<DiscoveryDnaViewModel, DiscoveryDnaState>(
  DiscoveryDnaViewModel.new,
);
