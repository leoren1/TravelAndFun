// lib/data/models/badge.dart
// Plain Dart model — no code generation required.

class Badge {
  final String id;
  final String name;
  final String icon;
  final String description;
  final double threshold;
  final String categoryKey;

  const Badge({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.threshold,
    required this.categoryKey,
  });

  factory Badge.fromJson(Map<String, dynamic> json) => Badge(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        description: json['description'] as String,
        threshold: (json['threshold'] as num).toDouble(),
        categoryKey: json['categoryKey'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'description': description,
        'threshold': threshold,
        'categoryKey': categoryKey,
      };

  Badge copyWith({
    String? id,
    String? name,
    String? icon,
    String? description,
    double? threshold,
    String? categoryKey,
  }) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      threshold: threshold ?? this.threshold,
      categoryKey: categoryKey ?? this.categoryKey,
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
      'Badge(id: $id, name: $name, categoryKey: $categoryKey, threshold: $threshold)';
}
