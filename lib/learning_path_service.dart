import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class LearningPathService {
  // 🌐 Deployed cloud backend — works from anywhere, any network.
  // This is the Render.com deployment URL for the Hoot Path server.
  static const String _baseUrl = 'https://hoot-path-server.onrender.com/api';

  String get baseUrl => _baseUrl;

  Map<String, dynamic> _handleResponse(http.Response response) {
    final Map<String, dynamic> decoded;
    try {
      decoded = json.decode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Invalid response from server (not JSON). Body: ${response.body}');
    }
    if (response.statusCode >= 400) {
      throw Exception('Server error ${response.statusCode}: ${decoded['error'] ?? response.body}');
    }
    return decoded;
  }

  /// Quick ping to check if server is reachable.
  Future<bool> isServerReachable() async {
    try {
      final response = await http
          .get(Uri.parse(_baseUrl.replaceAll('/api', '/')))
          .timeout(const Duration(seconds: 8));
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> checkExistingPath(String userId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/get-learning-path'),
            headers: {"Content-Type": "application/json"},
            body: json.encode({"user_id": userId}),
          )
          .timeout(const Duration(seconds: 20));
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Cannot reach server. Check your internet connection.');
    }
  }

  Future<Map<String, dynamic>> generatePath(
    String userId,
    Map<String, dynamic> accuracyData,
  ) async {
    try {
      // Gemini generation + MongoDB save can take 30-60s
      final response = await http
          .post(
            Uri.parse('$baseUrl/generate-learning-path'),
            headers: {"Content-Type": "application/json"},
            body: json.encode({"user_id": userId, "accuracy": accuracyData}),
          )
          .timeout(const Duration(seconds: 120));
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Path generation timed out. The AI is taking too long — please try again.');
    }
  }

  Future<Map<String, dynamic>> completeDay(String userId, int day) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/complete-day'),
            headers: {"Content-Type": "application/json"},
            body: json.encode({"user_id": userId, "day": day}),
          )
          .timeout(const Duration(seconds: 20));
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Request timed out. Check your internet connection.');
    }
  }
}
