/// Build-time configuration.
///
/// The API base URL is provided at build/run time with:
///
/// ```sh
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
/// ```
///
/// Defaults:
///   - `http://10.0.2.2:8080` — Android emulator (maps to host loopback)
///   - `http://localhost:8080` — iOS simulator / Chrome
///   - machine LAN IP for a physical device (e.g. `http://192.168.1.20:8080`)
class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );
}