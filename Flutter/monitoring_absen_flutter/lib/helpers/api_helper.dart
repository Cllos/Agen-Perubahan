// Helper untuk base domain/IP API
class ApiHelper {
  static const String _defaultBaseUrl = "http://192.168.12.63:5000";
  static const Duration requestTimeout = Duration(seconds: 15);
  static Map<String, dynamic>? currentUser;

  static String get baseUrl =>
      const String.fromEnvironment('API_BASE_URL', defaultValue: _defaultBaseUrl);

  static String getUrl(String endpoint) {
    return "$baseUrl$endpoint";
  }
}
