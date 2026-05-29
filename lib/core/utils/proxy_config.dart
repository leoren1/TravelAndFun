// lib/core/utils/proxy_config.dart
//
// Conditional import: on mobile/desktop uses dart:io HttpOverrides,
// on web it's a no-op (dart:io is unavailable in browsers).
export 'proxy_config_stub.dart'
    if (dart.library.io) 'proxy_config_io.dart';
