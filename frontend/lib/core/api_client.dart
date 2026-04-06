import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  // Ensure this IP matches your MacBook's current IP
  static const String baseUrl = "http://192.168.0.134:3000";

  // --- GET ---
  static Future<List<dynamic>> get(String endpoint) async {
    final String cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final Uri url = Uri.parse("$baseUrl$cleanEndpoint");

    try {
      print("Calling GET: $url");
      final response = await http.get(url).timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      print("General Error: $e");
      rethrow;
    }
  }

  // --- POST (Create) ---
  static Future<void> post(String endpoint, Map<String, dynamic> data) async {
    final String cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final Uri url = Uri.parse("$baseUrl$cleanEndpoint");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
      ).timeout(const Duration(seconds: 7));

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception("Failed to post data");
      }
    } catch (e) {
      rethrow;
    }
  }

  // --- PUT (Update) ---
  static Future<void> put(String endpoint, Map<String, dynamic> data) async {
    final String cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final Uri url = Uri.parse("$baseUrl$cleanEndpoint");

    try {
      print("Calling PUT: $url");
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
      ).timeout(const Duration(seconds: 7));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception("Failed to update data: ${response.statusCode}");
      }
    } catch (e) {
      print("Put Error: $e");
      rethrow;
    }
  }

  // --- DELETE (Remove) ---
  static Future<void> delete(String endpoint) async {
    final String cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final Uri url = Uri.parse("$baseUrl$cleanEndpoint");

    try {
      print("Calling DELETE: $url");
      final response = await http.delete(url).timeout(const Duration(seconds: 7));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception("Failed to delete data: ${response.statusCode}");
      }
    } catch (e) {
      print("Delete Error: $e");
      rethrow;
    }
  }
}