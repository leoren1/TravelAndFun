// lib/data/models/badge.dart
// Plain Dart model — no code generation required.

class Badge {
  final String id;
  final String name;
  final String icon;
  final String description;

  /// Threshold stored as a 0–1 fraction (multiply by 100 to get a percentage).
  final double threshold;

  final String categoryKey;

  /// 1 = Bronze, 2 = Silver, 3 = Gold, 4 = Platinum.
  /// Defaults to 1 for any legacy badges loaded from storage.
  final int tier;

  const Badge({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.threshold,
    required this.categoryKey,
    this.tier = 1,
  });

  factory Badge.fromJson(Map<String, dynamic> json) => Badge(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        description: json['description'] as String,
        threshold: (json['threshold'] as num).toDouble(),
        categoryKey: json['categoryKey'] as String,
        tier: (json['tier'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'description': description,
        'threshold': threshold,
        'categoryKey': categoryKey,
        'tier': tier,
      };

  Badge copyWith({
    String? id,
    String? name,
    String? icon,
    String? description,
    double? threshold,
    String? categoryKey,
    int? tier,
  }) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      threshold: threshold ?? this.threshold,
      categoryKey: categoryKey ?? this.categoryKey,
      tier: tier ?? this.tier,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Badge && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Badge(id: $id, name: $name, tier: $tier, categoryKey: $categoryKey, threshold: $threshold)';
}
