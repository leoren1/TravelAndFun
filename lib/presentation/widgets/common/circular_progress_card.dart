import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:explore_index/core/utils/theme_extensions.dart';

class CircularProgressCard extends StatelessWidget {
  final double percentage;
  final String label;
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Widget? centerWidget;

  const CircularProgressCard({
    super.key,
    required this.percentage,
    required this.label,
    this.size = 120,
    this.strokeWidth = 10,
    this.progressColor,
    this.centerWidget,
  });

  @override
  Widget build(BuildContext context) {
    final color = progressColor ?? _colorForPercentage(percentage);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ArcPainter(
              percentage: percentage,
              color: color,
              strokeWidth: strokeWidth,
              bgColor: context.appColors.divider,
            ),
          ),
          centerWidget ??
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: AppTextStyles.title.copyWith(color: color),
                  ),
                  Text(
                    label,
                    style: AppTextStyles.captionMuted,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
        ],
      ),
    );
  }

  Color _colorForPercentage(double pct) {
    if (pct >= 50) return AppColors.success;
    if (pct >= 25) return AppColors.warning;
    return AppColors.danger;
  }
}

class _ArcPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final double strokeWidth;
  final Color bgColor;

  const _ArcPainter({
    required this.percentage,
    required this.color,
    required this.strokeWidth,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = bgColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final sweepAngle = 2 * math.pi * (percentage / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) =>
      oldDelegate.percentage != percentage || oldDelegate.color != color;
}

