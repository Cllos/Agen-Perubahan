// Helper untuk base domain/IP API
class ApiHelper {
  static const String baseUrl = "http://192.168.1.13:5000"; // Ganti sesuai kebutuhan

  static String getUrl(String endpoint) {
    return "$baseUrl$endpoint";
  }
}
