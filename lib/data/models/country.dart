// lib/data/models/country.dart
// Plain Dart model — no code generation required.

class Country {
  final String id;
  final String name;
  final String countryCode;
  final String heroImage;
  final List<String> cityIds;
  final int totalCitiesInCountry;

  const Country({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.heroImage,
    required this.cityIds,
    required this.totalCitiesInCountry,
  });

  factory Country.fromJson(Map<String, dynamic> json) => Country(
        id: json['id'] as String,
        name: json['name'] as String,
        countryCode: json['countryCode'] as String,
        heroImage: json['heroImage'] as String,
        cityIds: (json['cityIds'] as List<dynamic>).cast<String>(),
        totalCitiesInCountry: json['totalCitiesInCountry'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'countryCode': countryCode,
        'heroImage': heroImage,
        'cityIds': cityIds,
        'totalCitiesInCountry': totalCitiesInCountry,
      };

  Country copyWith({
    String? id,
    String? name,
    String? countryCode,
    String? heroImage,
    List<String>? cityIds,
    int? totalCitiesInCountry,
  }) {
    return Country(
      id: id ?? this.id,
      name: name ?? this.name,
      countryCode: countryCode ?? this.countryCode,
      heroImage: heroImage ?? this.heroImage,
      cityIds: cityIds ?? this.cityIds,
      totalCitiesInCountry: totalCitiesInCountry ?? this.totalCitiesInCountry,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Country(id: $id, name: $name, countryCode: $countryCode)';
}
