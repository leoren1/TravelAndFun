// Parameters for the automatic trip suggestion engine
class AutoSuggestParams {
  final String countryId;
  final String? preferredCityId;
  final DateTime departureDate;
  final DateTime returnDate;
  final List<String> preferredCategoryIds;
  final String travelStyle; // 'relaxed' | 'balanced' | 'packed'

  const AutoSuggestParams({
    required this.countryId,
    this.preferredCityId,
    required this.departureDate,
    required this.returnDate,
    required this.preferredCategoryIds,
    required this.travelStyle,
  });

  int get tripDays => returnDate.difference(departureDate).inDays + 1;

  int get slotsPerDay => switch (travelStyle) {
        'relaxed' => 3,
        'packed' => 6,
        _ => 4, // balanced
      };

  AutoSuggestParams copyWith({
    String? countryId,
    String? preferredCityId,
    DateTime? departureDate,
    DateTime? returnDate,
    List<String>? preferredCategoryIds,
    String? travelStyle,
  }) =>
      AutoSuggestParams(
        countryId: countryId ?? this.countryId,
        preferredCityId: preferredCityId ?? this.preferredCityId,
        departureDate: departureDate ?? this.departureDate,
        returnDate: returnDate ?? this.returnDate,
        preferredCategoryIds:
            preferredCategoryIds ?? this.preferredCategoryIds,
        travelStyle: travelStyle ?? this.travelStyle,
      );
}
