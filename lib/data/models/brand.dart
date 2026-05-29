// lib/data/models/brand.dart

class Brand {
  final String id;
  final String name;
  final String countryId;
  final String industry;       // display label, e.g. "Automotive"
  final String industryEmoji;  // single emoji for the industry
  final String description;
  final int    foundedYear;
  final bool   isGlobal;       // well-known internationally

  const Brand({
    required this.id,
    required this.name,
    required this.countryId,
    required this.industry,
    required this.industryEmoji,
    required this.description,
    required this.foundedYear,
    this.isGlobal = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Brand && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
