import 'package:explore_index/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.appColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.appColors.divider),
        ),
        child: Icon(
          Icons.arrow_back_ios_new,
          size: 16,
          color: context.appColors.textPrimary,
        ),
      ),
    );
  }
}

