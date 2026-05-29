import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/core/theme/app_colors_scheme.dart';
import 'package:flutter/material.dart';

/// Convenient theme-aware accessors on [BuildContext].
///
/// Usage in any Widget.build():
///   context.appColors.background
///   context.titleStyle
extension ThemeX on BuildContext {
  // ── Color tokens ──────────────────────────────────────────────────────────
  AppColorsScheme get appColors =>
      Theme.of(this).extension<AppColorsScheme>() ?? AppColorsScheme.dark;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // ── Theme-aware text styles ───────────────────────────────────────────────
  TextStyle get displayStyle =>
      AppTextStyles.display.copyWith(color: appColors.textPrimary);

  TextStyle get titleStyle =>
      AppTextStyles.title.copyWith(color: appColors.textPrimary);

  TextStyle get titleSmallStyle =>
      AppTextStyles.titleSmall.copyWith(color: appColors.textPrimary);

  TextStyle get bodyStyle =>
      AppTextStyles.body.copyWith(color: appColors.textPrimary);

  TextStyle get bodyMediumStyle =>
      AppTextStyles.bodyMedium.copyWith(color: appColors.textPrimary);

  TextStyle get captionStyle =>
      AppTextStyles.caption.copyWith(color: appColors.textSecondary);

  TextStyle get captionMutedStyle =>
      AppTextStyles.captionMuted.copyWith(color: appColors.textMuted);

  TextStyle get overlineStyle =>
      AppTextStyles.overline.copyWith(color: appColors.textMuted);
}

