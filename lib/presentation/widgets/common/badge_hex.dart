import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

class BadgeHex extends StatelessWidget {
  final String icon;
  final String name;
  final bool isLocked;
  final double size;

  const BadgeHex({
    super.key,
    required this.icon,
    required this.name,
    required this.isLocked,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipPath(
          clipper: _HexClipper(),
          child: Container(
            width: size,
            height: size * 0.866,
            color: isLocked
                ? AppColors.surfaceElevated
                : AppColors.primary.withOpacity(0.2),
            child: Center(
              child: Text(
                icon,
                style: TextStyle(
                  fontSize: size * 0.38,
                  color: isLocked ? AppColors.textMuted : null,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isLocked ? 'Locked' : name,
          style: AppTextStyles.captionMuted.copyWith(
            color:
                isLocked ? AppColors.textMuted : AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_HexClipper old) => false;
}
