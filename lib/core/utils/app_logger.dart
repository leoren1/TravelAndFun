// lib/core/utils/app_logger.dart
//
// Thin wrapper around Flutter's debugPrint.
// All output is suppressed in release builds automatically.

import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void d(String tag, String message) {
    debugPrint('[$tag] $message');
  }

  static void w(String tag, String message, [Object? error]) {
    if (error != null) {
      debugPrint('[WARN][$tag] $message — $error');
    } else {
      debugPrint('[WARN][$tag] $message');
    }
  }

  static void e(String tag, String message, [Object? error, StackTrace? stack]) {
    debugPrint('[ERROR][$tag] $message${error != null ? ' — $error' : ''}');
    if (stack != null) debugPrint(stack.toString());
  }
}
