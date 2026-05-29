// Animated circular discovery-progress ring.
// Psychologically compelling — shows the user how much of a city they have
// explored, driving engagement and return visits.
import 'dart:math' as math;

import 'package:explore_index/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

class TpDiscoveryRing extends StatefulWidget {
  /// Progress value from 0.0 to 100.0.
  final double percent;

  /// Outer diameter of the ring widget.
  final double size;

  /// Stroke width of the progress arc. Default: 6.
  final double strokeWidth;

  /// Colour of the filled arc. Defaults to [AppColors.primary].
  final Color? activeColor;

  /// Colour of the background track. Defaults to [context.appColors.divider].
  final Color? trackColor;

  /// Widget rendered in the centre of the ring (e.g., a percentage label).
  final Widget? child;

  /// Whether to animate from 0 % to [percent] on first build.
  final bool animate;

  /// Duration of the fill animation.
  final Duration animationDuration;

  const TpDiscoveryRing({
    super.key,
    required this.percent,
    required this.size,
    this.strokeWidth = 6.0,
    this.activeColor,
    this.trackColor,
    this.child,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 1200),
  });

  @override
  State<TpDiscoveryRing> createState() => _TpDiscoveryRingState();
}

class _TpDiscoveryRingState extends State<TpDiscoveryRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: (widget.percent / 100).clamp(0.0, 1.0),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(TpDiscoveryRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percent != widget.percent) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: (widget.percent / 100).clamp(0.0, 1.0),
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) => CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _RingPainter(
                progress: _animation.value,
                strokeWidth: widget.strokeWidth,
                activeColor: widget.activeColor ?? AppColors.primary,
                trackColor: widget.trackColor ?? context.appColors.divider,
              ),
            ),
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;  // 0.0–1.0
  final double strokeWidth;
  final Color activeColor;
  final Color trackColor;

  const _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - strokeWidth / 2;
    const startAngle = -math.pi / 2; // Start from the top of the circle.
    const fullSweep = 2 * math.pi;

    // ── Track (full circle background) ───────────────────────────────────────
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // ── Active progress arc ───────────────────────────────────────────────────
    if (progress > 0) {
      // Gradient along the arc for a premium look.
      final sweepAngle = fullSweep * progress;

      final rect = Rect.fromCircle(center: center, radius: radius);
      final progressPaint = Paint()
        ..shader = SweepGradient(
          colors: [
            activeColor.withOpacity(0.6),
            activeColor,
          ],
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          tileMode: TileMode.clamp,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );

      // Glowing dot at the arc tip.
      if (progress < 1.0) {
        final tipAngle = startAngle + sweepAngle;
        final tipX = center.dx + radius * math.cos(tipAngle);
        final tipY = center.dy + radius * math.sin(tipAngle);
        final tipCenter = Offset(tipX, tipY);
        final dotRadius = strokeWidth / 2 + 1.5;

        // Outer glow.
        final glowPaint = Paint()
          ..color = activeColor.withOpacity(0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(tipCenter, dotRadius + 2, glowPaint);

        // Solid tip dot.
        final dotPaint = Paint()..color = activeColor;
        canvas.drawCircle(tipCenter, dotRadius, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.strokeWidth != strokeWidth ||
      old.activeColor != activeColor ||
      old.trackColor != trackColor;
}

