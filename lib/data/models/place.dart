// lib/data/models/place.dart
// Plain Dart model — no code generation required.

import 'package:explore_index/data/models/category.dart';
import 'package:explore_index/data/models/travel_mode.dart';

enum PlaceTag { mustVisit, hidden, local }

extension PlaceTagExtension on PlaceTag {
  String get jsonKey {
    return switch (this) {
      PlaceTag.mustVisit => 'mustVisit',
      PlaceTag.hidden => 'hidden',
      PlaceTag.local => 'local',
    };
  }

  static PlaceTag fromJsonKey(String key) {
    return PlaceTag.values.firstWhere(
      (e) => e.jsonKey == key,
      orElse: () => throw ArgumentError('Unknown PlaceTag key: $key'),
    );
  }
}

// ---------------------------------------------------------------------------

class Place {
  final String id;
  final String name;
  final String description;
  final String image;
  final String cityId;
  final CategoryType category;
  final List<PlaceTag> tags;
  final double latitude;
  final double longitude;
  final double discoveryBoost;

  const Place({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.cityId,
    required this.category,
    required this.tags,
    required this.latitude,
    required this.longitude,
    required this.discoveryBoost,
  });

  /// Derived tier from [tags] — no extra JSON field needed.
  ///
  /// - `mustVisit` tag  → [PlaceTier.bronze]  (globally iconic landmark)
  /// - `hidden`/`local` → [PlaceTier.gold]    (hidden gem / local favourite)
  /// - anything else    → [PlaceTier.silver]  (standard touristic place)
  PlaceTier get tier {
    if (tags.contains(PlaceTag.mustVisit)) return PlaceTier.bronze;
    if (tags.contains(PlaceTag.hidden) || tags.contains(PlaceTag.local)) {
      return PlaceTier.gold;
    }
    return PlaceTier.silver;
  }

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        image: json['image'] as String,
        cityId: json['cityId'] as String,
        category:
            CategoryTypeExtension.fromJsonKey(json['category'] as String),
        tags: (json['tags'] as List<dynamic>)
            .map((t) => PlaceTagExtension.fromJsonKey(t as String))
            .toList(),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        discoveryBoost: (json['discoveryBoost'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'image': image,
        'cityId': cityId,
        'category': category.jsonKey,
        'tags': tags.map((t) => t.jsonKey).toList(),
        'latitude': latitude,
        'longitude': longitude,
        'discoveryBoost': discoveryBoost,
      };

  Place copyWith({
    String? id,
    String? name,
    String? description,
    String? image,
    String? cityId,
    CategoryType? category,
    List<PlaceTag>? tags,
    double? latitude,
    double? longitude,
    double? discoveryBoost,
  }) {
    return Place(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
      cityId: cityId ?? this.cityId,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      discoveryBoost: discoveryBoost ?? this.discoveryBoost,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Place && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Place(id: $id, name: $name, cityId: $cityId, category: ${category.jsonKey}, tier: ${tier.jsonKey})';
}
