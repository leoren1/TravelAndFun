// lib/data/models/city.dart
// Plain Dart model — no code generation required.

import 'package:explore_index/data/models/travel_mode.dart';

class City {
  final String id;
  final String name;
  final String countryId;
  final String heroImage;
  final double latitude;
  final double longitude;
  final Map<String, int> categoryTargets;

  /// Tier classification used by the Travel Mode filter.
  /// Bronze = globally iconic; Silver = regional/secondary; Gold = niche/local.
  final CityTier tier;

  const City({
    required this.id,
    required this.name,
    required this.countryId,
    required this.heroImage,
    required this.latitude,
    required this.longitude,
    required this.categoryTargets,
    this.tier = CityTier.gold,
  });

  factory City.fromJson(Map<String, dynamic> json) => City(
        id: json['id'] as String,
        name: json['name'] as String,
        countryId: json['countryId'] as String,
        heroImage: json['heroImage'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        categoryTargets: (json['categoryTargets'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ),
        tier: json['tier'] != null
            ? CityTierX.fromJsonKey(json['tier'] as String)
            : CityTier.gold,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'countryId': countryId,
        'heroImage': heroImage,
        'latitude': latitude,
        'longitude': longitude,
        'categoryTargets': categoryTargets,
        'tier': tier.jsonKey,
      };

  City copyWith({
    String? id,
    String? name,
    String? countryId,
    String? heroImage,
    double? latitude,
    double? longitude,
    Map<String, int>? categoryTargets,
    CityTier? tier,
  }) {
    return City(
      id: id ?? this.id,
      name: name ?? this.name,
      countryId: countryId ?? this.countryId,
      heroImage: heroImage ?? this.heroImage,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      categoryTargets: categoryTargets ?? this.categoryTargets,
      tier: tier ?? this.tier,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'City(id: $id, name: $name, countryId: $countryId, tier: ${tier.jsonKey})';
}
