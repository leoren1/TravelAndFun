extension NumExtensions on num {
  String toPercent({int fractionDigits = 0}) =>
      '${toStringAsFixed(fractionDigits)}%';

  String toCompactString() {
    if (this >= 1000) return '${(this / 1000).toStringAsFixed(1)}k';
    return toString();
  }
}

extension DoubleExtensions on double {
  double clampUnit() => clamp(0.0, 1.0).toDouble();
}
