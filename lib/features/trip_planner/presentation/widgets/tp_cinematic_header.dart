// Cinematic gradient hero widget.
// Used in place of network images to deliver a visually striking, immersive
// hero section using only procedural gradients and layering.
import 'package:flutter/material.dart';

class TpCinematicHeader extends StatelessWidget {
  final Color gradientStart;
  final Color gradientEnd;
  final double height;

  /// Widget layered on top of the gradient (text, badges, back button …).
  final Widget? foreground;

  /// Whether to apply a bottom-to-top dark vignette for text legibility.
  final bool addOverlay;

  /// Opacity of the bottom vignette (0–1). Default: 0.65.
  final double overlayOpacity;

  const TpCinematicHeader({
    super.key,
    required this.gradientStart,
    required this.gradientEnd,
    required this.height,
    this.foreground,
    this.addOverlay = true,
    this.overlayOpacity = 0.65,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Base diagonal gradient ─────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gradientStart, gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ── 2. Secondary cross-diagonal for depth ─────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradientStart.withOpacity(0.30),
                  Colors.transparent,
                  gradientEnd.withOpacity(0.40),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── 3. Radial centre glow for premium depth ───────────────────────
          Center(
            child: Container(
              width: height * 0.9,
              height: height * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.06),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          // ── 4. Noise-like top shimmer line ────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── 5. Bottom vignette for text legibility ────────────────────────
          if (addOverlay)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(overlayOpacity),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),

          // ── 6. Foreground content ─────────────────────────────────────────
          if (foreground != null) foreground!,
        ],
      ),
    );
  }
}
