import 'package:explore_index/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final double percentage;
  final double height;
  final Color? color;
  final Color? backgroundColor;

  const ProgressBar({
    super.key,
    required this.percentage,
    this.height = 6,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? _colorForPercentage(percentage);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: (percentage / 100).clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: backgroundColor ?? AppColors.divider,
        valueColor: AlwaysStoppedAnimation<Color>(c),
      ),
    );
  }

  Color _colorForPercentage(double pct) {
    if (pct >= 50) return AppColors.success;
    if (pct >= 25) return AppColors.warning;
    return AppColors.danger;
  }
}
