// lib/data/models/event.dart
// Plain Dart model — no code generation required.

class Event {
  final String id;
  final String cityId;
  final String title;
  final String image;
  final DateTime startDate;
  final DateTime endDate;
  final String category;
  final String subcategory;
  final double discoveryBoost;
  final bool onlyThisWeek;

  const Event({
    required this.id,
    required this.cityId,
    required this.title,
    required this.image,
    required this.startDate,
    required this.endDate,
    required this.category,
    required this.subcategory,
    required this.discoveryBoost,
    required this.onlyThisWeek,
  });

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'] as String,
        cityId: json['cityId'] as String,
        title: json['title'] as String,
        image: json['image'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        category: json['category'] as String,
        subcategory: json['subcategory'] as String,
        discoveryBoost: (json['discoveryBoost'] as num).toDouble(),
        onlyThisWeek: json['onlyThisWeek'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'cityId': cityId,
        'title': title,
        'image': image,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'category': category,
        'subcategory': subcategory,
        'discoveryBoost': discoveryBoost,
        'onlyThisWeek': onlyThisWeek,
      };

  Event copyWith({
    String? id,
    String? cityId,
    String? title,
    String? image,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? subcategory,
    double? discoveryBoost,
    bool? onlyThisWeek,
  }) {
    return Event(
      id: id ?? this.id,
      cityId: cityId ?? this.cityId,
      title: title ?? this.title,
      image: image ?? this.image,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      discoveryBoost: discoveryBoost ?? this.discoveryBoost,
      onlyThisWeek: onlyThisWeek ?? this.onlyThisWeek,
    );
  }

  /// Returns true if the event is currently active (today is between startDate and endDate).
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Event(id: $id, title: $title, cityId: $cityId, category: $category)';
}
