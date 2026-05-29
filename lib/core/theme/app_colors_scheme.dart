import 'package:flutter/material.dart';

/// Design-token color palette registered as a [ThemeExtension].
/// Access via [BuildContext.appColors] (see theme_extensions.dart).
@immutable
class AppColorsScheme extends ThemeExtension<AppColorsScheme> {
  const AppColorsScheme({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.primary,
    required this.primaryDeep,
    required this.success,
    required this.warning,
    required this.danger,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
    required this.primaryGradient,
    required this.deepGradient,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color primary;
  final Color primaryDeep;
  final Color success;
  final Color warning;
  final Color danger;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color divider;
  final List<Color> primaryGradient;
  final List<Color> deepGradient;

  // ── Dark (original) ────────────────────────────────────────────────────────
  static const dark = AppColorsScheme(
    background:      Color(0xFF0A0A0F),
    surface:         Color(0xFF14141C),
    surfaceElevated: Color(0xFF1B1B26),
    primary:         Color(0xFF7B5BFF),
    primaryDeep:     Color(0xFF4B2EFF),
    success:         Color(0xFF22C55E),
    warning:         Color(0xFFF59E0B),
    danger:          Color(0xFFEF4444),
    textPrimary:     Color(0xFFFFFFFF),
    textSecondary:   Color(0xFFB4B4C0),
    textMuted:       Color(0xFF7A7A85),
    divider:         Color(0xFF24242F),
    primaryGradient: [Color(0xFF7B5BFF), Color(0xFF22C55E)],
    deepGradient:    [Color(0xFF4B2EFF), Color(0xFF7B5BFF)],
  );

  // ── Light ──────────────────────────────────────────────────────────────────
  static const light = AppColorsScheme(
    background:      Color(0xFFF4F4FB),
    surface:         Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFECECF6),
    primary:         Color(0xFF6B4EE8),
    primaryDeep:     Color(0xFF4527D4),
    success:         Color(0xFF16A34A),
    warning:         Color(0xFFD97706),
    danger:          Color(0xFFDC2626),
    textPrimary:     Color(0xFF0D0D1A),
    textSecondary:   Color(0xFF3E3E56),
    textMuted:       Color(0xFF7A7A92),
    divider:         Color(0xFFE2E2EE),
    primaryGradient: [Color(0xFF6B4EE8), Color(0xFF16A34A)],
    deepGradient:    [Color(0xFF4527D4), Color(0xFF6B4EE8)],
  );

  // ── ThemeExtension boilerplate ─────────────────────────────────────────────
  @override
  AppColorsScheme copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? primary,
    Color? primaryDeep,
    Color? success,
    Color? warning,
    Color? danger,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? divider,
    List<Color>? primaryGradient,
    List<Color>? deepGradient,
  }) {
    return AppColorsScheme(
      background:      background      ?? this.background,
      surface:         surface         ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      primary:         primary         ?? this.primary,
      primaryDeep:     primaryDeep     ?? this.primaryDeep,
      success:         success         ?? this.success,
      warning:         warning         ?? this.warning,
      danger:          danger          ?? this.danger,
      textPrimary:     textPrimary     ?? this.textPrimary,
      textSecondary:   textSecondary   ?? this.textSecondary,
      textMuted:       textMuted       ?? this.textMuted,
      divider:         divider         ?? this.divider,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      deepGradient:    deepGradient    ?? this.deepGradient,
    );
  }

  @override
  AppColorsScheme lerp(ThemeExtension<AppColorsScheme>? other, double t) {
    if (other is! AppColorsScheme) return this;
    return AppColorsScheme(
      background:      Color.lerp(background,      other.background,      t)!,
      surface:         Color.lerp(surface,         other.surface,         t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      primary:         Color.lerp(primary,         other.primary,         t)!,
      primaryDeep:     Color.lerp(primaryDeep,     other.primaryDeep,     t)!,
      success:         Color.lerp(success,         other.success,         t)!,
      warning:         Color.lerp(warning,         other.warning,         t)!,
      danger:          Color.lerp(danger,          other.danger,          t)!,
      textPrimary:     Color.lerp(textPrimary,     other.textPrimary,     t)!,
      textSecondary:   Color.lerp(textSecondary,   other.textSecondary,   t)!,
      textMuted:       Color.lerp(textMuted,       other.textMuted,       t)!,
      divider:         Color.lerp(divider,         other.divider,         t)!,
      primaryGradient: [
        Color.lerp(primaryGradient[0], other.primaryGradient[0], t)!,
        Color.lerp(primaryGradient[1], other.primaryGradient[1], t)!,
      ],
      deepGradient: [
        Color.lerp(deepGradient[0], other.deepGradient[0], t)!,
        Color.lerp(deepGradient[1], other.deepGradient[1], t)!,
      ],
    );
  }
}
