import 'package:explore_index/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

extension BuildContextExtensions on BuildContext {
  ThemeData get theme       => Theme.of(this);
  TextTheme  get textTheme  => Theme.of(this).textTheme;
  ColorScheme get colors    => Theme.of(this).colorScheme;
  Size       get screenSize => MediaQuery.sizeOf(this);
  double     get screenWidth  => MediaQuery.sizeOf(this).width;
  double     get screenHeight => MediaQuery.sizeOf(this).height;
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : Theme.of(this).colorScheme.secondary,
      ),
    );
  }
}
