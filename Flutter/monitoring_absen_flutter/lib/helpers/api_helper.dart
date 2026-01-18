// Helper untuk base domain/IP API
class ApiHelper {
  static const String _defaultBaseUrl = "http://localhost:5000";
  static const Duration requestTimeout = Duration(seconds: 15);

  static String get baseUrl =>
      const String.fromEnvironment('API_BASE_URL', defaultValue: _defaultBaseUrl);

  static String getUrl(String endpoint) {
    return "$baseUrl$endpoint";
  }
}
