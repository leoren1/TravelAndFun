import 'package:flutter/material.dart';

/// Typography constants — colours intentionally omitted so that Flutter's
/// [DefaultTextStyle] (driven by [ThemeData.textTheme]) supplies the right
/// colour for both dark and light modes.
/// Use .copyWith(color: ...) when you need an explicit override
/// (e.g. white text on a gradient card background).
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle display = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle title = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle captionMuted = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    height: 1.4,
  );
}
