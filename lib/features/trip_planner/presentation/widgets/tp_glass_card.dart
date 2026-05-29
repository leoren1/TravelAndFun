// Glassmorphism card widget used throughout the Trip Planner feature.
// Provides a luxury frosted-glass look via BackdropFilter + subtle gradient border.
import 'dart:ui';

import 'package:flutter/material.dart';

class TpGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  /// Subtle color tint applied to the frosted layer (default: white).
  final Color? tintColor;

  /// Blur sigma for the backdrop filter (default: 12).
  final double blurSigma;

  /// Override the card border. Defaults to a thin white 12 % opacity line.
  final Border? border;

  /// Optional tap callback. When null no ink-splash is added.
  final VoidCallback? onTap;

  /// Background opacity of the tint layer (0–1). Default: 0.08.
  final double opacity;

  /// Optional gradient that replaces the flat tint layer.
  final LinearGradient? tintGradient;

  /// Optional box shadow for depth.
  final List<BoxShadow>? shadows;

  const TpGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.tintColor,
    this.blurSigma = 12.0,
    this.border,
    this.onTap,
    this.opacity = 0.08,
    this.tintGradient,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(20);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTint = isDark ? Colors.white : Colors.black;
    final defaultBorderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.08);

    Widget card = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tintGradient == null
                ? (tintColor ?? defaultTint).withOpacity(opacity)
                : null,
            gradient: tintGradient != null
                ? LinearGradient(
                    colors: tintGradient!.colors
                        .map((c) => c.withOpacity(opacity))
                        .toList(),
                    begin: tintGradient!.begin,
                    end: tintGradient!.end,
                  )
                : null,
            borderRadius: radius,
            border: border ??
                Border.all(
                  color: defaultBorderColor,
                  width: 1.0,
                ),
            boxShadow: shadows,
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }

    return card;
  }
}
