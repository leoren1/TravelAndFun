import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/core/theme/app_colors_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._();

  // ── Dark ───────────────────────────────────────────────────────────────────
  static ThemeData get dark {
    const c = AppColorsScheme.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: c.background,
      colorScheme: ColorScheme.dark(
        surface: c.surface,
        primary: c.primary,
        secondary: c.success,
        error: c.danger,
        onSurface: c.textPrimary,
        onPrimary: c.textPrimary,
      ),
      fontFamily: 'Inter',
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display.copyWith(color: c.textPrimary),
        titleLarge:   AppTextStyles.title.copyWith(color: c.textPrimary),
        titleMedium:  AppTextStyles.titleSmall.copyWith(color: c.textPrimary),
        bodyMedium:   AppTextStyles.body.copyWith(color: c.textPrimary),
        bodySmall:    AppTextStyles.caption.copyWith(color: c.textSecondary),
        labelSmall:   AppTextStyles.overline.copyWith(color: c.textMuted),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: BorderSide(color: c.divider, width: 1),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: false,
        titleTextStyle: AppTextStyles.title.copyWith(color: c.textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.surface,
        selectedItemColor: c.primary,
        unselectedItemColor: c.textMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          borderSide: BorderSide(color: c.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          borderSide: BorderSide(color: c.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          borderSide: BorderSide(color: c.primary),
        ),
        labelStyle: AppTextStyles.body.copyWith(color: c.textMuted),
        hintStyle:  AppTextStyles.body.copyWith(color: c.textMuted),
      ),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surfaceElevated,
        contentTextStyle: AppTextStyles.body.copyWith(color: c.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      extensions: const [AppColorsScheme.dark],
    );
  }

  // ── Light ──────────────────────────────────────────────────────────────────
  static ThemeData get light {
    const c = AppColorsScheme.light;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: c.background,
      colorScheme: ColorScheme.light(
        surface: c.surface,
        primary: c.primary,
        secondary: c.success,
        error: c.danger,
        onSurface: c.textPrimary,
        onPrimary: Colors.white,
      ),
      fontFamily: 'Inter',
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display.copyWith(color: c.textPrimary),
        titleLarge:   AppTextStyles.title.copyWith(color: c.textPrimary),
        titleMedium:  AppTextStyles.titleSmall.copyWith(color: c.textPrimary),
        bodyMedium:   AppTextStyles.body.copyWith(color: c.textPrimary),
        bodySmall:    AppTextStyles.caption.copyWith(color: c.textSecondary),
        labelSmall:   AppTextStyles.overline.copyWith(color: c.textMuted),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: BorderSide(color: c.divider, width: 1),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: false,
        titleTextStyle: AppTextStyles.title.copyWith(color: c.textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.surface,
        selectedItemColor: c.primary,
        unselectedItemColor: c.textMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          borderSide: BorderSide(color: c.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          borderSide: BorderSide(color: c.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          borderSide: BorderSide(color: c.primary),
        ),
        labelStyle: AppTextStyles.body.copyWith(color: c.textMuted),
        hintStyle:  AppTextStyles.body.copyWith(color: c.textMuted),
      ),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surface,
        contentTextStyle: AppTextStyles.body.copyWith(color: c.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      extensions: const [AppColorsScheme.light],
    );
  }
}
