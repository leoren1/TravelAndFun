// A single scheduled visit slot in the itinerary
import 'package:flutter/material.dart';

class ScheduleSlot {
  final String id;
  final String placeId;
  final String placeName;
  final String cityId;
  final String cityName;
  final String countryName;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay? endTime;
  final String categoryId;
  final String categoryEmoji;
  final String gradientStartHex;
  final String gradientEndHex;
  final String notes;

  const ScheduleSlot({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.cityId,
    required this.cityName,
    required this.countryName,
    required this.date,
    required this.startTime,
    this.endTime,
    required this.categoryId,
    required this.categoryEmoji,
    required this.gradientStartHex,
    required this.gradientEndHex,
    required this.notes,
  });

  Color get gradientStart =>
      Color(int.parse('0xFF${gradientStartHex.replaceAll('#', '')}'));
  Color get gradientEnd =>
      Color(int.parse('0xFF${gradientEndHex.replaceAll('#', '')}'));

  int get startMinutes => startTime.hour * 60 + startTime.minute;
  int get endMinutes =>
      endTime != null
          ? endTime!.hour * 60 + endTime!.minute
          : startMinutes + 120;
  int get durationMinutes => endMinutes - startMinutes;

  String get startDisplay {
    final h = startTime.hour.toString().padLeft(2, '0');
    final m = startTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get endDisplay {
    if (endTime == null) return '';
    final h = endTime!.hour.toString().padLeft(2, '0');
    final m = endTime!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get durationDisplay {
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  ScheduleSlot copyWith({
    String? id,
    String? placeId,
    String? placeName,
    String? cityId,
    String? cityName,
    String? countryName,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? categoryId,
    String? categoryEmoji,
    String? gradientStartHex,
    String? gradientEndHex,
    String? notes,
  }) =>
      ScheduleSlot(
        id: id ?? this.id,
        placeId: placeId ?? this.placeId,
        placeName: placeName ?? this.placeName,
        cityId: cityId ?? this.cityId,
        cityName: cityName ?? this.cityName,
        countryName: countryName ?? this.countryName,
        date: date ?? this.date,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        categoryId: categoryId ?? this.categoryId,
        categoryEmoji: categoryEmoji ?? this.categoryEmoji,
        gradientStartHex: gradientStartHex ?? this.gradientStartHex,
        gradientEndHex: gradientEndHex ?? this.gradientEndHex,
        notes: notes ?? this.notes,
      );
}
