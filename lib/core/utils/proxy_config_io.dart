// lib/core/utils/proxy_config_io.dart
// Mobile/desktop implementation: routes HTTP(S) through 10.0.2.2:8080
// so that Android emulators (which lack direct internet) can load map tiles
// via the host machine's internet connection.
import 'dart:io';

class _EmulatorProxyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    // 10.0.2.2 is the Android emulator's gateway to the host machine.
    // Falls back to DIRECT on real devices where the proxy isn't reachable.
    client.findProxy = (uri) => 'PROXY 10.0.2.2:8080; DIRECT';
    // Accept self-signed certs from the local proxy tunnel.
    client.badCertificateCallback = (cert, host, port) => true;
    return client;
  }
}

/// Call once in [main] before [runApp] to route HTTP through the host proxy
/// when running on an Android emulator. On real devices the DIRECT fallback
/// is used automatically, so this is safe to leave enabled.
void configureEmulatorProxy() {
  if (Platform.isAndroid) {
    HttpOverrides.global = _EmulatorProxyHttpOverrides();
  }
}
