// lib/data/models/category.dart
// Plain Dart model — no code generation required.

enum CategoryType {
  historicalPlaces,
  foodRestaurants,
  cafes,
  museumsArt,
  routes,
  nature,
  nightlife,
  localMarkets,
  hiddenGems,
  events,
}

extension CategoryTypeExtension on CategoryType {
  String get displayName {
    return switch (this) {
      CategoryType.historicalPlaces => 'Historical Places',
      CategoryType.foodRestaurants => 'Food & Restaurants',
      CategoryType.cafes => 'Cafes',
      CategoryType.museumsArt => 'Museums & Art',
      CategoryType.routes => 'Routes',
      CategoryType.nature => 'Nature',
      CategoryType.nightlife => 'Nightlife',
      CategoryType.localMarkets => 'Local Markets',
      CategoryType.hiddenGems => 'Hidden Gems',
      CategoryType.events => 'Events',
    };
  }

  String get icon {
    return switch (this) {
      CategoryType.historicalPlaces => '🏛️',
      CategoryType.foodRestaurants => '🍽️',
      CategoryType.cafes => '☕',
      CategoryType.museumsArt => '🎨',
      CategoryType.routes => '🗺️',
      CategoryType.nature => '🌿',
      CategoryType.nightlife => '🌙',
      CategoryType.localMarkets => '🛍️',
      CategoryType.hiddenGems => '💎',
      CategoryType.events => '🎭',
    };
  }

  String get jsonKey {
    return switch (this) {
      CategoryType.historicalPlaces => 'historicalPlaces',
      CategoryType.foodRestaurants => 'foodRestaurants',
      CategoryType.cafes => 'cafes',
      CategoryType.museumsArt => 'museumsArt',
      CategoryType.routes => 'routes',
      CategoryType.nature => 'nature',
      CategoryType.nightlife => 'nightlife',
      CategoryType.localMarkets => 'localMarkets',
      CategoryType.hiddenGems => 'hiddenGems',
      CategoryType.events => 'events',
    };
  }

  static CategoryType fromJsonKey(String key) {
    return CategoryType.values.firstWhere(
      (e) => e.jsonKey == key,
      orElse: () => throw ArgumentError('Unknown CategoryType jsonKey: $key'),
    );
  }
}

// ---------------------------------------------------------------------------

class CategoryProgress {
  final CategoryType type;
  final int completed;
  final int total;
  final double percentage;

  const CategoryProgress({
    required this.type,
    required this.completed,
    required this.total,
    required this.percentage,
  });

  factory CategoryProgress.fromJson(Map<String, dynamic> json) =>
      CategoryProgress(
        type: CategoryTypeExtension.fromJsonKey(json['type'] as String),
        completed: json['completed'] as int,
        total: json['total'] as int,
        percentage: (json['percentage'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'type': type.jsonKey,
        'completed': completed,
        'total': total,
        'percentage': percentage,
      };

  CategoryProgress copyWith({
    CategoryType? type,
    int? completed,
    int? total,
    double? percentage,
  }) {
    return CategoryProgress(
      type: type ?? this.type,
      completed: completed ?? this.completed,
      total: total ?? this.total,
      percentage: percentage ?? this.percentage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryProgress &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          completed == other.completed &&
          total == other.total;

  @override
  int get hashCode => Object.hash(type, completed, total);

  @override
  String toString() =>
      'CategoryProgress(type: ${type.jsonKey}, completed: $completed, total: $total, percentage: $percentage)';
}
