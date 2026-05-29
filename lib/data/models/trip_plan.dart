// lib/data/models/trip_plan.dart
//
// A planned future trip to a city with a set of selected places.
// Stored locally in Hive; future API integration possible via the repository pattern.

import 'dart:convert';

enum TripPlanStatus { planned, completed, cancelled }

extension TripPlanStatusX on TripPlanStatus {
  String get jsonKey => name;

  static TripPlanStatus fromJsonKey(String key) =>
      TripPlanStatus.values.firstWhere(
        (s) => s.jsonKey == key,
        orElse: () => TripPlanStatus.planned,
      );
}

// ---------------------------------------------------------------------------

class TripPlan {
  final String id;

  final String cityId;
  final String cityName;
  final String countryId;

  /// The date (just the day, not time) the user plans to visit.
  final DateTime plannedDate;

  /// IDs of the places the user intends to visit.
  final List<String> placeIds;

  /// City discovery % before this plan (snapshot at creation time).
  final double currentDiscovery;

  /// Projected city discovery % if all places are completed.
  final double projectedDiscovery;

  final TripPlanStatus status;
  final DateTime createdAt;

  const TripPlan({
    required this.id,
    required this.cityId,
    required this.cityName,
    required this.countryId,
    required this.plannedDate,
    required this.placeIds,
    required this.currentDiscovery,
    required this.projectedDiscovery,
    this.status = TripPlanStatus.planned,
    required this.createdAt,
  });

  /// Discovery gain this plan will unlock (0.0–100.0).
  double get discoveryGain =>
      (projectedDiscovery - currentDiscovery).clamp(0.0, 100.0);

  factory TripPlan.fromJson(Map<String, dynamic> json) => TripPlan(
        id: json['id'] as String,
        cityId: json['cityId'] as String,
        cityName: json['cityName'] as String,
        countryId: json['countryId'] as String,
        plannedDate: DateTime.parse(json['plannedDate'] as String),
        placeIds: List<String>.from(json['placeIds'] as List),
        currentDiscovery: (json['currentDiscovery'] as num).toDouble(),
        projectedDiscovery: (json['projectedDiscovery'] as num).toDouble(),
        status: TripPlanStatusX.fromJsonKey(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'cityId': cityId,
        'cityName': cityName,
        'countryId': countryId,
        'plannedDate': plannedDate.toIso8601String(),
        'placeIds': placeIds,
        'currentDiscovery': currentDiscovery,
        'projectedDiscovery': projectedDiscovery,
        'status': status.jsonKey,
        'createdAt': createdAt.toIso8601String(),
      };

  TripPlan copyWith({
    String? id,
    String? cityId,
    String? cityName,
    String? countryId,
    DateTime? plannedDate,
    List<String>? placeIds,
    double? currentDiscovery,
    double? projectedDiscovery,
    TripPlanStatus? status,
    DateTime? createdAt,
  }) =>
      TripPlan(
        id: id ?? this.id,
        cityId: cityId ?? this.cityId,
        cityName: cityName ?? this.cityName,
        countryId: countryId ?? this.countryId,
        plannedDate: plannedDate ?? this.plannedDate,
        placeIds: placeIds ?? this.placeIds,
        currentDiscovery: currentDiscovery ?? this.currentDiscovery,
        projectedDiscovery: projectedDiscovery ?? this.projectedDiscovery,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripPlan && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ---------------------------------------------------------------------------
// Codec helpers (used by the repository)
// ---------------------------------------------------------------------------

String encodePlans(List<TripPlan> plans) =>
    jsonEncode(plans.map((p) => p.toJson()).toList());

List<TripPlan> decodePlans(String json) {
  final list = jsonDecode(json) as List<dynamic>;
  return list.map((e) => TripPlan.fromJson(e as Map<String, dynamic>)).toList();
}
