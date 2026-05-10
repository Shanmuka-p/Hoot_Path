import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class LearningPathService {
  // 🌐 Deployed on Render — works from anywhere, any network.
  static const String _baseUrl = 'https://hoot-path.onrender.com/api';

  String get baseUrl => _baseUrl;

  Map<String, dynamic> _handleResponse(http.Response response) {
    final Map<String, dynamic> decoded;
    try {
      decoded = json.decode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
          'Invalid response from server. Body: ${response.body}');
    }
    if (response.statusCode >= 400) {
      throw Exception(
          'Server error ${response.statusCode}: ${decoded['error'] ?? response.body}');
    }
    return decoded;
  }

  /// Quick ping to check if server is reachable.
  Future<bool> isServerReachable() async {
    try {
      final response = await http
          .get(Uri.parse('https://hoot-path.onrender.com/'))
          .timeout(const Duration(seconds: 10));
      // "Cannot GET /" with 404 means server IS running
      return true;
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
          .timeout(const Duration(seconds: 30));
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
      // AI generation can take a long time if running locally on CPU
      final response = await http
          .post(
            Uri.parse('$baseUrl/generate-learning-path'),
            headers: {"Content-Type": "application/json"},
            body: json.encode({"user_id": userId, "accuracy": accuracyData}),
          )
          .timeout(const Duration(seconds: 300));
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception(
          'Path generation timed out. Please try again.');
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
