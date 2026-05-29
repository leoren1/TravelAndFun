// Category model for place exploration
import 'package:flutter/material.dart';

class ExploreCategory {
  final String id;
  final String label;
  final String emoji;
  final String accentHex;
  final String description;

  const ExploreCategory({
    required this.id,
    required this.label,
    required this.emoji,
    required this.accentHex,
    required this.description,
  });

  Color get accent =>
      Color(int.parse('0xFF${accentHex.replaceAll('#', '')}'));
}
