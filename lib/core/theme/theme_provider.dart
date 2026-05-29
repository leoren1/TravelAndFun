import 'package:explore_index/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persists theme preference in the Hive settings box.
final themeProvider =
    NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<ThemeMode> {
  static const _key = 'app_theme_mode';

  @override
  ThemeMode build() {
    final stored = ref
        .read(localStorageServiceProvider)
        .getSetting<String>(_key, 'dark');
    return stored == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> toggle() async {
    final next =
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    await ref
        .read(localStorageServiceProvider)
        .setSetting(_key, next == ThemeMode.light ? 'light' : 'dark');
  }

  bool get isLight => state == ThemeMode.light;
}
