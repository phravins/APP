enum AppEnvironment { demo, development, production }

abstract final class AppConfig {
  static const environmentName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'demo',
  );
  static AppEnvironment get environment =>
      AppEnvironment.values.byName(environmentName);
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static bool get isDemo => environment == AppEnvironment.demo;
  static void validate() {
    if (!isDemo) {
      final uri = Uri.tryParse(apiBaseUrl);
      if (uri == null ||
          !uri.hasAuthority ||
          !['https', 'http'].contains(uri.scheme)) {
        throw StateError('Set a valid API_BASE_URL with --dart-define.');
      }
      if (environment == AppEnvironment.production && uri.scheme != 'https') {
        throw StateError('Production requires HTTPS.');
      }
    }
  }
}
