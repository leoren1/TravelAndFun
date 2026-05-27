import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background      = Color(0xFF0A0A0F);
  static const surface         = Color(0xFF14141C);
  static const surfaceElevated = Color(0xFF1B1B26);
  static const primary         = Color(0xFF7B5BFF);
  static const primaryDeep     = Color(0xFF4B2EFF);
  static const success         = Color(0xFF22C55E);
  static const warning         = Color(0xFFF59E0B);
  static const danger          = Color(0xFFEF4444);
  static const textPrimary     = Color(0xFFFFFFFF);
  static const textSecondary   = Color(0xFFB4B4C0);
  static const textMuted       = Color(0xFF7A7A85);
  static const divider         = Color(0xFF24242F);

  static const List<Color> primaryGradient = [primary, success];
  static const List<Color> deepGradient    = [primaryDeep, primary];
}
