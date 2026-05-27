// lib/data/models/discovery_dna.dart
// Plain Dart model — no code generation required.

class DiscoveryDna {
  final double history;
  final double food;
  final double nature;
  final double events;
  final double nightlife;
  final double localExp;
  final double shopping;
  final double museums;
  final String summary;

  const DiscoveryDna({
    required this.history,
    required this.food,
    required this.nature,
    required this.events,
    required this.nightlife,
    required this.localExp,
    required this.shopping,
    required this.museums,
    required this.summary,
  });

  factory DiscoveryDna.fromJson(Map<String, dynamic> json) => DiscoveryDna(
        history: (json['history'] as num).toDouble(),
        food: (json['food'] as num).toDouble(),
        nature: (json['nature'] as num).toDouble(),
        events: (json['events'] as num).toDouble(),
        nightlife: (json['nightlife'] as num).toDouble(),
        localExp: (json['localExp'] as num).toDouble(),
        shopping: (json['shopping'] as num).toDouble(),
        museums: (json['museums'] as num).toDouble(),
        summary: json['summary'] as String,
      );

  Map<String, dynamic> toJson() => {
        'history': history,
        'food': food,
        'nature': nature,
        'events': events,
        'nightlife': nightlife,
        'localExp': localExp,
        'shopping': shopping,
        'museums': museums,
        'summary': summary,
      };

  DiscoveryDna copyWith({
    double? history,
    double? food,
    double? nature,
    double? events,
    double? nightlife,
    double? localExp,
    double? shopping,
    double? museums,
    String? summary,
  }) {
    return DiscoveryDna(
      history: history ?? this.history,
      food: food ?? this.food,
      nature: nature ?? this.nature,
      events: events ?? this.events,
      nightlife: nightlife ?? this.nightlife,
      localExp: localExp ?? this.localExp,
      shopping: shopping ?? this.shopping,
      museums: museums ?? this.museums,
      summary: summary ?? this.summary,
    );
  }

  /// Returns all dimension values as a map keyed by label (useful for charts).
  Map<String, double> get dimensions => {
        'History': history,
        'Food': food,
        'Nature': nature,
        'Events': events,
        'Nightlife': nightlife,
        'Local Exp': localExp,
        'Shopping': shopping,
        'Museums': museums,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveryDna &&
          runtimeType == other.runtimeType &&
          history == other.history &&
          food == other.food &&
          nature == other.nature &&
          events == other.events &&
          nightlife == other.nightlife &&
          localExp == other.localExp &&
          shopping == other.shopping &&
          museums == other.museums;

  @override
  int get hashCode => Object.hash(
      history, food, nature, events, nightlife, localExp, shopping, museums);

  @override
  String toString() => 'DiscoveryDna(summary: $summary)';
}
