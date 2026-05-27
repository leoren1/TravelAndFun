import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String formatMonthYear(DateTime date) =>
      DateFormat('MMMM yyyy').format(date);

  static String formatDayMonth(DateTime date) =>
      DateFormat('d MMM').format(date);

  static String formatFull(DateTime date) =>
      DateFormat('d MMMM yyyy').format(date);

  static String formatTime(DateTime date) =>
      DateFormat('HH:mm').format(date);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String greetingByHour(int hour, String firstName) {
    if (hour < 12) return 'Good morning, $firstName';
    if (hour < 17) return 'Good afternoon, $firstName';
    return 'Good evening, $firstName';
  }

  static String greetingByHourTr(int hour, String firstName) {
    if (hour < 12) return 'Günaydın, $firstName';
    if (hour < 17) return 'İyi öğleden sonralar, $firstName';
    return 'İyi akşamlar, $firstName';
  }
}
